import 'package:equatable/equatable.dart';

/// A tennis workout detected by a [HealthSyncService].
///
/// Carries only the fields a `SessionLog` needs, so raw health records never
/// leave the device (NFR-7).
class DetectedWorkout extends Equatable {
  /// Unique per workout. Simulated workouts are prefixed with `sim-`.
  final String externalWorkoutId;

  /// Workout start, in UTC.
  final DateTime startTime;

  final int durationMinutes;

  /// One of [sourceHealthKit], [sourceHealthConnect] or [sourceSimulated].
  final String source;

  static const sourceHealthKit = 'healthkit';
  static const sourceHealthConnect = 'health_connect';
  static const sourceSimulated = 'simulated';

  const DetectedWorkout({
    required this.externalWorkoutId,
    required this.startTime,
    required this.durationMinutes,
    required this.source,
  });

  @override
  List<Object?> get props => [
    externalWorkoutId,
    startTime,
    durationMinutes,
    source,
  ];
}

/// Strategy interface for ingesting tennis workouts (FR-11, ARCH-5).
///
/// UI and blocs depend only on this type, never on a health plugin.
abstract class HealthSyncService {
  /// Every newly detected workout, as it is detected.
  Stream<DetectedWorkout> get workouts;

  /// Pulls recently completed workouts and returns the ones not seen before.
  ///
  /// All workouts detected by one call are emitted on [workouts] together, so
  /// listeners can surface them as a single batch. Never throws: platform
  /// failures yield an empty list.
  Future<List<DetectedWorkout>> syncWorkouts();

  /// Whether [simulateWorkout] is available (web / desktop only).
  bool get supportsSimulation;

  /// Workouts detected so far that have not been assigned yet.
  List<DetectedWorkout> get pendingWorkouts;

  /// Emits a simulated workout immediately.
  Future<void> simulateWorkout();

  /// Removes the workout matching [externalWorkoutId] from [pendingWorkouts].
  void dismissPendingWorkout(String externalWorkoutId);

  void dispose();
}
