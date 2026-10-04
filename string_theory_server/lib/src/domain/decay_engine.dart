import 'package:string_theory_server/src/generated/protocol.dart';

/// Pure Dart domain engine for calculating tennis string elasticity decay,
/// composite health scores, and tension loss estimates.
///
/// Shared calculation logic between Serverpod backend and Flutter client.
class DecayEngine {
  /// Default shelf life in days per string material category.
  static int getShelfLifeDays(StringMaterialCategory category) {
    switch (category) {
      case StringMaterialCategory.coPoly:
        return 75;
      case StringMaterialCategory.multifilament:
      case StringMaterialCategory.syntheticGut:
        return 180;
      case StringMaterialCategory.naturalGut:
        return 365;
      case StringMaterialCategory.kevlar:
        return 120;
      case StringMaterialCategory.hybrid:
      case StringMaterialCategory.other:
        return 180;
    }
  }

  /// Calculates composite health score (0-100%) based on:
  /// - 70% dynamic court play hours penalty: (hoursPlayed / maxRatedHours) * 70
  /// - 30% static calendar shelf-life penalty: (daysElapsed / shelfLife) * 30
  static int calculateHealth({
    required double hoursPlayed,
    required double maxRatedHours,
    required DateTime stringingDate,
    required StringMaterialCategory materialCategory,
    DateTime? now,
  }) {
    final effectiveHours = hoursPlayed <= 0 ? 0.0 : hoursPlayed;
    final effectiveMaxHours = maxRatedHours <= 0 ? 1.0 : maxRatedHours;
    final dynamicPenalty = (effectiveHours / effectiveMaxHours) * 70.0;

    final currentTime = now ?? DateTime.now();
    final diffMs = currentTime.difference(stringingDate).inMilliseconds;
    final daysElapsed = diffMs <= 0
        ? 0.0
        : diffMs / Duration.millisecondsPerDay;
    final shelfLife = getShelfLifeDays(materialCategory).toDouble();
    final calendarPenalty = (daysElapsed / shelfLife) * 30.0;

    final totalPenalty = dynamicPenalty + calendarPenalty;
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
    // Maximum expected elasticity tension loss when strings are fully dead (0% health)
    // is approximately 25% of installed tension.
    final lbsDrop = installedTensionLbs * 0.25 * healthDropFraction;
    final kgDrop = lbsDrop * 0.45359237;

    return '~${kgDrop.toStringAsFixed(1)} kg / ~${lbsDrop.toStringAsFixed(1)} lbs drop';
  }
}
