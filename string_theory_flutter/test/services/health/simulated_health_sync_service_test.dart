import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_flutter/services/health/health_sync_service.dart';
import 'package:string_theory_flutter/services/health/simulated_health_sync_service.dart';

void main() {
  final fixedNow = DateTime.utc(2026, 10, 4, 18, 0);

  group('SimulatedHealthSyncService', () {
    test('emits one 90-minute simulated tennis workout on simulate', () async {
      final service = SimulatedHealthSyncService(
        now: () => fixedNow,
        idGenerator: () => 'sim-abc',
      );
      addTearDown(service.dispose);

      final emitted = service.workouts.first;
      await service.simulateWorkout();

      expect(
        await emitted,
        DetectedWorkout(
          externalWorkoutId: 'sim-abc',
          startTime: fixedNow.subtract(const Duration(minutes: 90)),
          durationMinutes: 90,
          source: 'simulated',
        ),
      );
      expect(service.pendingWorkouts, hasLength(1));
    });

    test('generates distinct sim- prefixed ids on repeated taps', () async {
      final service = SimulatedHealthSyncService(now: () => fixedNow);
      addTearDown(service.dispose);

      final emitted = service.workouts.take(2).toList();
      await service.simulateWorkout();
      await service.simulateWorkout();

      final workouts = await emitted;
      expect(workouts, hasLength(2));
      expect(
        workouts[0].externalWorkoutId,
        isNot(workouts[1].externalWorkoutId),
      );
      for (final workout in workouts) {
        expect(workout.externalWorkoutId, startsWith('sim-'));
        expect(workout.startTime.isUtc, isTrue);
      }
      expect(service.pendingWorkouts, workouts);
    });

    test('default id generator yields many unique sim- ids', () async {
      // Also run under `flutter test --platform chrome`: the default
      // generator must stay within dart2js integer semantics.
      final service = SimulatedHealthSyncService(now: () => fixedNow);
      addTearDown(service.dispose);

      for (var i = 0; i < 200; i++) {
        await service.simulateWorkout();
      }

      final ids = service.pendingWorkouts.map((w) => w.externalWorkoutId);
      expect(ids.toSet(), hasLength(200));
      expect(ids, everyElement(matches(RegExp(r'^sim-[0-9a-z-]+$'))));
    });

    test('startTime is UTC even when the clock returns local time', () async {
      final service = SimulatedHealthSyncService(
        now: () => DateTime(2026, 10, 4, 18, 0),
      );
      addTearDown(service.dispose);

      await service.simulateWorkout();

      expect(service.pendingWorkouts.single.startTime.isUtc, isTrue);
    });

    test('supports simulation and syncWorkouts returns nothing', () async {
      final service = SimulatedHealthSyncService();
      addTearDown(service.dispose);

      expect(service.supportsSimulation, isTrue);
      expect(await service.syncWorkouts(), isEmpty);
    });
  });

  group('DetectedWorkout', () {
    test('carries exactly the SessionLog health fields', () {
      final start = DateTime.utc(2026, 10, 4, 16, 30);
      final workout = DetectedWorkout(
        externalWorkoutId: 'sim-1',
        startTime: start,
        durationMinutes: 90,
        source: 'simulated',
      );

      expect(workout.props, ['sim-1', start, 90, 'simulated']);
    });
  });
}
