import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:string_theory_flutter/services/health/native_health_sync_service.dart';

import '../../helpers/tdd_red_phase.dart';
import 'native_health_sync_service_test.dart';

/// Test gateway that allows controlling completion timing and errors.
class ControllableHealthGateway implements HealthPluginGateway {
  bool authorized = true;
  Completer<List<HealthDataPoint>>? fetchCompleter;
  int fetchCalls = 0;
  List<HealthDataPoint> pointsToReturn = [];

  @override
  Future<bool> requestAuthorization() async => authorized;

  @override
  Future<List<HealthDataPoint>> fetchWorkouts({
    required DateTime start,
    required DateTime end,
  }) async {
    fetchCalls++;
    if (fetchCompleter != null) {
      return fetchCompleter!.future;
    }
    return pointsToReturn;
  }
}

void main() {
  group('Story 6.2: NativeHealthSyncService Hardening (AC-2 & AC-5)', () {
    late ControllableHealthGateway gateway;
    late DateTime now;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      gateway = ControllableHealthGateway();
      now = DateTime.utc(2026, 10, 12, 18, 0);
    });

    testWidgets(
      '[P1] [AC-2] syncWorkouts enforces a 5-second timeout and guarantees _isSyncing = false in a finally block',
      skip: tddRedPhase,
      (tester) async {
        // A gateway that hangs indefinitely.
        gateway.fetchCompleter = Completer<List<HealthDataPoint>>();

        final service = NativeHealthSyncService(
          gateway: gateway,
          now: () => now,
        );

        var syncCompleted = false;
        List<dynamic>? syncResult;

        service.syncWorkouts().then((result) {
          syncCompleted = true;
          syncResult = result;
        });

        // Concurrently call syncWorkouts while first sync is in flight.
        // Concurrency guard should prevent duplicate gateway fetch.
        service.syncWorkouts();
        expect(
          gateway.fetchCalls,
          equals(1),
          reason:
              'Concurrent syncWorkouts call must not start duplicate fetch while sync is active',
        );

        // Fast-forward past the 5-second timeout.
        await tester.pump(const Duration(seconds: 5));

        expect(
          syncCompleted,
          isTrue,
          reason: 'syncWorkouts must timeout and complete after 5 seconds',
        );
        expect(
          syncResult,
          isEmpty,
          reason: 'Timed-out syncWorkouts must safely return empty list',
        );

        // Now verify _isSyncing was reset in finally: a new syncWorkouts call can execute.
        gateway.fetchCompleter = null;
        gateway.pointsToReturn = [];
        service.syncWorkouts();
        expect(
          gateway.fetchCalls,
          equals(2),
          reason:
              'Subsequent syncWorkouts call must be allowed after prior sync timed out',
        );

        service.dispose();
      },
    );

    test(
      '[P1] [AC-5] processed or dismissed workout IDs are stored in persistent storage across restarts',
      skip: tddRedPhaseReason,
      () async {
        const workoutId = 'TENNIS-PERSIST-1';
        final tennisStart = now.subtract(const Duration(hours: 2));
        gateway.pointsToReturn = [
          tennis(workoutId, tennisStart, const Duration(minutes: 60)),
        ];

        final service1 = NativeHealthSyncService(
          gateway: gateway,
          now: () => now,
        );

        final detected = await service1.syncWorkouts();
        expect(detected.length, equals(1));
        expect(detected.first.externalWorkoutId, equals(workoutId));

        // Player dismisses or handles the workout
        service1.dismissPendingWorkout(workoutId);
        service1.dispose();

        // Simulate app restart by creating a new service instance with same persistent storage.
        final service2 = NativeHealthSyncService(
          gateway: gateway,
          now: () => now,
        );

        final detectedAfterRestart = await service2.syncWorkouts();
        expect(
          detectedAfterRestart,
          isEmpty,
          reason:
              'Handled/dismissed workout IDs must persist across service restarts so users are not re-alerted',
        );

        service2.dispose();
      },
    );
  });
}
