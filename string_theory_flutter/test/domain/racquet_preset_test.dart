import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/domain/decay_engine.dart';
import 'package:string_theory_flutter/domain/racquet_preset.dart';

import '../helpers/tdd_red_phase.dart';

void main() {
  group('Story 6.4: Domain Model Extraction - RacquetPreset (AC-4)', () {
    test(
      '[P2] [AC-4] RacquetPreset domain model encapsulates pure specifications and popularPoly preset without UI dependencies',
      skip: tddRedPhase64 ? tddRedPhase64Reason : null,
      () {
        // 1. Pure domain instantiation without UI dependencies
        const customPreset = RacquetPreset(
          name: 'Wilson Pro Staff 97',
          brand: 'Wilson',
          model: 'Pro Staff 97',
          materialCategory: StringMaterialCategory.coPoly,
          stringBrand: 'Luxilon',
          stringModel: 'ALU Power',
          tension: 54.0,
          maxRatedHours: 20.0,
        );

        // Criterion-defining assertion: preset values correctly encapsulated in domain model
        expect(customPreset.name, equals('Wilson Pro Staff 97'));
        expect(customPreset.brand, equals('Wilson'));
        expect(customPreset.model, equals('Pro Staff 97'));
        expect(
          customPreset.materialCategory,
          equals(StringMaterialCategory.coPoly),
        );
        expect(customPreset.stringBrand, equals('Luxilon'));
        expect(customPreset.stringModel, equals('ALU Power'));
        expect(customPreset.tension, equals(54.0));
        expect(customPreset.maxRatedHours, equals(20.0));

        // 2. Canonical popularPoly default preset properties
        const popular = RacquetPreset.popularPoly;
        expect(popular.name, equals('Babolat Pure Aero'));
        expect(popular.brand, equals('Babolat'));
        expect(popular.model, equals('Pure Aero'));
        expect(popular.materialCategory, equals(StringMaterialCategory.coPoly));
        expect(popular.stringBrand, equals('Babolat'));
        expect(popular.stringModel, equals('RPM Blast'));
        expect(popular.tension, equals(52.0));

        // 3. Alignment with domain StringCategoryDefaults
        expect(
          popular.maxRatedHours,
          equals(
            StringCategoryDefaults.maxHours(StringMaterialCategory.coPoly),
          ),
          reason:
              'Preset maxRatedHours must strictly match domain StringCategoryDefaults',
        );
      },
    );

    test('RacquetPreset supports value equality and hashCode', () {
      const presetA = RacquetPreset(
        name: 'Wilson Blade 98',
        brand: 'Wilson',
        model: 'Blade 98',
        materialCategory: StringMaterialCategory.coPoly,
        stringBrand: 'Luxilon',
        stringModel: 'ALU Power',
        tension: 52.0,
        maxRatedHours: 20.0,
      );

      const presetB = RacquetPreset(
        name: 'Wilson Blade 98',
        brand: 'Wilson',
        model: 'Blade 98',
        materialCategory: StringMaterialCategory.coPoly,
        stringBrand: 'Luxilon',
        stringModel: 'ALU Power',
        tension: 52.0,
        maxRatedHours: 20.0,
      );

      expect(presetA, equals(presetB));
      expect(presetA.hashCode, equals(presetB.hashCode));
    });
  });
}
