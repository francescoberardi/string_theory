import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Accordion header revealing the advanced options panel.
class AdvancedOptionsToggle extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const AdvancedOptionsToggle({
    super.key,
    required this.isExpanded,
    required this.onToggle,
  });

  static const keyAdvancedToggle = Key('workout_assignment_advanced_toggle');

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: InkWell(
          key: keyAdvancedToggle,
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isExpanded
                      ? Icons.remove_circle_outline
                      : Icons.add_circle_outline,
                  size: 18,
                  color: CourtMidnightTheme.primaryVolt,
                ),
                const SizedBox(width: 8),
                Text(
                  isExpanded ? '- Fewer Options' : '+ Advanced Options',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CourtMidnightTheme.primaryVolt,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
