import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Placeholder for the Sessions tab until session history ships.
class SessionsPlaceholder extends StatelessWidget {
  const SessionsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CourtMidnightTheme.primaryVolt.withValues(alpha: 0.12),
                border: Border.all(
                  color: CourtMidnightTheme.primaryVolt.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.sports_tennis,
                size: 38,
                color: CourtMidnightTheme.primaryVolt,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'COURT SESSIONS',
              style: GoogleFonts.barlowCondensed(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: CourtMidnightTheme.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Session logging & Apple Health sync coming soon in Epic 2.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: CourtMidnightTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
