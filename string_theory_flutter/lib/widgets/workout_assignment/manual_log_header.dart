import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Title and instructions for the manual quick logger.
class ManualLogHeader extends StatelessWidget {
  const ManualLogHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'LOG COURT SESSION',
          style: GoogleFonts.barlowCondensed(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: CourtMidnightTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select duration and attribute court time to your active stringbed.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: CourtMidnightTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
