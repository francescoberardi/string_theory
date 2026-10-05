import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Full-width confirm button pinned at the bottom of the sheet. Disabled when
/// [onPressed] is null; shows a spinner while [isSubmitting].
class ConfirmButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isSubmitting;

  const ConfirmButton({
    super.key,
    required this.onPressed,
    required this.isSubmitting,
  });

  static const keyConfirmButton = Key('workout_assignment_confirm_button');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          key: keyConfirmButton,
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: CourtMidnightTheme.primaryVolt,
            foregroundColor: Colors.black,
            disabledBackgroundColor: CourtMidnightTheme.surfaceBorder,
            disabledForegroundColor: CourtMidnightTheme.textSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : Text(
                  'Confirm',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
