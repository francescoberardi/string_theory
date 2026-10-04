import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_flutter/services/health/health_sync_service.dart';
import 'package:string_theory_flutter/services/health/native_health_sync_service.dart';

/// Gateway fake that honours the query window like the real plugin does:
/// iOS queries with `.strictStartDate`, so only workouts whose start lies in
/// `[start, end)` come back. A window bug is therefore visible in tests.
class FakeHealthGateway implements HealthPluginGateway {
  bool authorized = true;
  Object? authorizationError;
  Object? fetchError;
  List<HealthDataPoint> points = [];
  final List<(DateTime, DateTime)> fetchCalls = [];
  int authorizationCalls = 0;

  @override
  Future<bool> requestAuthorization() async {
    authorizationCalls++;
    if (authorizationError != null) throw authorizationError!;
    return authorized;
  }

  @override
  Future<List<HealthDataPoint>> fetchWorkouts({
    required DateTime start,
    required DateTime end,
  }) async {
    fetchCalls.add((start, end));
    if (fetchError != null) throw fetchError!;
    return points
        .where((p) => !p.dateFrom.isBefore(start) && p.dateFrom.isBefore(end))
        .toList();
  }
}

class MockHealth extends Mock implements Health {}

HealthDataPoint workoutPoint({
  required String uuid,
  required HealthWorkoutActivityType activity,
  required DateTime from,
  required DateTime to,
  HealthPlatformType platform = HealthPlatformType.appleHealth,
}) {
  return HealthDataPoint(
    uuid: uuid,
    value: WorkoutHealthValue(workoutActivityType: activity),
    type: HealthDataType.WORKOUT,
    unit: HealthDataUnit.NO_UNIT,
    dateFrom: from,
    dateTo: to,
    sourcePlatform: platform,
    sourceDeviceId: 'device',
    sourceId: 'com.apple.health',
    sourceName: 'Health',
  );
}

HealthDataPoint tennis(String uuid, DateTime from, Duration length) =>
    workoutPoint(
      uuid: uuid,
      activity: HealthWorkoutActivityType.TENNIS,
      from: from,
      to: from.add(length),
    );

void main() {
  group('NativeHealthSyncService', () {
    late DateTime now;
    late FakeHealthGateway gateway;
    late NativeHealthSyncService service;

    setUp(() {
      now = DateTime.utc(2026, 10, 4, 20, 0);
      gateway = FakeHealthGateway();
      service = NativeHealthSyncService(gateway: gateway, now: () => now);
    });

    tearDown(() => service.dispose());

    test('does not support simulation', () {
      expect(service.supportsSimulation, isFalse);
    });

    test(
      'maps only tennis workouts with HealthKit source and plugin uuid',
      () async {
        final tennisStart = DateTime.utc(2026, 10, 4, 17, 0);
        gateway.points = [
          tennis('TENNIS-UUID-1', tennisStart, const Duration(minutes: 75)),
          workoutPoint(
            uuid: 'RUN-UUID-1',
            activity: HealthWorkoutActivityType.RUNNING,
            from: DateTime.utc(2026, 10, 4, 8, 0),
            to: DateTime.utc(2026, 10, 4, 8, 40),
          ),
        ];

        final emitted = service.workouts.first;
        final result = await service.syncWorkouts();

        final expected = DetectedWorkout(
          externalWorkoutId: 'TENNIS-UUID-1',
          startTime: tennisStart,
          durationMinutes: 75,
          source: 'healthkit',
        );
        expect(result, [expected]);
        expect(await emitted, expected);
        expect(service.pendingWorkouts, [expected]);
      },
    );

    test('maps Health Connect workouts to health_connect source', () async {
      final start = DateTime.utc(2026, 10, 4, 10, 0);
      gateway.points = [
        workoutPoint(
          uuid: 'hc-1',
          activity: HealthWorkoutActivityType.TENNIS,
          from: start,
          to: start.add(const Duration(minutes: 60)),
          platform: HealthPlatformType.googleHealthConnect,
        ),
      ];

      final result = await service.syncWorkouts();

      expect(result.single.source, 'health_connect');
      expect(result.single.startTime.isUtc, isTrue);
    });

    test('maps a local-time plugin point to a UTC startTime', () async {
      // The real plugin builds local DateTimes.
      // A day before `now`, so it stays in the window in any time zone.
      final localStart = DateTime(2026, 10, 3, 17);
      gateway.points = [
        tennis('LOCAL-1', localStart, const Duration(minutes: 60)),
      ];

      final result = await service.syncWorkouts();

      expect(result.single.startTime.isUtc, isTrue);
      expect(result.single.startTime, localStart.toUtc());
    });

    test('skips workouts that have not completed yet', () async {
      gateway.points = [
        tennis(
          'in-progress',
          now.subtract(const Duration(minutes: 30)),
          const Duration(minutes: 60),
        ),
      ];

      expect(await service.syncWorkouts(), isEmpty);
    });

    test('first sync of a launch looks back 7 days', () async {
      await service.syncWorkouts();

      expect(gateway.fetchCalls.single, (
        now.subtract(const Duration(days: 7)),
        now,
      ));
    });

    test('later syncs start 24h before the previous sync', () async {
      final firstSync = now;
      await service.syncWorkouts();
      now = now.add(const Duration(hours: 2));
      await service.syncWorkouts();

      expect(gateway.fetchCalls[1], (
        firstSync.subtract(const Duration(hours: 24)),
        now,
      ));
    });

    test('detects a match that straddles a sync exactly once', () async {
      // 17:00-18:30 match; first sync happens mid-match at 17:30.
      gateway.points = [
        tennis(
          'STRADDLE-1',
          DateTime.utc(2026, 10, 4, 17, 0),
          const Duration(minutes: 90),
        ),
      ];
      final emitted = <DetectedWorkout>[];
      final sub = service.workouts.listen(emitted.add);
      addTearDown(sub.cancel);

      now = DateTime.utc(2026, 10, 4, 17, 30);
      expect(await service.syncWorkouts(), isEmpty);

      now = DateTime.utc(2026, 10, 4, 19, 0);
      final second = await service.syncWorkouts();

      now = DateTime.utc(2026, 10, 4, 20, 0);
      final third = await service.syncWorkouts();
      await pumpEventQueue();

      expect(second.map((w) => w.externalWorkoutId), ['STRADDLE-1']);
      expect(second.single.durationMinutes, 90);
      expect(third, isEmpty);
      expect(emitted, hasLength(1));
    });

    test('detects a workout saved after the sync that covered it', () async {
      // Watch saves the 10:00-11:00 workout late, after the 11:30 sync.
      now = DateTime.utc(2026, 10, 4, 11, 30);
      expect(await service.syncWorkouts(), isEmpty);

      gateway.points = [
        tennis(
          'LATE-1',
          DateTime.utc(2026, 10, 4, 10, 0),
          const Duration(hours: 1),
        ),
      ];
      now = DateTime.utc(2026, 10, 4, 12, 0);
      final second = await service.syncWorkouts();

      expect(second.map((w) => w.externalWorkoutId), ['LATE-1']);
    });

    test('emits a workout returned by overlapping syncs only once', () async {
      gateway.points = [
        tennis(
          'TENNIS-UUID-1',
          DateTime.utc(2026, 10, 4, 17, 0),
          const Duration(minutes: 60),
        ),
      ];
      final emitted = <DetectedWorkout>[];
      final sub = service.workouts.listen(emitted.add);
      addTearDown(sub.cancel);

      final first = await service.syncWorkouts();
      now = now.add(const Duration(hours: 1));
      final second = await service.syncWorkouts();
      await pumpEventQueue();

      expect(first, hasLength(1));
      expect(second, isEmpty);
      expect(emitted, hasLength(1));
      expect(service.pendingWorkouts, hasLength(1));
      // The overlap window really did return the workout a second time.
      expect(gateway.fetchCalls, hasLength(2));
      expect(
        gateway.fetchCalls[1].$1.isBefore(DateTime.utc(2026, 10, 4, 17, 0)),
        isTrue,
      );
    });

    test(
      'dismissPendingWorkout removes matching workout from pendingWorkouts',
      () async {
        gateway.points = [
          tennis(
            'TO-DISMISS-1',
            DateTime.utc(2026, 10, 4, 17, 0),
            const Duration(minutes: 60),
          ),
        ];
        await service.syncWorkouts();
        expect(service.pendingWorkouts, hasLength(1));

        service.dismissPendingWorkout('TO-DISMISS-1');
        expect(service.pendingWorkouts, isEmpty);
      },
    );

    test('a failed sync does not advance the sync window', () async {
      gateway.fetchError = Exception('platform channel failure');
      await service.syncWorkouts();

      gateway.fetchError = null;
      now = now.add(const Duration(hours: 1));
      await service.syncWorkouts();

      expect(gateway.fetchCalls[1].$1, now.subtract(const Duration(days: 7)));
    });

    test('returns empty list when permission is denied', () async {
      gateway.authorized = false;

      expect(await service.syncWorkouts(), isEmpty);
      expect(gateway.fetchCalls, isEmpty);
    });

    test('returns empty list when authorization throws', () async {
      gateway.authorizationError = Exception('Health Connect unavailable');

      expect(await service.syncWorkouts(), isEmpty);
    });

    test('returns empty list when the plugin query throws', () async {
      gateway.fetchError = Exception('platform channel failure');

      expect(await service.syncWorkouts(), isEmpty);
      expect(service.pendingWorkouts, isEmpty);
    });

    test('simulateWorkout is unsupported on native', () {
      expect(service.simulateWorkout, throwsUnsupportedError);
    });
  });

  group('PluginHealthGateway', () {
    late MockHealth health;

    setUpAll(() {
      registerFallbackValue(<HealthDataType>[]);
      registerFallbackValue(<HealthDataAccess>[]);
      registerFallbackValue(DateTime.utc(2026));
    });

    setUp(() {
      health = MockHealth();
      when(() => health.configure()).thenAnswer((_) async {});
      when(
        () => health.requestAuthorization(
          any(),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => true);
      when(
        () => health.getHealthDataFromTypes(
          types: any(named: 'types'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
        ),
      ).thenAnswer((_) async => []);
    });

    (List<dynamic>, List<dynamic>) capturedAuthorization() {
      final captured = verify(
        () => health.requestAuthorization(
          captureAny(),
          permissions: captureAny(named: 'permissions'),
        ),
      ).captured;
      return (captured[0] as List<dynamic>, captured[1] as List<dynamic>);
    }

    test(
      'requests workout plus distance, calories and steps reads on Android',
      () async {
        final gateway = PluginHealthGateway(
          health: health,
          platform: TargetPlatform.android,
        );

        expect(await gateway.requestAuthorization(), isTrue);

        final (types, permissions) = capturedAuthorization();
        expect(types, [
          HealthDataType.WORKOUT,
          HealthDataType.DISTANCE_DELTA,
          HealthDataType.TOTAL_CALORIES_BURNED,
          HealthDataType.STEPS,
        ]);
        expect(permissions, List.filled(4, HealthDataAccess.READ));
      },
    );

    test('requests workout reads only on iOS', () async {
      final gateway = PluginHealthGateway(
        health: health,
        platform: TargetPlatform.iOS,
      );

      await gateway.requestAuthorization();

      final (types, permissions) = capturedAuthorization();
      expect(types, [HealthDataType.WORKOUT]);
      expect(permissions, [HealthDataAccess.READ]);
    });

    test('fetches only WORKOUT records, even on Android', () async {
      final gateway = PluginHealthGateway(
        health: health,
        platform: TargetPlatform.android,
      );
      final start = DateTime.utc(2026, 10, 3);
      final end = DateTime.utc(2026, 10, 4);

      await gateway.fetchWorkouts(start: start, end: end);

      final captured = verify(
        () => health.getHealthDataFromTypes(
          types: captureAny(named: 'types'),
          startTime: captureAny(named: 'startTime'),
          endTime: captureAny(named: 'endTime'),
        ),
      ).captured;
      expect(captured, [
        [HealthDataType.WORKOUT],
        start,
        end,
      ]);
    });
  });
}
