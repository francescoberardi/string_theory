import 'package:equatable/equatable.dart';
import 'package:string_theory_client/string_theory_client.dart';

abstract class BagEvent extends Equatable {
  const BagEvent();

  @override
  List<Object?> get props => [];
}

class LoadBag extends BagEvent {
  const LoadBag();
}

class AddRacquet extends BagEvent {
  final String name;
  final String? brand;
  final String? model;
  final bool isPrimary;
  final StringMaterialCategory materialCategory;
  final String stringBrand;
  final String stringModel;
  final double tension;
  final double maxRatedHours;
  final DateTime stringingDate;

  const AddRacquet({
    required this.name,
    this.brand,
    this.model,
    this.isPrimary = false,
    this.materialCategory = StringMaterialCategory.coPoly,
    required this.stringBrand,
    required this.stringModel,
    required this.tension,
    required this.maxRatedHours,
    required this.stringingDate,
  });

  @override
  List<Object?> get props => [
    name,
    brand,
    model,
    isPrimary,
    materialCategory,
    stringBrand,
    stringModel,
    tension,
    maxRatedHours,
    stringingDate,
  ];
}

class DeleteRacquet extends BagEvent {
  final int racquetId;

  const DeleteRacquet(this.racquetId);

  @override
  List<Object?> get props => [racquetId];
}

class SetPrimaryRacquet extends BagEvent {
  final int racquetId;

  const SetPrimaryRacquet(this.racquetId);

  @override
  List<Object?> get props => [racquetId];
}

class SeedSampleBag extends BagEvent {
  const SeedSampleBag();
}

class FastForwardRacquetAge extends BagEvent {
  final int racquetId;
  final int days;

  const FastForwardRacquetAge(this.racquetId, {this.days = 30});

  @override
  List<Object?> get props => [racquetId, days];
}

/// A real-time [BagStreamMessage] pushed by the server on the user's bag
/// channel.
class BagStreamReceived extends BagEvent {
  final BagStreamMessage message;

  const BagStreamReceived(this.message);

  @override
  List<Object?> get props => [message];
}

/// Logs a tennis session against [racquetId], attributing court time to its
/// active stringbed.
class LogSession extends BagEvent {
  final int racquetId;
  final DateTime startTime;
  final int durationMinutes;
  final String? courtSurface;
  final String? notes;
  final String source;
  final String? externalWorkoutId;

  const LogSession({
    required this.racquetId,
    required this.startTime,
    required this.durationMinutes,
    this.courtSurface,
    this.notes,
    required this.source,
    this.externalWorkoutId,
  });

  @override
  List<Object?> get props => [
    racquetId,
    startTime,
    durationMinutes,
    courtSurface,
    notes,
    source,
    externalWorkoutId,
  ];
}
