import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Row of court surface chips; tapping the selected chip clears it.
class CourtSurfaceSelector extends StatelessWidget {
  final String? selectedSurface;
  final ValueChanged<String?> onChanged;

  const CourtSurfaceSelector({
    super.key,
    required this.selectedSurface,
    required this.onChanged,
  });

  static Key keySurfaceChip(String surface) =>
      Key('workout_assignment_surface_${surface.toLowerCase()}');

  static const _surfaces = ['Hard', 'Clay', 'Grass', 'Carpet'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _surfaces.map((surface) {
        final isSelected = selectedSurface == surface;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              button: true,
              selected: isSelected,
              child: InkWell(
                key: keySurfaceChip(surface),
                onTap: () => onChanged(isSelected ? null : surface),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CourtMidnightTheme.primaryVolt.withValues(
                            alpha: 0.15,
                          )
                        : CourtMidnightTheme.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? CourtMidnightTheme.primaryVolt
                          : CourtMidnightTheme.surfaceBorder,
                    ),
                  ),
                  child: Text(
                    surface,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? CourtMidnightTheme.primaryVolt
                          : CourtMidnightTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
