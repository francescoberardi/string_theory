import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../domain/decay_engine.dart';
import '../services/offline_session_queue.dart';
import 'bag_error_messages.dart';
import 'bag_event.dart';
import 'bag_state.dart';

export 'bag_event.dart';
export 'bag_state.dart';

/// Re-fetches the bag in the background after a mutation whose follow-up
/// reload failed.
class _ResyncBag extends BagEvent {
  const _ResyncBag();
}

class BagBloc extends Bloc<BagEvent, BagState> {
  /// Shown when a session is queued locally instead of reaching the server.
  static const offlineSavedMessage =
      'Session saved offline. Will sync when back online.';

  /// Toast shown once the server has confirmed a restring.
  static const restringSuccessMessage =
      'Fresh stringbed mounted! Restrung to 100% health.';

  /// Background re-sync attempts after a failed post-mutation reload.
  static const maxResyncAttempts = 3;

  final Client client;

  /// Cap on the bag reload that follows a successful mutation; a slower
  /// reload counts as failed.
  final Duration reloadTimeout;

  /// Wait before each background re-sync attempt.
  final Duration resyncDelay;

  /// Sessions logged while the server is unreachable.
  final OfflineSessionQueue offlineQueue;

  StreamSubscription<BagStreamMessage>? _bagUpdatesSubscription;
  ConnectivityMonitor? _connectivityMonitor;

  /// Last status reported by the connectivity monitor; null until reported.
  bool? _isOnline;

  /// Racquets whose restring is still awaiting the server, so a double tap
  /// cannot retire two stringbeds.
  final _restringsInFlight = <int>{};

  /// Pending background re-sync, if any.
  Timer? _resyncTimer;

  /// Re-sync attempts made in the current cycle.
  int _resyncAttempts = 0;

  /// [offlineQueue] defaults to a volatile in-memory queue; the app passes one
  /// backed by `SharedPreferences`.
  BagBloc({
    required this.client,
    OfflineSessionQueue? offlineQueue,
    this.reloadTimeout = const Duration(seconds: 10),
    this.resyncDelay = const Duration(seconds: 5),
  }) : offlineQueue =
           offlineQueue ??
           OfflineSessionQueue(storage: InMemorySessionQueueStorage()),
       super(const BagInitial()) {
    on<LoadBag>(_onLoadBag);
    on<AddRacquet>(_onAddRacquet);
    on<DeleteRacquet>(_onDeleteRacquet);
    on<SetPrimaryRacquet>(_onSetPrimaryRacquet);
    on<SeedSampleBag>(_onSeedSampleBag);
    on<FastForwardRacquetAge>(_onFastForwardRacquetAge);
    on<BagStreamReceived>(_onBagStreamReceived);
    on<LogSession>(_onLogSession);
    on<SyncOfflineSessions>(_onSyncOfflineSessions);
    on<RestringRacquet>(_onRestringRacquet);
    on<_ResyncBag>(_onResyncBag);
    _listenToConnectivity();
  }

  /// Message for the toast shown after [count] queued sessions synced.
  static String syncedMessage(int count) =>
      'Synced $count offline session${count == 1 ? '' : 's'}';

  /// Returns [racquets] with a [durationMinutes] session applied to the
  /// active stringbed of [racquetId]: court hours incremented and health
  /// recalculated with the shared [DecayEngine], mirroring the server.
  static List<Racquet> applyOptimisticSession(
    List<Racquet> racquets, {
    required int racquetId,
    required int durationMinutes,
    DateTime? now,
  }) {
    return racquets.map((r) {
      final job = r.activeStringJob;
      if (r.id != racquetId || job == null) return r;
      final updatedHours = job.totalCourtHours + durationMinutes / 60.0;
      final optimisticHealth = DecayEngine.calculateHealth(
        hoursPlayed: updatedHours,
        maxRatedHours: job.maxRatedHours,
        stringingDate: job.stringingDate,
        materialCategory: job.materialCategory,
        now: now,
      );
      return r.copyWith(
        activeStringJob: job.copyWith(
          totalCourtHours: updatedHours,
          currentHealthScore: optimisticHealth,
        ),
      );
    }).toList();
  }

  /// Returns [racquets] with the restring in [event] applied to its active
  /// stringbed: health 100, no court hours, stringing date [now] and, unless
  /// [RestringRacquet.keepSame], the new specs.
  static List<Racquet> applyOptimisticRestring(
    List<Racquet> racquets,
    RestringRacquet event, {
    DateTime? now,
  }) {
    return racquets.map((r) {
      final job = r.activeStringJob;
      if (r.id != event.racquetId || job == null) return r;
      final fresh = job.copyWith(
        stringingDate: (now ?? DateTime.now()).toUtc(),
        totalCourtHours: 0.0,
        currentHealthScore: 100,
      );
      if (event.keepSame) return r.copyWith(activeStringJob: fresh);
      return r.copyWith(
        activeStringJob: fresh.copyWith(
          materialCategory: event.materialCategory ?? job.materialCategory,
          brand: event.stringBrand ?? job.brand,
          model: event.stringModel ?? job.model,
          installedTension: event.tension ?? job.installedTension,
          maxRatedHours: event.maxRatedHours ?? job.maxRatedHours,
        ),
      );
    }).toList();
  }

  /// Builds a [BagLoaded] carrying the current offline queue size.
  BagLoaded _loaded(
    List<Racquet> racquets, {
    String? errorMessage,
    String? infoMessage,
    String? successMessage,
    bool reauthRequired = false,
  }) {
    return BagLoaded(
      racquets,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
      successMessage: successMessage,
      pendingSyncCount: offlineQueue.pendingCount,
      reauthRequired: reauthRequired,
    );
  }

  /// Logs the raw [error] of a failed [operation] and returns the
  /// user-facing copy for it. [racquet] is the target as it was before the
  /// failure; [racquetName] names a racquet not yet in the bag.
  String _failure(
    BagOperation operation,
    Object error, {
    Racquet? racquet,
    String? racquetName,
  }) {
    debugPrint('BagBloc: ${operation.name} failed: $error');
    return bagErrorMessage(
      operation,
      error,
      racquet: racquet,
      racquetName: racquetName,
    );
  }

  /// The racquet [racquetId] in the current state, if loaded.
  Racquet? _racquetIn(BagState state, int racquetId) => state is BagLoaded
      ? state.racquets.where((r) => r.id == racquetId).firstOrNull
      : null;

  /// Applies still-queued sessions on top of authoritative server
  /// [racquets], so gauges keep reflecting play not yet synced.
  List<Racquet> _withPending(List<Racquet> racquets) {
    var result = racquets;
    for (final log in offlineQueue.pending) {
      result = applyOptimisticSession(
        result,
        racquetId: log.racquetId,
        durationMinutes: log.durationMinutes,
      );
    }
    return result;
  }

  Future<void> _loadQueue() async {
    try {
      await offlineQueue.load();
    } catch (e) {
      debugPrint('BagBloc: failed to load offline session queue: $e');
    }
  }

  void _listenToConnectivity() {
    try {
      _connectivityMonitor = client.connectivityMonitor;
      _connectivityMonitor?.addListener(_onConnectivityChanged);
    } catch (e) {
      debugPrint('BagBloc: connectivity monitor unavailable: $e');
      _connectivityMonitor = null;
    }
  }

  void _onConnectivityChanged(bool connected) {
    _isOnline = connected;
    if (connected && !isClosed) add(const SyncOfflineSessions());
  }

  @override
  Future<void> close() async {
    _cancelResync();
    _connectivityMonitor?.removeListener(_onConnectivityChanged);
    _connectivityMonitor = null;
    await _bagUpdatesSubscription?.cancel();
    _bagUpdatesSubscription = null;
    return super.close();
  }

  /// Subscribes to the server's real-time bag channel unless already
  /// subscribed. An error or done clears the subscription so the next
  /// [LoadBag] re-subscribes; there is no retry loop.
  void _subscribeToBagUpdates() {
    if (_bagUpdatesSubscription != null || isClosed) return;
    try {
      _bagUpdatesSubscription = client.bag.bagUpdates().listen(
        (message) {
          if (!isClosed) add(BagStreamReceived(message));
        },
        onError: (Object error) {
          debugPrint('BagBloc: bag updates stream error: $error');
          _clearBagUpdatesSubscription();
        },
        onDone: _clearBagUpdatesSubscription,
        cancelOnError: true,
      );
    } catch (e) {
      debugPrint('BagBloc: failed to subscribe to bag updates: $e');
      _bagUpdatesSubscription = null;
    }
  }

  void _clearBagUpdatesSubscription() {
    _bagUpdatesSubscription = null;
  }

  void _onBagStreamReceived(
    BagStreamReceived event,
    Emitter<BagState> emit,
  ) {
    final current = state;
    if (current is! BagLoaded) return;
    final message = event.message;
    final index = current.racquets.indexWhere(
      (r) => r.id == message.racquetId,
    );
    if (index == -1) return;
    final job = current.racquets[index].activeStringJob;
    if (job == null) return;

    final newRacquets = current.racquets.map((r) {
      if (r.id != message.racquetId) return r;
      return r.copyWith(
        activeStringJob: job.copyWith(
          currentHealthScore: message.healthScore ?? job.currentHealthScore,
          totalCourtHours: message.totalCourtHours ?? job.totalCourtHours,
        ),
      );
    }).toList();
    emit(_loaded(newRacquets));
  }

  /// Fetches the bag within [reloadTimeout] after a successful mutation;
  /// null when the reload fails or times out.
  Future<List<Racquet>?> _tryReload(String after) async {
    try {
      return await client.bag.getVirtualBag().timeout(reloadTimeout);
    } catch (e) {
      debugPrint('BagBloc: bag reload after $after failed: $e');
      return null;
    }
  }

  /// Adopts a successful post-mutation reload, or schedules a background
  /// re-sync when [racquets] is null (reload failed).
  void _adoptReload(List<Racquet>? racquets, Emitter<BagState> emit) {
    if (racquets == null) {
      _scheduleResync();
      return;
    }
    emit(_loaded(_withPending(racquets)));
  }

  /// Starts a fresh re-sync cycle of up to [maxResyncAttempts] attempts.
  void _scheduleResync() {
    _cancelResync();
    _armResyncTimer();
  }

  void _armResyncTimer() {
    _resyncTimer?.cancel();
    if (isClosed) return;
    _resyncTimer = Timer(resyncDelay, () {
      _resyncTimer = null;
      if (!isClosed) add(const _ResyncBag());
    });
  }

  void _cancelResync() {
    _resyncTimer?.cancel();
    _resyncTimer = null;
    _resyncAttempts = 0;
  }

  /// Silent background reconciliation: never emits [BagLoading] or an error.
  Future<void> _onResyncBag(_ResyncBag event, Emitter<BagState> emit) async {
    _resyncAttempts++;
    final before = state;
    final racquets = await _tryReload('re-sync');
    // Newer state landed meanwhile (mutation, log, restring, load): this
    // snapshot is stale, so drop it.
    if (isClosed || !identical(state, before)) return;
    if (racquets == null) {
      if (_resyncAttempts < maxResyncAttempts) {
        _armResyncTimer();
      } else {
        debugPrint('BagBloc: giving up background re-sync');
        _resyncAttempts = 0;
      }
      return;
    }
    _resyncAttempts = 0;
    emit(_loaded(_withPending(racquets)));
    _subscribeToBagUpdates();
  }

  Future<void> _onLoadBag(LoadBag event, Emitter<BagState> emit) async {
    emit(const BagLoading());
    try {
      final racquets = await client.bag.getVirtualBag();
      await _loadQueue();
      // A full load supersedes any pending background re-sync.
      _cancelResync();
      emit(_loaded(_withPending(racquets)));
      _subscribeToBagUpdates();
      // Drain sessions queued in a previous run (e.g. logged offline before
      // the app was closed) in the background.
      if (offlineQueue.pendingCount > 0 && !isClosed) {
        add(const SyncOfflineSessions());
      }
    } catch (e) {
      emit(BagError(_failure(BagOperation.loadBag, e)));
    } finally {
      event.onSettled?.call();
    }
  }

  /// Returns [racquets] with [created] added (or replacing a racquet with the
  /// same id); a primary [created] demotes every other racquet.
  static List<Racquet> _withCreated(List<Racquet> racquets, Racquet created) {
    final others = racquets.where((r) => r.id != created.id).map((r) {
      return created.isPrimary && r.isPrimary
          ? r.copyWith(isPrimary: false)
          : r;
    });
    return [...others, created];
  }

  Future<void> _onAddRacquet(AddRacquet event, Emitter<BagState> emit) async {
    final Racquet created;
    try {
      created = await client.bag.createRacquet(
        racquetName: event.name,
        brand: event.brand,
        model: event.model,
        isPrimary: event.isPrimary,
        materialCategory: event.materialCategory,
        stringBrand: event.stringBrand,
        stringModel: event.stringModel,
        tension: event.tension,
        maxRatedHours: event.maxRatedHours,
        stringingDate: event.stringingDate,
      );
    } catch (e) {
      emit(
        BagError(
          _failure(BagOperation.addRacquet, e, racquetName: event.name),
        ),
      );
      return;
    }

    // The racquet is saved: a failed reload must not be reported as a failed
    // add. Keep it in the bag and reconcile in the background.
    final racquets = await _tryReload('addRacquet');
    if (racquets == null) {
      final latest = state;
      if (latest is BagLoaded) {
        emit(_loaded(_withCreated(latest.racquets, created)));
      }
    }
    _adoptReload(racquets, emit);
  }

  Future<void> _onDeleteRacquet(
    DeleteRacquet event,
    Emitter<BagState> emit,
  ) async {
    try {
      await client.bag.deleteRacquet(racquetId: event.racquetId);
    } catch (e) {
      emit(
        BagError(
          _failure(
            BagOperation.deleteRacquet,
            e,
            racquet: _racquetIn(state, event.racquetId),
          ),
        ),
      );
      return;
    }
    final current = state;
    if (current is BagLoaded) {
      emit(
        _loaded(
          current.racquets.where((r) => r.id != event.racquetId).toList(),
        ),
      );
    } else {
      _adoptReload(await _tryReload('deleteRacquet'), emit);
    }
  }

  Future<void> _onSetPrimaryRacquet(
    SetPrimaryRacquet event,
    Emitter<BagState> emit,
  ) async {
    final Racquet updated;
    try {
      updated = await client.bag.setPrimary(racquetId: event.racquetId);
    } catch (e) {
      emit(
        BagError(
          _failure(
            BagOperation.setPrimaryRacquet,
            e,
            racquet: _racquetIn(state, event.racquetId),
          ),
        ),
      );
      return;
    }
    final current = state;
    if (current is BagLoaded) {
      final newRacquets = current.racquets.map((r) {
        if (r.id == event.racquetId) {
          return updated;
        } else if (r.isPrimary) {
          return r.copyWith(isPrimary: false);
        }
        return r;
      }).toList();
      emit(_loaded(newRacquets));
    } else {
      _adoptReload(await _tryReload('setPrimaryRacquet'), emit);
    }
  }

  Future<void> _onSeedSampleBag(
    SeedSampleBag event,
    Emitter<BagState> emit,
  ) async {
    emit(const BagLoading());
    try {
      final now = DateTime.now().toUtc();
      await client.bag.createRacquet(
        racquetName: 'Wilson Blade 98',
        brand: 'Wilson',
        model: 'Blade 98',
        isPrimary: true,
        materialCategory: StringMaterialCategory.coPoly,
        stringBrand: 'Luxilon',
        stringModel: 'ALU Power',
        tension: 52.0,
        maxRatedHours: 20.0,
        stringingDate: now.subtract(const Duration(days: 12)),
        initialCourtHours: 5.0,
      );
      await client.bag.createRacquet(
        racquetName: 'Babolat Pure Drive',
        brand: 'Babolat',
        model: 'Pure Drive',
        isPrimary: false,
        materialCategory: StringMaterialCategory.coPoly,
        stringBrand: 'Babolat',
        stringModel: 'RPM Blast',
        tension: 54.0,
        maxRatedHours: 20.0,
        stringingDate: now.subtract(const Duration(days: 24)),
        initialCourtHours: 9.0,
      );
      await client.bag.createRacquet(
        racquetName: 'Head Radical MP',
        brand: 'Head',
        model: 'Radical MP',
        isPrimary: false,
        materialCategory: StringMaterialCategory.multifilament,
        stringBrand: 'Head',
        stringModel: 'Velocity MLT',
        tension: 55.0,
        maxRatedHours: 35.0,
        stringingDate: now.subtract(const Duration(days: 64)),
        initialCourtHours: 25.0,
      );
      emit(_loaded(await client.bag.getVirtualBag()));
    } catch (e) {
      emit(BagError(_failure(BagOperation.seedSampleBag, e)));
    }
  }

  Future<void> _onFastForwardRacquetAge(
    FastForwardRacquetAge event,
    Emitter<BagState> emit,
  ) async {
    final Racquet updated;
    try {
      updated = await client.bag.fastForwardRacquetAge(
        racquetId: event.racquetId,
        days: event.days,
      );
    } catch (e) {
      emit(
        BagError(
          _failure(
            BagOperation.fastForwardRacquetAge,
            e,
            racquet: _racquetIn(state, event.racquetId),
          ),
        ),
      );
      return;
    }
    final current = state;
    if (current is BagLoaded) {
      emit(
        _loaded(
          current.racquets
              .map((r) => r.id == event.racquetId ? updated : r)
              .toList(),
        ),
      );
    } else {
      _adoptReload(await _tryReload('fastForwardRacquetAge'), emit);
    }
  }

  Future<void> _onLogSession(
    LogSession event,
    Emitter<BagState> emit,
  ) async {
    final externalId =
        event.externalWorkoutId ??
        'client_offline_${DateTime.now().microsecondsSinceEpoch}_${event.racquetId}';
    final log = SessionLog(
      userId: Namespace.nil.uuidValue,
      racquetId: event.racquetId,
      startTime: event.startTime,
      durationMinutes: event.durationMinutes,
      courtSurface: event.courtSurface,
      notes: event.notes,
      source: event.source,
      externalWorkoutId: externalId,
    );

    // Optimistic gauge decay, applied before any network round trip.
    final current = state;
    List<Racquet>? optimistic;
    if (current is BagLoaded) {
      optimistic = applyOptimisticSession(
        current.racquets,
        racquetId: event.racquetId,
        durationMinutes: event.durationMinutes,
      );
      emit(_loaded(optimistic));
    }

    // Skip the round trip when the device is known to be offline.
    if (_isOnline != false) {
      try {
        await client.session.logSession(log);
      } catch (e) {
        // An expired session can't be fixed by retrying later: prompt a
        // sign-in instead of queueing behind a "saved offline" toast.
        if (statusCodeOf(e) == 401) {
          _emitLogFailure(
            current,
            _failure(
              BagOperation.logSession,
              e,
              racquet: _racquetIn(current, event.racquetId),
            ),
            emit,
            reauthRequired: true,
          );
          return;
        }
        if (isPermanentSessionRejection(e)) {
          _emitLogFailure(
            current,
            _failure(
              BagOperation.logSession,
              e,
              racquet: _racquetIn(current, event.racquetId),
            ),
            emit,
          );
          return;
        }
        debugPrint('BagBloc: logSession unreachable, queueing offline: $e');
        await _queueOffline(log, event, current, optimistic, emit);
        return;
      }
    } else {
      await _queueOffline(log, event, current, optimistic, emit);
      return;
    }

    event.onLogged?.call();

    // The session is saved; a failed refresh must not be reported as a failed
    // log. The bag stream still delivers the updated health.
    try {
      final racquets = await client.bag.getVirtualBag();
      emit(_loaded(_withPending(racquets)));
    } catch (e) {
      debugPrint('BagBloc: bag refresh after logSession failed: $e');
    }
  }

  /// Reverts the optimistic gauge and surfaces a failed log.
  /// With [reauthRequired] the error offers a sign-in action.
  void _emitLogFailure(
    BagState previous,
    String message,
    Emitter<BagState> emit, {
    bool reauthRequired = false,
  }) {
    if (previous is BagLoaded) {
      // Clear first so a repeated identical error is still a new state.
      emit(_loaded(previous.racquets));
      emit(
        _loaded(
          previous.racquets,
          errorMessage: message,
          reauthRequired: reauthRequired,
        ),
      );
    } else {
      emit(BagError(message));
    }
  }

  /// Persists [log] in the offline queue, keeping the optimistic gauge and
  /// releasing the caller via [LogSession.onLogged].
  Future<void> _queueOffline(
    SessionLog log,
    LogSession event,
    BagState previous,
    List<Racquet>? optimistic,
    Emitter<BagState> emit,
  ) async {
    try {
      await offlineQueue.enqueue(log);
    } catch (e) {
      _emitLogFailure(
        previous,
        _failure(
          BagOperation.saveSessionOffline,
          e,
          racquet: _racquetIn(previous, log.racquetId),
        ),
        emit,
      );
      return;
    }

    event.onLogged?.call();

    final latest = state;
    final racquets =
        optimistic ?? (latest is BagLoaded ? latest.racquets : null);
    if (racquets != null) {
      emit(_loaded(racquets, infoMessage: offlineSavedMessage));
    }
  }

  Future<void> _onRestringRacquet(
    RestringRacquet event,
    Emitter<BagState> emit,
  ) async {
    final previous = state;
    if (previous is! BagLoaded) return;
    final original = previous.racquets
        .where((r) => r.id == event.racquetId && r.activeStringJob != null)
        .firstOrNull;
    if (original == null || !_restringsInFlight.add(event.racquetId)) return;

    List<Racquet> replaceTarget(Racquet replacement) {
      final latest = state;
      final racquets = latest is BagLoaded
          ? latest.racquets
          : previous.racquets;
      return racquets
          .map((r) => r.id == event.racquetId ? replacement : r)
          .toList();
    }

    // Optimistic reset, applied before any network round trip.
    emit(_loaded(applyOptimisticRestring(previous.racquets, event)));
    try {
      final updated = await client.bag.restringRacquet(
        racquetId: event.racquetId,
        keepSame: event.keepSame,
        materialCategory: event.materialCategory,
        stringBrand: event.stringBrand,
        stringModel: event.stringModel,
        tension: event.tension,
        maxRatedHours: event.maxRatedHours,
      );
      // Like every other server adoption, keep reflecting play still queued
      // offline: the server attributes it to the active (now fresh) stringbed.
      emit(
        _loaded(
          replaceTarget(_withPending([updated]).first),
          successMessage: restringSuccessMessage,
        ),
      );
    } catch (e) {
      final message = _failure(
        BagOperation.restringRacquet,
        e,
        racquet: original,
      );
      final reverted = replaceTarget(original);
      // Clear first so a repeated identical error is still a new state.
      emit(_loaded(reverted));
      emit(_loaded(reverted, errorMessage: message));
    } finally {
      _restringsInFlight.remove(event.racquetId);
    }
  }

  Future<void> _onSyncOfflineSessions(
    SyncOfflineSessions event,
    Emitter<BagState> emit,
  ) async {
    await _loadQueue();
    if (offlineQueue.pendingCount == 0) return;

    final SessionSyncResult result;
    try {
      result = await offlineQueue.sync(client.session.logSession);
    } catch (e) {
      debugPrint('BagBloc: offline session sync failed: $e');
      return;
    }
    if (result.synced == 0 && result.discarded == 0) return;

    final infoMessage = result.synced > 0 ? syncedMessage(result.synced) : null;
    try {
      final racquets = await client.bag.getVirtualBag();
      emit(_loaded(_withPending(racquets), infoMessage: infoMessage));
      _subscribeToBagUpdates();
    } catch (e) {
      debugPrint('BagBloc: bag refresh after offline sync failed: $e');
      final latest = state;
      if (latest is BagLoaded) {
        emit(_loaded(latest.racquets, infoMessage: infoMessage));
      }
    }
  }
}
