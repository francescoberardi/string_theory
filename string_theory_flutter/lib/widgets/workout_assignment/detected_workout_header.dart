import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/workout_formatting.dart';
import '../../services/health/health_sync_service.dart';
import '../../theme/court_midnight_theme.dart';

/// Title, duration pill, start time and source line for a detected workout.
class DetectedWorkoutHeader extends StatelessWidget {
  final DetectedWorkout workout;

  const DetectedWorkoutHeader({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ASSIGN WORKOUT',
              style: GoogleFonts.barlowCondensed(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: CourtMidnightTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CourtMidnightTheme.primaryVolt.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CourtMidnightTheme.primaryVolt,
                  width: 1.5,
                ),
              ),
              child: Text(
                formatWorkoutDuration(workout.durationMinutes),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CourtMidnightTheme.primaryVolt,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formatWorkoutStartTime(workout.startTime),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CourtMidnightTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Tennis workout detected via ${workout.source}. Attribute court time to a racquet.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: CourtMidnightTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
