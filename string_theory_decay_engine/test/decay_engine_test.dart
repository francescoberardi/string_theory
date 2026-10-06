import 'package:string_theory_decay_engine/string_theory_decay_engine.dart';
import 'package:test/test.dart';

enum ForeignStringMaterialCategory {
  coPoly,
  multifilament,
  syntheticGut,
  naturalGut,
  kevlar,
  hybrid,
  other,
  exoticFutureMaterial,
}

void main() {
  group('DecayEngine Domain Calculations & Health Tiers', () {
    group('HealthTier Classification & Semantics', () {
      test('should classify health scores >= 70 as optimal', () {
        expect(DecayEngine.getHealthTier(100), equals(HealthTier.optimal));
        expect(DecayEngine.getHealthTier(70), equals(HealthTier.optimal));
        expect(DecayEngine.getHealthTier(71), equals(HealthTier.optimal));
        expect(DecayEngine.getHealthTier(150), equals(HealthTier.optimal));

        final tier = HealthTier.fromScore(70);
        expect(tier.isOptimal, isTrue);
        expect(tier.isDegraded, isFalse);
        expect(tier.isCritical, isFalse);
        expect(tier.description, equals('Optimal condition'));
      });

      test('should classify health scores between 40 and 69 as degraded', () {
        expect(DecayEngine.getHealthTier(69), equals(HealthTier.degraded));
        expect(DecayEngine.getHealthTier(40), equals(HealthTier.degraded));
        expect(DecayEngine.getHealthTier(55), equals(HealthTier.degraded));

        final tier = HealthTier.fromScore(50);
        expect(tier.isOptimal, isFalse);
        expect(tier.isDegraded, isTrue);
        expect(tier.isCritical, isFalse);
        expect(tier.description, equals('Degraded condition'));
      });

      test('should classify health scores < 40 as critical', () {
        expect(DecayEngine.getHealthTier(39), equals(HealthTier.critical));
        expect(DecayEngine.getHealthTier(0), equals(HealthTier.critical));
        expect(DecayEngine.getHealthTier(-10), equals(HealthTier.critical));

        final tier = HealthTier.fromScore(20);
        expect(tier.isOptimal, isFalse);
        expect(tier.isDegraded, isFalse);
        expect(tier.isCritical, isTrue);
        expect(tier.description, equals('Critical condition, high shock risk'));
      });
    });

    group('Composite Health Score Calculation', () {
      test(
        'should calculate composite health score from dynamic hours and calendar days',
        () {
          final stringingDate = DateTime(2026, 1, 1);
          final testNow = DateTime(
            2026,
            1,
            1,
          ).add(const Duration(days: 37, hours: 12));

          final healthScore = DecayEngine.calculateHealth(
            hoursPlayed: 10.0,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
            materialCategory: DomainStringMaterialCategory.coPoly,
            now: testNow,
          );

          expect(healthScore, equals(50));
        },
      );

      test(
        'should weigh 70% dynamic playtime and 30% static calendar creep independently',
        () {
          final stringingDate = DateTime(2026, 2, 1);
          final testNow = stringingDate;

          final health = DecayEngine.calculateHealth(
            hoursPlayed: 20.0,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
            materialCategory: DomainStringMaterialCategory.coPoly,
            now: testNow,
          );

          expect(health, equals(30));
        },
      );

      test('should accept polymorphic Enum inputs from external packages', () {
        final stringingDate = DateTime(2026, 1, 1);
        final testNow = DateTime(
          2026,
          1,
          1,
        ).add(const Duration(days: 37, hours: 12));

        final scoreFromForeign = DecayEngine.calculateHealth(
          hoursPlayed: 10.0,
          maxRatedHours: 20.0,
          stringingDate: stringingDate,
          materialCategory: ForeignStringMaterialCategory.coPoly,
          now: testNow,
        );

        expect(scoreFromForeign, equals(50));

        final scoreFromUnknown = DecayEngine.calculateHealth(
          hoursPlayed: 10.0,
          maxRatedHours: 20.0,
          stringingDate: stringingDate,
          materialCategory: ForeignStringMaterialCategory.exoticFutureMaterial,
          now: testNow,
        );
        // Falls back to other (shelf life 180 days)
        // Dynamic: (10/20)*70 = 35
        // Calendar: (37.5/180)*30 = 6.25
        // Total = 41.25 -> 58.75 -> 59
        expect(scoreFromUnknown, equals(59));
      });

      test('should clamp boundary conditions correctly', () {
        final now = DateTime(2026, 3, 1);

        // Fresh unplayed strings
        expect(
          DecayEngine.calculateHealth(
            hoursPlayed: 0.0,
            maxRatedHours: 20.0,
            stringingDate: now,
            materialCategory: DomainStringMaterialCategory.coPoly,
            now: now,
          ),
          equals(100),
        );

        // Overplayed / aged out -> clamps to 0%
        expect(
          DecayEngine.calculateHealth(
            hoursPlayed: 40.0,
            maxRatedHours: 20.0,
            stringingDate: DateTime(2025, 1, 1),
            materialCategory: DomainStringMaterialCategory.coPoly,
            now: now,
          ),
          equals(0),
        );

        // Negative hours or future date -> clamps to 100%
        expect(
          DecayEngine.calculateHealth(
            hoursPlayed: -5.0,
            maxRatedHours: 20.0,
            stringingDate: DateTime(2026, 3, 10),
            materialCategory: DomainStringMaterialCategory.coPoly,
            now: now,
          ),
          equals(100),
        );

        // Zero maxRatedHours -> does not crash or divide by zero
        expect(
          DecayEngine.calculateHealth(
            hoursPlayed: 5.0,
            maxRatedHours: 0.0,
            stringingDate: now,
            materialCategory: DomainStringMaterialCategory.coPoly,
            now: now,
          ),
          equals(0),
        );
      });
    });

    group('Tension Loss Formatting', () {
      test('should format tension loss text accurately', () {
        expect(
          DecayEngine.calculateTensionLossText(healthScore: 100),
          equals('~0.0 kg / ~0.0 lbs drop'),
        );
        expect(
          DecayEngine.calculateTensionLossText(healthScore: 50),
          equals('~2.9 kg / ~6.5 lbs drop'),
        );
        expect(
          DecayEngine.calculateTensionLossText(healthScore: 0),
          equals('~5.9 kg / ~13.0 lbs drop'),
        );
      });

      test('should clamp negative installed tension to 0 drop', () {
        expect(
          DecayEngine.calculateTensionLossText(
            healthScore: 50,
            installedTensionLbs: -52.0,
          ),
          equals('~0.0 kg / ~0.0 lbs drop'),
        );
      });
    });

    group('StringCategoryDefaults', () {
      test('should provide accurate shelf life for all categories', () {
        expect(
          StringCategoryDefaults.shelfLifeDays(
            DomainStringMaterialCategory.coPoly,
          ),
          equals(75),
        );
        expect(
          StringCategoryDefaults.shelfLifeDays(
            DomainStringMaterialCategory.multifilament,
          ),
          equals(180),
        );
        expect(
          StringCategoryDefaults.shelfLifeDays(
            DomainStringMaterialCategory.syntheticGut,
          ),
          equals(180),
        );
        expect(
          StringCategoryDefaults.shelfLifeDays(
            DomainStringMaterialCategory.naturalGut,
          ),
          equals(365),
        );
        expect(
          StringCategoryDefaults.shelfLifeDays(
            DomainStringMaterialCategory.kevlar,
          ),
          equals(120),
        );
        expect(
          StringCategoryDefaults.shelfLifeDays(
            DomainStringMaterialCategory.hybrid,
          ),
          equals(180),
        );
        expect(
          StringCategoryDefaults.shelfLifeDays(
            DomainStringMaterialCategory.other,
          ),
          equals(180),
        );
      });

      test('should provide accurate default max hours for all categories', () {
        expect(
          StringCategoryDefaults.maxHours(DomainStringMaterialCategory.coPoly),
          equals(20.0),
        );
        expect(
          StringCategoryDefaults.maxHours(
            DomainStringMaterialCategory.multifilament,
          ),
          equals(35.0),
        );
        expect(
          StringCategoryDefaults.maxHours(
            DomainStringMaterialCategory.syntheticGut,
          ),
          equals(30.0),
        );
        expect(
          StringCategoryDefaults.maxHours(
            DomainStringMaterialCategory.naturalGut,
          ),
          equals(50.0),
        );
        expect(
          StringCategoryDefaults.maxHours(DomainStringMaterialCategory.kevlar),
          equals(25.0),
        );
        expect(
          StringCategoryDefaults.maxHours(DomainStringMaterialCategory.hybrid),
          equals(25.0),
        );
        expect(
          StringCategoryDefaults.maxHours(DomainStringMaterialCategory.other),
          equals(20.0),
        );
      });

      test('should provide accurate display names for all categories', () {
        expect(
          StringCategoryDefaults.displayName(
            DomainStringMaterialCategory.coPoly,
          ),
          equals('Co-Polyester'),
        );
        expect(
          StringCategoryDefaults.displayName(
            DomainStringMaterialCategory.multifilament,
          ),
          equals('Multifilament'),
        );
        expect(
          StringCategoryDefaults.displayName(
            DomainStringMaterialCategory.syntheticGut,
          ),
          equals('Synthetic Gut'),
        );
        expect(
          StringCategoryDefaults.displayName(
            DomainStringMaterialCategory.naturalGut,
          ),
          equals('Natural Gut'),
        );
        expect(
          StringCategoryDefaults.displayName(
            DomainStringMaterialCategory.kevlar,
          ),
          equals('Kevlar'),
        );
        expect(
          StringCategoryDefaults.displayName(
            DomainStringMaterialCategory.hybrid,
          ),
          equals('Hybrid'),
        );
        expect(
          StringCategoryDefaults.displayName(
            DomainStringMaterialCategory.other,
          ),
          equals('Other'),
        );
      });

      test(
        'should polymorphically resolve foreign enums and fallback to other',
        () {
          expect(
            StringCategoryDefaults.shelfLifeDays(
              ForeignStringMaterialCategory.coPoly,
            ),
            equals(75),
          );
          expect(
            StringCategoryDefaults.maxHours(
              ForeignStringMaterialCategory.multifilament,
            ),
            equals(35.0),
          );
          expect(
            StringCategoryDefaults.displayName(
              ForeignStringMaterialCategory.naturalGut,
            ),
            equals('Natural Gut'),
          );

          // Unknown enum
          expect(
            StringCategoryDefaults.shelfLifeDays(
              ForeignStringMaterialCategory.exoticFutureMaterial,
            ),
            equals(180),
          );
          expect(
            StringCategoryDefaults.maxHours(
              ForeignStringMaterialCategory.exoticFutureMaterial,
            ),
            equals(20.0),
          );
          expect(
            StringCategoryDefaults.displayName(
              ForeignStringMaterialCategory.exoticFutureMaterial,
            ),
            equals('Other'),
          );
        },
      );
    });
  });
}
