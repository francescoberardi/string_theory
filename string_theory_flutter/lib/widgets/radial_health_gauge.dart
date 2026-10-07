import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_flutter/domain/decay_engine.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';

/// Standalone circular radial health gauge widget displaying real-time
/// tennis stringbed elasticity and tension decay.
///
/// Features smooth 60fps animations and 3-tier glowing status colors,
/// classified by [HealthTier]:
/// - [HealthTier.optimal]: >= [HealthTier.optimalThreshold] (#10B981)
/// - [HealthTier.degraded]: >= [HealthTier.degradedThreshold] (#F59E0B)
/// - [HealthTier.critical]: below [HealthTier.degradedThreshold] (#EF4444)
///
/// Displays Barlow Condensed bold percentage in the center and secondary
/// tension loss or health helper text below.
class RadialHealthGauge extends StatelessWidget {
  final int? healthScore;
  final String? tensionLossText;
  final double size;
  final bool animate;
  final Duration animationDuration;

  const RadialHealthGauge({
    super.key,
    required this.healthScore,
    this.tensionLossText,
    this.size = 64.0,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 750),
  });

  /// Computes tier status color based on health score.
  static Color getStatusColor(int? health) {
    if (health == null) {
      return CourtMidnightTheme.textTertiary;
    }
    final tier = DecayEngine.getHealthTier(health);
    switch (tier) {
      case HealthTier.optimal:
        return CourtMidnightTheme.healthOptimal;
      case HealthTier.degraded:
        return CourtMidnightTheme.healthDegraded;
      case HealthTier.critical:
        return CourtMidnightTheme.healthCritical;
    }
  }

  @override
  Widget build(BuildContext context) {
    final health = healthScore;
    final healthColor = getStatusColor(health);
    final targetProgress = health != null
        ? (health.clamp(0, 100)) / 100.0
        : 0.0;
    final displayValue = health != null ? '$health%' : '--';

    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final effectiveDuration = (animate && !reducedMotion)
        ? animationDuration
        : Duration.zero;

    final semanticsLabel = health != null
        ? 'Stringbed health: $health percent. ${DecayEngine.getHealthTier(health).description}.${tensionLossText != null ? " Tension loss: $tensionLossText." : ""}'
        : 'Unstrung racquet';

    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft ambient glow aura
            if (health != null)
              Container(
                width: size * 0.88,
                height: size * 0.88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: healthColor.withValues(alpha: 0.32),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

            // 60fps animated radial progress ring
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: (animate && !reducedMotion) ? 0.0 : targetProgress,
                end: targetProgress,
              ),
              duration: effectiveDuration,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: (size * 0.09).clamp(3.5, 7.0),
                    backgroundColor: CourtMidnightTheme.surfaceBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                  ),
                );
              },
            ),

            // Center: bold percentage and helper text
            Padding(
              padding: EdgeInsets.all((size * 0.12).clamp(4.0, 8.0)),
              child: Center(
                child: SizedBox(
                  width: (size * 0.76).clamp(24.0, 300.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayValue,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: (size * 0.30).clamp(13.0, 22.0),
                            fontWeight: FontWeight.w800,
                            color: health != null
                                ? CourtMidnightTheme.textPrimary
                                : CourtMidnightTheme.textTertiary,
                            height: 1.0,
                          ),
                        ),
                        if (tensionLossText != null &&
                            tensionLossText!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            tensionLossText!,
                            style: GoogleFonts.inter(
                              fontSize: (size * 0.13).clamp(8.0, 11.0),
                              fontWeight: FontWeight.w500,
                              color: CourtMidnightTheme.textSecondary,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else ...[
                          const SizedBox(height: 1),
                          Text(
                            health != null ? 'HEALTH' : 'UNSTRUNG',
                            style: GoogleFonts.barlowCondensed(
                              fontSize: (size * 0.16).clamp(7.0, 10.0),
                              fontWeight: FontWeight.bold,
                              color: healthColor,
                              letterSpacing: 0.5,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
