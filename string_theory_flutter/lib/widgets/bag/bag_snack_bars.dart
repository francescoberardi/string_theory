import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// SnackBar announcing detected workouts, with an Assign action.
SnackBar buildDetectionSnackBar({
  required String message,
  required VoidCallback onAssign,
}) {
  return SnackBar(
    backgroundColor: CourtMidnightTheme.surface,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 4),
    persist: false,
    action: SnackBarAction(
      label: 'Assign',
      textColor: CourtMidnightTheme.primaryVolt,
      onPressed: onAssign,
    ),
    content: Row(
      children: [
        const Icon(
          Icons.sports_tennis,
          color: CourtMidnightTheme.primaryVolt,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.inter(
              color: CourtMidnightTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// SnackBar relaying a bloc info message; the icon shows offline vs synced.
SnackBar buildInfoSnackBar({
  required String message,
  required bool hasPendingSync,
}) {
  return SnackBar(
    backgroundColor: CourtMidnightTheme.surface,
    behavior: SnackBarBehavior.floating,
    content: Row(
      children: [
        Icon(
          hasPendingSync ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
          color: CourtMidnightTheme.primaryVolt,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.inter(
              color: CourtMidnightTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Celebratory green SnackBar relaying a bloc success message.
SnackBar buildSuccessSnackBar(String message) {
  return SnackBar(
    backgroundColor: CourtMidnightTheme.healthOptimal,
    behavior: SnackBarBehavior.floating,
    content: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: Colors.black, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

/// SnackBar relaying a bloc error message.
SnackBar buildErrorSnackBar(String message) {
  return SnackBar(
    backgroundColor: CourtMidnightTheme.healthCritical,
    behavior: SnackBarBehavior.floating,
    content: Text(
      message,
      style: GoogleFonts.inter(color: Colors.white),
    ),
  );
}
