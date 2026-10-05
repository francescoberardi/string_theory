import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Extended FAB opening the manual session logger.
class LogSessionFab extends StatelessWidget {
  final VoidCallback onPressed;

  const LogSessionFab({super.key, required this.onPressed});

  static const keyLogSessionFab = Key('virtual_bag_fab_log_session');

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      key: keyLogSessionFab,
      heroTag: 'virtual_bag_fab_log_session_hero',
      backgroundColor: CourtMidnightTheme.surface,
      foregroundColor: CourtMidnightTheme.primaryVolt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: CourtMidnightTheme.primaryVolt,
          width: 1.5,
        ),
      ),
      onPressed: onPressed,
      icon: const Icon(
        Icons.timer_outlined,
        color: CourtMidnightTheme.primaryVolt,
      ),
      label: Text(
        '+ Log Session',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: CourtMidnightTheme.primaryVolt,
        ),
      ),
    );
  }
}
