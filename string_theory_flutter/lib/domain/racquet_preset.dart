import 'package:string_theory_client/string_theory_client.dart';

/// Preset racquet and string bed configuration for 1-tap setup.
///
/// Encapsulates pure domain specifications with zero UI dependencies.
class RacquetPreset {
  final String name;
  final String? brand;
  final String? model;
  final StringMaterialCategory materialCategory;
  final String stringBrand;
  final String stringModel;
  final double tension;
  final double maxRatedHours;

  const RacquetPreset({
    required this.name,
    this.brand,
    this.model,
    required this.materialCategory,
    required this.stringBrand,
    required this.stringModel,
    required this.tension,
    required this.maxRatedHours,
  });

  /// Popular Poly preset: Babolat RPM Blast @ 52 lbs on Babolat Pure Aero
  static const popularPoly = RacquetPreset(
    name: 'Babolat Pure Aero',
    brand: 'Babolat',
    model: 'Pure Aero',
    materialCategory: StringMaterialCategory.coPoly,
    stringBrand: 'Babolat',
    stringModel: 'RPM Blast',
    tension: 52.0,
    maxRatedHours: 20.0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RacquetPreset &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          brand == other.brand &&
          model == other.model &&
          materialCategory == other.materialCategory &&
          stringBrand == other.stringBrand &&
          stringModel == other.stringModel &&
          tension == other.tension &&
          maxRatedHours == other.maxRatedHours;

  @override
  int get hashCode => Object.hash(
    name,
    brand,
    model,
    materialCategory,
    stringBrand,
    stringModel,
    tension,
    maxRatedHours,
  );
}
