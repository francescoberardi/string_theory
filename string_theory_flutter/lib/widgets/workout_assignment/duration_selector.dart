import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Row of preset duration chips for the manual quick logger.
class DurationSelector extends StatelessWidget {
  final int selectedMinutes;
  final ValueChanged<int> onSelected;

  const DurationSelector({
    super.key,
    required this.selectedMinutes,
    required this.onSelected,
  });

  static Key keyDurationChip(String duration) =>
      Key('workout_assignment_duration_$duration');

  static const _durationPresets = [
    ('30m', 30),
    ('1h', 60),
    ('1.5h', 90),
    ('2h', 120),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _durationPresets.map((preset) {
        final (label, minutes) = preset;
        final isSelected = selectedMinutes == minutes;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Semantics(
              button: true,
              selected: isSelected,
              child: InkWell(
                key: keyDurationChip(label),
                onTap: () => onSelected(minutes),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? CourtMidnightTheme.primaryVolt.withValues(
                            alpha: 0.15,
                          )
                        : CourtMidnightTheme.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? CourtMidnightTheme.primaryVolt
                          : CourtMidnightTheme.surfaceBorder,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
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
