import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'health_sync_service.dart';

/// Thin seam over the `health` plugin so mapping and error handling can be
/// unit-tested without the platform channel.
abstract class HealthPluginGateway {
  /// Requests read access to workouts. Returns `false` when denied.
  Future<bool> requestAuthorization();

  /// Returns workout data points between [start] and [end].
  Future<List<HealthDataPoint>> fetchWorkouts({
    required DateTime start,
    required DateTime end,
  });
}

/// [HealthPluginGateway] backed by the real `health` plugin.
class PluginHealthGateway implements HealthPluginGateway {
  final Health _health;
  final TargetPlatform _platform;
  bool _configured = false;

  /// [platform] defaults to [defaultTargetPlatform] (web-safe, no `dart:io`).
  PluginHealthGateway({Health? health, TargetPlatform? platform})
    : _health = health ?? Health(),
      _platform = platform ?? defaultTargetPlatform;

  /// Only workouts are ever queried.
  static const _fetchTypes = [HealthDataType.WORKOUT];

  /// Read access requested on [platform].
  ///
  /// On Android the plugin reads distance, calories and steps records for
  /// every exercise session and silently returns no workouts without those
  /// permissions. Their values are discarded on-device: only the
  /// [DetectedWorkout] fields are kept.
  static List<HealthDataType> authorizationTypesFor(TargetPlatform platform) =>
      platform == TargetPlatform.android
      ? const [
          HealthDataType.WORKOUT,
          HealthDataType.DISTANCE_DELTA,
          HealthDataType.TOTAL_CALORIES_BURNED,
          HealthDataType.STEPS,
        ]
      : _fetchTypes;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<bool> requestAuthorization() async {
    await _ensureConfigured();
    final types = authorizationTypesFor(_platform);
    return _health.requestAuthorization(
      types,
      permissions: List.filled(types.length, HealthDataAccess.READ),
    );
  }

  @override
  Future<List<HealthDataPoint>> fetchWorkouts({
    required DateTime start,
    required DateTime end,
  }) async {
    await _ensureConfigured();
    return _health.getHealthDataFromTypes(
      types: _fetchTypes,
      startTime: start,
      endTime: end,
    );
  }
}

/// [HealthSyncService] reading tennis workouts from Apple Health (iOS) or
/// Health Connect (Android). Parsing happens on-device; only the minimal
/// [DetectedWorkout] leaves this class.
class NativeHealthSyncService implements HealthSyncService {
  /// How far back the first sync of a launch looks.
  static const defaultInitialLookback = Duration(days: 7);

  /// Longest workout emitted, matching the server's `logSession` limit.
  static const maxWorkoutMinutes = 360;

  /// Later syncs start this long before the previous sync, so matches still
  /// in progress during a sync, or saved late by a watch, are not lost.
  /// Already seen workouts are skipped by id.
  static const syncOverlap = Duration(hours: 24);

  /// Key under which handled and dismissed workout IDs are persisted.
  static const _storageKey = 'handled_workout_ids_v1';

  /// Maximum duration allowed for a sync query before timing out safely.
  static const syncTimeout = Duration(seconds: 5);

  final DateTime Function() _now;
  HealthPluginGateway? _gateway;
  final SharedPreferences? _prefs;
  final _controller = StreamController<DetectedWorkout>.broadcast();
  final _pending = <DetectedWorkout>[];
  final _seenIds = <String>{};
  DateTime? _lastSync;
  final Duration _initialLookback;
  bool _isSyncing = false;
  bool _hasPermission = true;
  bool _storageLoaded = false;

  /// The plugin gateway is created lazily on the first sync, so constructing
  /// this service never touches the platform channel.
  NativeHealthSyncService({
    this._gateway,
    DateTime Function()? now,
    this._initialLookback = defaultInitialLookback,
    this._prefs,
  }) : _now = now ?? DateTime.now;

  HealthPluginGateway get _resolvedGateway =>
      _gateway ??= PluginHealthGateway();

  @override
  Stream<DetectedWorkout> get workouts => _controller.stream;

  @override
  bool get supportsSimulation => false;

  @override
  bool get hasPermission => _hasPermission;

  @override
  List<DetectedWorkout> get pendingWorkouts => List.unmodifiable(_pending);

  Future<SharedPreferences?> _resolvePrefs() async {
    if (_prefs != null) return _prefs;
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('HealthSync: SharedPreferences unavailable: $e');
      return null;
    }
  }

  Future<void> _ensureStorageLoaded() async {
    if (_storageLoaded) return;
    try {
      final prefs = await _resolvePrefs();
      final stored = prefs?.getStringList(_storageKey);
      if (stored != null) {
        _seenIds.addAll(stored);
      }
    } catch (e) {
      debugPrint('HealthSync: failed to load persisted workout IDs: $e');
    }
    _storageLoaded = true;
  }

  Future<void> _persistHandledId(String id) async {
    try {
      final prefs = await _resolvePrefs();
      if (prefs == null) return;
      final currentList = prefs.getStringList(_storageKey) ?? <String>[];
      if (!currentList.contains(id)) {
        currentList.add(id);
        await prefs.setStringList(_storageKey, currentList);
      }
    } catch (e) {
      debugPrint('HealthSync: failed to persist handled workout ID: $e');
    }
  }

  @override
  Future<List<DetectedWorkout>> syncWorkouts() async {
    if (_isSyncing) return const [];
    _isSyncing = true;

    try {
      await _ensureStorageLoaded();
      final end = _now().toUtc();
      final lastSync = _lastSync;
      final start = lastSync == null
          ? end.subtract(_initialLookback)
          : lastSync.subtract(syncOverlap);

      final gateway = _resolvedGateway;
      final authorized = await gateway.requestAuthorization().timeout(
        syncTimeout,
      );
      if (!authorized) {
        _hasPermission = false;
        debugPrint('HealthSync: workout read permission denied');
        return const [];
      }
      _hasPermission = true;

      final points = await gateway
          .fetchWorkouts(start: start, end: end)
          .timeout(syncTimeout);
      final detected = <DetectedWorkout>[];
      for (final point in points) {
        final workout = _mapTennisWorkout(point, end);
        if (workout == null || !_seenIds.add(workout.externalWorkoutId)) {
          continue;
        }
        detected.add(workout);
      }

      _lastSync = end;
      _pending.addAll(detected);
      if (!_controller.isClosed) detected.forEach(_controller.add);
      return detected;
    } catch (error) {
      debugPrint('HealthSync: workout sync failed: $error');
      return const [];
    } finally {
      _isSyncing = false;
    }
  }

  DetectedWorkout? _mapTennisWorkout(HealthDataPoint point, DateTime now) {
    final value = point.value;
    if (point.type != HealthDataType.WORKOUT ||
        value is! WorkoutHealthValue ||
        value.workoutActivityType != HealthWorkoutActivityType.TENNIS) {
      return null;
    }
    // Only completed workouts.
    if (point.dateTo.isAfter(now)) return null;

    final minutes = point.dateTo.difference(point.dateFrom).inMinutes;
    if (minutes <= 0 || minutes > maxWorkoutMinutes) return null;

    return DetectedWorkout(
      externalWorkoutId: point.uuid,
      startTime: point.dateFrom.toUtc(),
      durationMinutes: minutes,
      source: switch (point.sourcePlatform) {
        HealthPlatformType.appleHealth => DetectedWorkout.sourceHealthKit,
        HealthPlatformType.googleHealthConnect =>
          DetectedWorkout.sourceHealthConnect,
      },
    );
  }

  @override
  Future<void> simulateWorkout() => Future.error(
    UnsupportedError('Simulation is only available on web/desktop'),
  );

  @override
  void dismissPendingWorkout(String externalWorkoutId) {
    _pending.removeWhere((w) => w.externalWorkoutId == externalWorkoutId);
    _seenIds.add(externalWorkoutId);
    unawaited(_persistHandledId(externalWorkoutId));
  }

  @override
  void dispose() {
    _controller.close();
  }
}
