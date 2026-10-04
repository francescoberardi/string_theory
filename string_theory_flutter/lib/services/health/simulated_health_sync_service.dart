import 'dart:async';
import 'dart:math';

import 'health_sync_service.dart';

/// Hardware-free [HealthSyncService] for web and desktop, letting judges
/// generate a 90-minute tennis workout on demand.
class SimulatedHealthSyncService implements HealthSyncService {
  static const simulatedDurationMinutes = 90;

  final DateTime Function() _now;
  final String Function() _idGenerator;
  final _controller = StreamController<DetectedWorkout>.broadcast();
  final _pending = <DetectedWorkout>[];

  SimulatedHealthSyncService({
    DateTime Function()? now,
    String Function()? idGenerator,
  }) : _now = now ?? DateTime.now,
       _idGenerator = idGenerator ?? _defaultId;

  static final _random = Random();
  static int _counter = 0;

  /// Largest `Random.nextInt` bound that is safe on every platform: dart2js
  /// folds `1 << 32` to `0`, so 32-bit shifts must never be used here.
  static const _maxSalt = 0x7fffffff;

  static String _defaultId() {
    _counter++;
    final micros = DateTime.now().microsecondsSinceEpoch;
    final salt = _random.nextInt(_maxSalt).toRadixString(36);
    return 'sim-$micros-$_counter-$salt';
  }

  @override
  Stream<DetectedWorkout> get workouts => _controller.stream;

  @override
  bool get supportsSimulation => true;

  @override
  List<DetectedWorkout> get pendingWorkouts => List.unmodifiable(_pending);

  @override
  Future<List<DetectedWorkout>> syncWorkouts() async => const [];

  @override
  Future<void> simulateWorkout() async {
    final end = _now().toUtc();
    final workout = DetectedWorkout(
      externalWorkoutId: _idGenerator(),
      startTime: end.subtract(
        const Duration(minutes: simulatedDurationMinutes),
      ),
      durationMinutes: simulatedDurationMinutes,
      source: DetectedWorkout.sourceSimulated,
    );
    _pending.add(workout);
    if (!_controller.isClosed) _controller.add(workout);
  }

  @override
  void dismissPendingWorkout(String externalWorkoutId) {
    _pending.removeWhere((w) => w.externalWorkoutId == externalWorkoutId);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
