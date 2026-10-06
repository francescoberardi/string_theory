import 'package:string_theory_server/src/domain/decay_engine.dart';
import 'package:string_theory_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  group('Story 2.1: DecayEngine Pure Dart Domain Calculations', () {
    group('AC-1: Composite Health Score Calculation', () {
      test(
        '[P0] AC-1 should calculate composite health score from dynamic hours and calendar days',
        () {
          // Given: A co-poly string job with 10.0 hours played out of 20.0 max rated hours,
          // strung 37.5 days ago (exact half of 75-day co-poly shelf life).
          final stringingDate = DateTime(2026, 1, 1);
          final testNow = DateTime(2026, 1, 1).add(
            const Duration(days: 37, hours: 12),
          );

          // When: DecayEngine.calculateHealth executes
          // Dynamic penalty: (10.0 / 20.0) * 70 = 35.0
          // Calendar penalty: (37.5 / 75.0) * 30 = 15.0
          // Total penalty = 50.0 -> Expected HealthScore = 50%
          final healthScore = DecayEngine.calculateHealth(
            hoursPlayed: 10.0,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
            materialCategory: StringMaterialCategory.coPoly,
            now: testNow,
          );

          // Then: Health score is 50%
          expect(healthScore, equals(50));
        },
      );

      test(
        '[P0] AC-1 should weigh 70% dynamic playtime and 30% static calendar creep independently',
        () {
          // Given: Fresh strings (0 days old) played for full max rated hours (20.0h / 20.0h)
          final stringingDate = DateTime(2026, 2, 1);
          final testNow = stringingDate; // 0 days elapsed

          // When: 100% court hours consumed, 0% calendar creep
          // Dynamic penalty = 70, Calendar penalty = 0 -> Expected Health = 30%
          final health = DecayEngine.calculateHealth(
            hoursPlayed: 20.0,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
            materialCategory: StringMaterialCategory.coPoly,
            now: testNow,
          );

          // Then: Exactly 30% health remains
          expect(health, equals(30));
        },
      );
    });

    group('AC-2: Secondary Tension Loss Formatting', () {
      test(
        '[P1] AC-2 should calculate secondary tension loss text based on health degradation',
        () {
          // Given: A racquet with 50% health degradation strung at 52 lbs (~23.6 kg)
          // When: Formatting tension drop text
          final text = DecayEngine.calculateTensionLossText(
            healthScore: 50,
            installedTensionLbs: 52.0,
          );

          // Then: Secondary tension loss displays format with kg and lbs drop
          expect(text, contains('kg'));
          expect(text, contains('lbs drop'));
        },
      );

      test(
        '[P1] AC-2 should report 0 drop when health score is 100%',
        () {
          // Given: Brand new fresh stringbed at 100% health
          final text = DecayEngine.calculateTensionLossText(
            healthScore: 100,
            installedTensionLbs: 52.0,
          );

          // Then: Tension loss indicates no drop
          expect(text, equals('~0.0 kg / ~0.0 lbs drop'));
        },
      );

      test(
        '[P1] AC-2 should clamp negative installed tension to 0 drop',
        () {
          // Given: A degraded health score with negative installed tension
          final text = DecayEngine.calculateTensionLossText(
            healthScore: 50,
            installedTensionLbs: -52.0,
          );

          // Then: Tension loss indicates 0 drop without negative numbers
          expect(text, equals('~0.0 kg / ~0.0 lbs drop'));
        },
      );
    });

    group('AC-3: Boundary Clamping & Material Category Shelf Life Tiers', () {
      test(
        '[P0] AC-3 should return 100% health for fresh unplayed strings (0 hours, 0 days)',
        () {
          // Given: 0 hours played, strung today
          final now = DateTime(2026, 3, 1);
          final health = DecayEngine.calculateHealth(
            hoursPlayed: 0.0,
            maxRatedHours: 20.0,
            stringingDate: now,
            materialCategory: StringMaterialCategory.coPoly,
            now: now,
          );

          // Then: Health is 100%
          expect(health, equals(100));
        },
      );

      test(
        '[P0] AC-3 should clamp health score to 0% after 400 days elapsed even with 0 hours played',
        () {
          // Given: 0 hours played, but strung >400 days ago (shelf life 75 days)
          // Calendar penalty: (424 / 75) * 30 = ~169.6 -> clamped to 0%
          final stringingDate = DateTime(2025, 1, 1);
          final now = DateTime(2026, 3, 1); // >400 days
          final health = DecayEngine.calculateHealth(
            hoursPlayed: 0.0,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
            materialCategory: StringMaterialCategory.coPoly,
            now: now,
          );

          // Then: Health is clamped to 0% purely by calendar aging
          expect(health, equals(0));
        },
      );

      test(
        '[P0] AC-3 should clamp health score to 0% when penalties exceed 100%',
        () {
          // Given: 40 hours played on 20h rated strings, strung 400 days ago
          final stringingDate = DateTime(2025, 1, 1);
          final now = DateTime(2026, 3, 1); // >400 days
          final health = DecayEngine.calculateHealth(
            hoursPlayed: 40.0,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
            materialCategory: StringMaterialCategory.coPoly,
            now: now,
          );

          // Then: Health never drops below 0%
          expect(health, equals(0));
        },
      );

      test(
        '[P0] AC-3 should clamp negative hours or future dates to 0 penalty (capped at 100%)',
        () {
          // Given: Negative hours played or future stringing date
          final now = DateTime(2026, 3, 1);
          final futureDate = DateTime(2026, 3, 10);
          final health = DecayEngine.calculateHealth(
            hoursPlayed: -5.0,
            maxRatedHours: 20.0,
            stringingDate: futureDate,
            materialCategory: StringMaterialCategory.coPoly,
            now: now,
          );

          // Then: Health is clamped to 100%
          expect(health, equals(100));
        },
      );

      test(
        '[P0] AC-3 should map correct shelf lives per material category',
        () {
          // Co-Poly: 75 days
          expect(
            DecayEngine.getShelfLifeDays(StringMaterialCategory.coPoly),
            equals(75),
          );
          // Multifilament: 180 days
          expect(
            DecayEngine.getShelfLifeDays(StringMaterialCategory.multifilament),
            equals(180),
          );
          // Synthetic Gut: 180 days
          expect(
            DecayEngine.getShelfLifeDays(StringMaterialCategory.syntheticGut),
            equals(180),
          );
          // Natural Gut: 365 days
          expect(
            DecayEngine.getShelfLifeDays(StringMaterialCategory.naturalGut),
            equals(365),
          );
          // Fallbacks / Other: 180 days
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
