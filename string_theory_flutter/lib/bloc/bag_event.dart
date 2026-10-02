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
