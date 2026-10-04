import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_theory_client/string_theory_client.dart';

import 'bag_event.dart';
import 'bag_state.dart';

export 'bag_event.dart';
export 'bag_state.dart';

class BagBloc extends Bloc<BagEvent, BagState> {
  final Client client;
  StreamSubscription<BagStreamMessage>? _bagUpdatesSubscription;

  BagBloc({required this.client}) : super(const BagInitial()) {
    on<LoadBag>(_onLoadBag);
    on<AddRacquet>(_onAddRacquet);
    on<DeleteRacquet>(_onDeleteRacquet);
    on<SetPrimaryRacquet>(_onSetPrimaryRacquet);
    on<SeedSampleBag>(_onSeedSampleBag);
    on<FastForwardRacquetAge>(_onFastForwardRacquetAge);
    on<BagStreamReceived>(_onBagStreamReceived);
    on<LogSession>(_onLogSession);
  }

  @override
  Future<void> close() async {
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
    emit(BagLoaded(newRacquets));
  }

  Future<void> _onLoadBag(LoadBag event, Emitter<BagState> emit) async {
    emit(const BagLoading());
    try {
      final racquets = await client.bag.getVirtualBag();
      emit(BagLoaded(racquets));
      _subscribeToBagUpdates();
    } catch (e) {
      emit(BagError('Failed to load virtual bag: $e'));
    }
  }

  Future<void> _onAddRacquet(AddRacquet event, Emitter<BagState> emit) async {
    try {
      await client.bag.createRacquet(
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
      final racquets = await client.bag.getVirtualBag();
      emit(BagLoaded(racquets));
    } catch (e) {
      emit(BagError('Failed to add racquet: $e'));
    }
  }

  Future<void> _onDeleteRacquet(
    DeleteRacquet event,
    Emitter<BagState> emit,
  ) async {
    try {
      await client.bag.deleteRacquet(racquetId: event.racquetId);
      if (state is BagLoaded) {
        final currentRacquets = (state as BagLoaded).racquets;
        final newRacquets = currentRacquets
            .where((r) => r.id != event.racquetId)
            .toList();
        emit(BagLoaded(newRacquets));
      } else {
        final racquets = await client.bag.getVirtualBag();
        emit(BagLoaded(racquets));
      }
    } catch (e) {
      emit(BagError('Failed to delete racquet: $e'));
    }
  }

  Future<void> _onSetPrimaryRacquet(
    SetPrimaryRacquet event,
    Emitter<BagState> emit,
  ) async {
    try {
      final updated = await client.bag.setPrimary(racquetId: event.racquetId);
      if (state is BagLoaded) {
        final currentRacquets = (state as BagLoaded).racquets;
        final newRacquets = currentRacquets.map((r) {
          if (r.id == event.racquetId) {
            return updated;
          } else if (r.isPrimary) {
            return r.copyWith(isPrimary: false);
          }
          return r;
        }).toList();
        emit(BagLoaded(newRacquets));
      } else {
        final racquets = await client.bag.getVirtualBag();
        emit(BagLoaded(racquets));
      }
    } catch (e) {
      emit(BagError('Failed to set primary racquet: $e'));
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
      );
      final racquets = await client.bag.getVirtualBag();
      final seededRacquets = racquets.map((r) {
        if (r.name == 'Wilson Blade 98' &&
            (r.activeStringJob?.totalCourtHours ?? 0.0) == 0.0) {
          final job = r.activeStringJob?.copyWith(
            totalCourtHours: 5.0,
            currentHealthScore: 76,
          );
          return r.copyWith(activeStringJob: job);
        } else if (r.name == 'Babolat Pure Drive' &&
            (r.activeStringJob?.totalCourtHours ?? 0.0) == 0.0) {
          final job = r.activeStringJob?.copyWith(
            totalCourtHours: 9.0,
            currentHealthScore: 58,
          );
          return r.copyWith(activeStringJob: job);
        } else if (r.name == 'Head Radical MP' &&
            (r.activeStringJob?.totalCourtHours ?? 0.0) == 0.0) {
          final job = r.activeStringJob?.copyWith(
            totalCourtHours: 25.0,
            currentHealthScore: 34,
          );
          return r.copyWith(activeStringJob: job);
        }
        return r;
      }).toList();
      emit(BagLoaded(seededRacquets));
    } catch (e) {
      emit(BagError('Failed to seed sample bag: $e'));
    }
  }

  Future<void> _onFastForwardRacquetAge(
    FastForwardRacquetAge event,
    Emitter<BagState> emit,
  ) async {
    try {
      final updated = await client.bag.fastForwardRacquetAge(
        racquetId: event.racquetId,
        days: event.days,
      );
      if (state is BagLoaded) {
        final currentRacquets = (state as BagLoaded).racquets;
        final newRacquets = currentRacquets.map((r) {
          return r.id == event.racquetId ? updated : r;
        }).toList();
        emit(BagLoaded(newRacquets));
      } else {
        final racquets = await client.bag.getVirtualBag();
        emit(BagLoaded(racquets));
      }
    } catch (e) {
      emit(BagError('Failed to fast-forward racquet age: $e'));
    }
  }

  Future<void> _onLogSession(
    LogSession event,
    Emitter<BagState> emit,
  ) async {
    try {
      await client.session.logSession(
        SessionLog(
          userId: 0,
          racquetId: event.racquetId,
          startTime: event.startTime,
          durationMinutes: event.durationMinutes,
          courtSurface: event.courtSurface,
          notes: event.notes,
          source: event.source,
          externalWorkoutId: event.externalWorkoutId,
        ),
      );
      final racquets = await client.bag.getVirtualBag();
      emit(BagLoaded(racquets));
    } catch (e) {
      if (state is BagLoaded) {
        emit(
          BagLoaded(
            (state as BagLoaded).racquets,
            errorMessage: 'Failed to log session: $e',
          ),
        );
      } else {
        emit(BagError('Failed to log session: $e'));
      }
    }
  }
}
