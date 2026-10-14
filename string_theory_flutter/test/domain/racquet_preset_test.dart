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
          brand: 'Baseline',
          model: 'Pro Staff 97',
          materialCategory: StringMaterialCategory.coPoly,
          stringBrand: 'Baseline',
          stringModel: 'Poly Tour',
          tension: 54.0,
          maxRatedHours: 20.0,
        );

        // Criterion-defining assertion: preset values correctly encapsulated in domain model
        expect(customPreset.name, equals('Wilson Pro Staff 97'));
        expect(customPreset.brand, equals('Baseline'));
        expect(customPreset.model, equals('Pro Staff 97'));
        expect(
          customPreset.materialCategory,
          equals(StringMaterialCategory.coPoly),
        );
        expect(customPreset.stringBrand, equals('Baseline'));
        expect(customPreset.stringModel, equals('Poly Tour'));
        expect(customPreset.tension, equals(54.0));
        expect(customPreset.maxRatedHours, equals(20.0));

        // 2. Canonical popularPoly default preset properties
        const popular = RacquetPreset.popularPoly;
        expect(popular.name, equals('Baseline Spin 100'));
        expect(popular.brand, equals('Baseline'));
        expect(popular.model, equals('Spin 100'));
        expect(popular.materialCategory, equals(StringMaterialCategory.coPoly));
        expect(popular.stringBrand, equals('Baseline'));
        expect(popular.stringModel, equals('Spin Poly'));
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
        name: 'Tour 98',
        brand: 'Baseline',
        model: 'Tour 98',
        materialCategory: StringMaterialCategory.coPoly,
        stringBrand: 'Baseline',
        stringModel: 'Poly Tour',
        tension: 52.0,
        maxRatedHours: 20.0,
      );

      const presetB = RacquetPreset(
        name: 'Tour 98',
        brand: 'Baseline',
        model: 'Tour 98',
        materialCategory: StringMaterialCategory.coPoly,
        stringBrand: 'Baseline',
        stringModel: 'Poly Tour',
        tension: 52.0,
        maxRatedHours: 20.0,
      );

      expect(presetA, equals(presetB));
      expect(presetA.hashCode, equals(presetB.hashCode));
    });
  });
}
