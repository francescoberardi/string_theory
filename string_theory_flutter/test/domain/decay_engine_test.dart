import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/domain/decay_engine.dart';

void main() {
  group('Story 2.1: DecayEngine Flutter Domain Calculations', () {
    group('AC-1: Composite Health Score Calculation', () {
      test(
        '[P0] AC-1 should calculate composite health score from dynamic hours and calendar days',
        () {
          final stringingDate = DateTime(2026, 1, 1);
          final testNow = DateTime(2026, 1, 1).add(
            const Duration(days: 37, hours: 12),
          );

          final healthScore = DecayEngine.calculateHealth(
            hoursPlayed: 10.0,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
            materialCategory: StringMaterialCategory.coPoly,
            now: testNow,
          );

          expect(healthScore, equals(50));
        },
      );

      test(
        '[P0] AC-1 should weigh 70% dynamic playtime and 30% static calendar creep independently',
        () {
          final stringingDate = DateTime(2026, 2, 1);
          final testNow = stringingDate;

          final health = DecayEngine.calculateHealth(
            hoursPlayed: 20.0,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
            materialCategory: StringMaterialCategory.coPoly,
            now: testNow,
          );

          expect(health, equals(30));
        },
      );
    });

    group('AC-2: Secondary Tension Loss Formatting', () {
      test(
        '[P1] AC-2 should calculate secondary tension loss text based on health degradation',
        () {
          final text = DecayEngine.calculateTensionLossText(
            healthScore: 50,
            installedTensionLbs: 52.0,
          );

          expect(text, contains('kg'));
          expect(text, contains('lbs drop'));
        },
      );

      test(
        '[P1] AC-2 should report 0 drop when health score is 100%',
        () {
          final text = DecayEngine.calculateTensionLossText(
            healthScore: 100,
            installedTensionLbs: 52.0,
          );

          expect(text, equals('~0.0 kg / ~0.0 lbs drop'));
        },
      );

      test(
        '[P1] AC-2 should clamp negative installed tension to 0 drop',
        () {
          final text = DecayEngine.calculateTensionLossText(
            healthScore: 50,
            installedTensionLbs: -52.0,
          );

          expect(text, equals('~0.0 kg / ~0.0 lbs drop'));
        },
      );
    });

    group('AC-3: Boundary Clamping & Material Category Shelf Life Tiers', () {
      test(
        '[P0] AC-3 should return 100% health for fresh unplayed strings (0 hours, 0 days)',
        () {
          final now = DateTime(2026, 3, 1);
          final health = DecayEngine.calculateHealth(
            hoursPlayed: 0.0,
            maxRatedHours: 20.0,
            stringingDate: now,
            materialCategory: StringMaterialCategory.coPoly,
            now: now,
          );

          expect(health, equals(100));
        },
      );

      test(
        '[P0] AC-3 should clamp health score to 0% after 400 days elapsed even with 0 hours played',
        () {
          final stringingDate = DateTime(2025, 1, 1);
          final now = DateTime(2026, 3, 1);
          final health = DecayEngine.calculateHealth(
            hoursPlayed: 0.0,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
            materialCategory: StringMaterialCategory.coPoly,
            now: now,
          );

          expect(health, equals(0));
        },
      );

      test(
        '[P0] AC-3 should clamp health score to 0% when penalties exceed 100%',
        () {
          final stringingDate = DateTime(2025, 1, 1);
          final now = DateTime(2026, 3, 1);
          final health = DecayEngine.calculateHealth(
            hoursPlayed: 40.0,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
            materialCategory: StringMaterialCategory.coPoly,
            now: now,
          );

          expect(health, equals(0));
        },
      );

      test(
        '[P0] AC-3 should clamp negative hours or future dates to 0 penalty (capped at 100%)',
        () {
          final now = DateTime(2026, 3, 1);
          final futureDate = DateTime(2026, 3, 10);
          final health = DecayEngine.calculateHealth(
            hoursPlayed: -5.0,
            maxRatedHours: 20.0,
            stringingDate: futureDate,
            materialCategory: StringMaterialCategory.coPoly,
            now: now,
          );

          expect(health, equals(100));
        },
      );

      test(
        '[P0] AC-3 should map correct shelf lives per material category',
        () {
          expect(
            DecayEngine.getShelfLifeDays(StringMaterialCategory.coPoly),
            equals(75),
          );
          expect(
            DecayEngine.getShelfLifeDays(StringMaterialCategory.multifilament),
            equals(180),
          );
          expect(
            DecayEngine.getShelfLifeDays(StringMaterialCategory.syntheticGut),
            equals(180),
          );
          expect(
            DecayEngine.getShelfLifeDays(StringMaterialCategory.naturalGut),
            equals(365),
          );
          expect(
            DecayEngine.getShelfLifeDays(StringMaterialCategory.hybrid),
            equals(180),
          );
          expect(
            DecayEngine.getShelfLifeDays(StringMaterialCategory.kevlar),
            equals(120),
          );
          expect(
            DecayEngine.getShelfLifeDays(StringMaterialCategory.other),
            equals(180),
          );
        },
      );

      test('[P1] AC-2 should compute exact tension drop values', () {
        expect(
          DecayEngine.calculateTensionLossText(healthScore: 50),
          equals('~2.9 kg / ~6.5 lbs drop'),
        );
        expect(
          DecayEngine.calculateTensionLossText(healthScore: 0),
          equals('~5.9 kg / ~13.0 lbs drop'),
        );
      });

      test('[P0] AC-3 should not divide by zero when maxRatedHours is 0', () {
        final now = DateTime(2026, 3, 1);
        final health = DecayEngine.calculateHealth(
          hoursPlayed: 5.0,
          maxRatedHours: 0.0,
          stringingDate: now,
          materialCategory: StringMaterialCategory.coPoly,
          now: now,
        );
        expect(health, equals(0));
      });
    });

    group('Generated Enum Parity', () {
      test(
        'every generated StringMaterialCategory maps to a same-named domain category',
        () {
          final domainNames = DomainStringMaterialCategory.values
              .asNameMap()
              .keys
              .toSet();
          for (final category in StringMaterialCategory.values) {
            expect(
              domainNames,
              contains(category.name),
              reason:
                  '${category.name} would silently fall back to `other` decay rules',
            );
          }
          expect(
            StringMaterialCategory.values.length,
            equals(DomainStringMaterialCategory.values.length),
          );
        },
      );
    });
  });
}
