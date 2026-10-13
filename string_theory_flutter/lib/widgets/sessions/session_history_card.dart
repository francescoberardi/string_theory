import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../../domain/workout_formatting.dart';
import '../../theme/court_midnight_theme.dart';

/// Card widget rendering an individual session log entry in the sessions history.
class SessionHistoryCard extends StatelessWidget {
  final SessionLog session;
  final String racquetName;

  const SessionHistoryCard({
    super.key,
    required this.session,
    required this.racquetName,
  });

  @override
  Widget build(BuildContext context) {
    final hours = session.durationMinutes / 60.0;
    final hoursText = hours >= 0
        ? '+${hours.toStringAsFixed(1)} hrs'
        : '${hours.toStringAsFixed(1)} hrs';
    final durationText = '${session.durationMinutes} min';
    final dateText = formatWorkoutStartTime(session.startTime);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: CourtMidnightTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CourtMidnightTheme.surfaceBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        racquetName,
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: CourtMidnightTheme.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateText,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CourtMidnightTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Court hours added badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: CourtMidnightTheme.primaryVolt.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: CourtMidnightTheme.primaryVolt.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                  child: Text(
                    hoursText,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: CourtMidnightTheme.primaryVolt,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(
              height: 1,
              thickness: 1,
              color: CourtMidnightTheme.surfaceBorder,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 15,
                      color: CourtMidnightTheme.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      durationText,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: CourtMidnightTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (session.courtSurface != null &&
                    session.courtSurface!.trim().isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sports_tennis,
                        size: 14,
                        color: CourtMidnightTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _capitalize(session.courtSurface!.trim()),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: CourtMidnightTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                if (session.source.isNotEmpty)
                  _buildSourceBadge(session.source),
              ],
            ),
            if (session.notes != null && session.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                session.notes!.trim(),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: CourtMidnightTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge(String source) {
    final (IconData icon, String label) = switch (source.toLowerCase()) {
      'apple_health' || 'healthkit' => (Icons.favorite, 'Apple Health'),
      'health_connect' => (Icons.favorite, 'Health Connect'),
      'simulation' || 'simulated' => (Icons.smart_toy_outlined, 'Simulated'),
      _ => (Icons.edit_note, 'Manual'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: CourtMidnightTheme.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: CourtMidnightTheme.textTertiary,
          ),
        ),
      ],
    );
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
