import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';
import 'court_surface_selector.dart';

/// Collapsible court surface and session notes inputs.
class AdvancedOptionsPanel extends StatelessWidget {
  final bool isExpanded;
  final String? selectedSurface;
  final ValueChanged<String?> onSurfaceChanged;
  final TextEditingController notesController;

  const AdvancedOptionsPanel({
    super.key,
    required this.isExpanded,
    required this.selectedSurface,
    required this.onSurfaceChanged,
    required this.notesController,
  });

  static const keyNotesField = Key('workout_assignment_notes_field');

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: isExpanded
          ? Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'COURT SURFACE',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: CourtMidnightTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CourtSurfaceSelector(
                    selectedSurface: selectedSurface,
                    onChanged: onSurfaceChanged,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SESSION NOTES',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: CourtMidnightTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: keyNotesField,
                    controller: notesController,
                    maxLines: 2,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: CourtMidnightTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Heavy baseline rallies, match tiebreak...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: CourtMidnightTheme.textSecondary.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      filled: true,
                      fillColor: CourtMidnightTheme.background,
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: CourtMidnightTheme.surfaceBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: CourtMidnightTheme.surfaceBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: CourtMidnightTheme.primaryVolt,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
