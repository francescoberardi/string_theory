/// Represents the health status tier of a tennis stringbed.
///
/// Tiers are classified into 3 ranges:
/// - [optimal]: Health score >= 70% (Green)
/// - [degraded]: Health score 40% - 69% (Amber)
/// - [critical]: Health score < 40% (Red, high shock risk)
enum HealthTier {
  optimal,
  degraded,
  critical;

  /// Threshold for optimal health tier (inclusive).
  static const int optimalThreshold = 70;

  /// Threshold for degraded health tier (inclusive).
  static const int degradedThreshold = 40;

  /// Classifies a [healthScore] (clamped to 0..100) into a [HealthTier].
  static HealthTier fromScore(int healthScore) {
    final clamped = healthScore.clamp(0, 100);
    if (clamped >= optimalThreshold) {
      return HealthTier.optimal;
    } else if (clamped >= degradedThreshold) {
      return HealthTier.degraded;
    } else {
      return HealthTier.critical;
    }
  }

  /// Whether the stringbed is in optimal condition.
  bool get isOptimal => this == HealthTier.optimal;

  /// Whether the stringbed is in degraded condition.
  bool get isDegraded => this == HealthTier.degraded;

  /// Whether the stringbed is in critical condition (high shock risk).
  bool get isCritical => this == HealthTier.critical;

  /// Human-readable semantic description for accessibility and status messages.
  String get description {
    switch (this) {
      case HealthTier.optimal:
        return 'Optimal condition';
      case HealthTier.degraded:
        return 'Degraded condition';
      case HealthTier.critical:
        return 'Critical condition, high shock risk';
    }
  }
}
