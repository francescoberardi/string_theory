import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_theory_client/string_theory_client.dart';

import 'bag_event.dart';
import 'bag_state.dart';

export 'bag_event.dart';
export 'bag_state.dart';

class BagBloc extends Bloc<BagEvent, BagState> {
  final Client client;

  BagBloc({required this.client}) : super(const BagInitial()) {
    on<LoadBag>(_onLoadBag);
    on<AddRacquet>(_onAddRacquet);
    on<DeleteRacquet>(_onDeleteRacquet);
    on<SetPrimaryRacquet>(_onSetPrimaryRacquet);
    on<SeedSampleBag>(_onSeedSampleBag);
  }

  Future<void> _onLoadBag(LoadBag event, Emitter<BagState> emit) async {
    emit(const BagLoading());
    try {
      final racquets = await client.bag.getVirtualBag();
      emit(BagLoaded(racquets));
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
    // Red-phase stub pending Story 1.5 implementation
  }
}
