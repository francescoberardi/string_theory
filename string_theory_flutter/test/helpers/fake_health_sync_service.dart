import 'dart:async';

import 'package:string_theory_flutter/services/health/health_sync_service.dart';

/// In-memory [HealthSyncService] for widget tests.
class FakeHealthSyncService implements HealthSyncService {
  @override
  final bool supportsSimulation;

  final _controller = StreamController<DetectedWorkout>.broadcast();
  final _pending = <DetectedWorkout>[];
  int simulateCalls = 0;
  int syncCalls = 0;

  /// Workouts the next [syncWorkouts] call detects and emits as one batch.
  List<DetectedWorkout> nextSyncBatch = [];

  FakeHealthSyncService({this.supportsSimulation = false});

  void emit(DetectedWorkout workout) {
    _pending.add(workout);
    _controller.add(workout);
  }

  @override
  Stream<DetectedWorkout> get workouts => _controller.stream;

  @override
  List<DetectedWorkout> get pendingWorkouts => List.unmodifiable(_pending);

  @override
  Future<List<DetectedWorkout>> syncWorkouts() async {
    syncCalls++;
    final batch = nextSyncBatch;
    nextSyncBatch = [];
    batch.forEach(emit);
    return batch;
  }

  @override
  Future<void> simulateWorkout() async {
    simulateCalls++;
    emit(
      DetectedWorkout(
        externalWorkoutId: 'sim-fake-$simulateCalls',
        startTime: DateTime.utc(2026, 10, 4, 16, 30),
        durationMinutes: 90,
        source: DetectedWorkout.sourceSimulated,
      ),
    );
  }

  @override
  void dismissPendingWorkout(String externalWorkoutId) {
    _pending.removeWhere((w) => w.externalWorkoutId == externalWorkoutId);
  }

  @override
  void dispose() => _controller.close();
}
