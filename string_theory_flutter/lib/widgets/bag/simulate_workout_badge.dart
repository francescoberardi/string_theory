import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Dev-only chip that injects a simulated workout detection.
class SimulateWorkoutBadge extends StatelessWidget {
  final VoidCallback onTap;

  const SimulateWorkoutBadge({super.key, required this.onTap});

  static const keySimulateWorkoutBadge = Key(
    'virtual_bag_simulate_workout_badge',
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CourtMidnightTheme.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: CourtMidnightTheme.primaryVolt.withValues(alpha: 0.6),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: keySimulateWorkoutBadge,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            '🧪 Simulate Workout',
            style: GoogleFonts.barlowCondensed(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: CourtMidnightTheme.primaryVolt,
            ),
          ),
        ),
      ),
    );
  }
}
