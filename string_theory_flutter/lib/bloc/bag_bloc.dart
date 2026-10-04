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
}
