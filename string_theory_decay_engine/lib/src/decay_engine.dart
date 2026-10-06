import 'health_tier.dart';
import 'string_category_defaults.dart';

/// Pure Dart domain engine for calculating tennis string elasticity decay,
/// composite health scores, health tiers, and tension loss estimates.
///
/// Shared calculation logic between Serverpod backend and Flutter client.
class DecayEngine {
  /// Default shelf life in days per string material category.
  static int getShelfLifeDays(Enum category) =>
      StringCategoryDefaults.shelfLifeDays(category);

  /// Resolves the [HealthTier] for a given [healthScore].
  static HealthTier getHealthTier(int healthScore) =>
      HealthTier.fromScore(healthScore);

  /// Resolves the [HealthTier] for a nullable [score], returning `null` if [score] is null.
  static HealthTier? getHealthTierOrNull(int? score) =>
      score != null ? HealthTier.fromScore(score) : null;

  /// Calculates composite health score (0-100%) based on:
  /// - 70% dynamic court play hours penalty: (hoursPlayed / maxRatedHours) * 70
  /// - 30% static calendar shelf-life penalty: (daysElapsed / shelfLife) * 30
  ///
  /// Supports polymorphic [Enum] inputs for [materialCategory].
  static int calculateHealth({
    required double hoursPlayed,
    required double maxRatedHours,
    required DateTime stringingDate,
    required Enum materialCategory,
    DateTime? now,
  }) {
    final double effectiveHours;
    if (hoursPlayed.isNaN || hoursPlayed <= 0.0) {
      effectiveHours = 0.0;
    } else {
      effectiveHours = hoursPlayed;
    }

    final double effectiveMaxHours;
    if (maxRatedHours.isNaN || maxRatedHours <= 0.0) {
      effectiveMaxHours = 1.0;
    } else {
      effectiveMaxHours = maxRatedHours;
    }

    final dynamicPenalty = (effectiveHours / effectiveMaxHours) * 70.0;

    final currentTime = now ?? DateTime.now();
    final diffMs = currentTime.difference(stringingDate).inMilliseconds;
    final daysElapsed = diffMs <= 0
        ? 0.0
        : diffMs / Duration.millisecondsPerDay;
    final shelfLife = getShelfLifeDays(materialCategory).toDouble();
    final calendarPenalty = (daysElapsed / shelfLife) * 30.0;

    final totalPenalty = dynamicPenalty + calendarPenalty;
    if (!totalPenalty.isFinite || totalPenalty >= 100.0) {
      return 0;
    }
    if (totalPenalty <= 0.0) {
      return 100;
    }

    final rawHealth = 100.0 - totalPenalty;
    return rawHealth.round().clamp(0, 100);
  }

  /// Calculates secondary tension loss text (e.g. "~1.5 kg / ~3.3 lbs drop")
  /// based on health score degradation.
  static String calculateTensionLossText({
    required int healthScore,
    double installedTensionLbs = 52.0,
  }) {
    final clampedScore = healthScore.clamp(0, 100);
    if (clampedScore == 100) {
      return '~0.0 kg / ~0.0 lbs drop';
    }

    final healthDropFraction = (100 - clampedScore) / 100.0;
    final effectiveTension =
        !installedTensionLbs.isFinite || installedTensionLbs <= 0
        ? 0.0
        : installedTensionLbs;
    // Maximum expected elasticity tension loss when strings are fully dead (0% health)
    // is approximately 25% of installed tension.
    final lbsDrop = effectiveTension * 0.25 * healthDropFraction;
    final kgDrop = lbsDrop * 0.45359237;

    return '~${kgDrop.toStringAsFixed(1)} kg / ~${lbsDrop.toStringAsFixed(1)} lbs drop';
  }
}
