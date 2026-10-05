import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';
import '../../theme/court_midnight_theme.dart';
import '../radial_health_gauge.dart';

const List<String> _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats start and end dates as e.g. "Aug 10 – Oct 2", including years when they span different years.
String formatTimelineDateRange(DateTime start, DateTime end) {
  if (start.year != end.year) {
    final startStr =
        '${_shortMonths[start.month - 1]} ${start.day}, ${start.year}';
    final endStr = '${_shortMonths[end.month - 1]} ${end.day}, ${end.year}';
    return '$startStr – $endStr';
  }
  final startStr = '${_shortMonths[start.month - 1]} ${start.day}';
  final endStr = '${_shortMonths[end.month - 1]} ${end.day}';
  return '$startStr – $endStr';
}

/// A single node in the Restring History timeline displaying past stringbed performance.
class RestringTimelineTile extends StatelessWidget {
  final RestringEvent event;
  final bool isFirst;
  final bool isLast;

  const RestringTimelineTile({
    super.key,
    required this.event,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final healthColor = RadialHealthGauge.getStatusColor(
      event.finalHealthScore,
    );
    final tensionText = event.installedTension != null
        ? '${event.installedTension!.toStringAsFixed(1)} lbs'
        : '—';
    final dateRange = formatTimelineDateRange(
      event.stringingDate,
      event.restringDate,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator (connector line and bullet)
          SizedBox(
            width: 28,
            child: Column(
              children: [
                // Line above bullet
                Container(
                  width: 2,
                  height: 16,
                  color: isFirst
                      ? Colors.transparent
                      : CourtMidnightTheme.surfaceBorder,
                ),
                // Bullet
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: healthColor,
                    boxShadow: [
                      BoxShadow(
                        color: healthColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                // Line below bullet
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : CourtMidnightTheme.surfaceBorder,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CourtMidnightTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: CourtMidnightTheme.surfaceBorder,
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: Date range + Health score badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          dateRange,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: CourtMidnightTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: healthColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: healthColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '${event.finalHealthScore}%',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: healthColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // String description
                  Text(
                    event.stringDescription,
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CourtMidnightTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Bottom metrics chips/stats
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatChip(
                        icon: Icons.sports_tennis,
                        label:
                            '${event.finalCourtHours.toStringAsFixed(1)} court hours',
                      ),
                      _StatChip(
                        icon: Icons.calendar_today_outlined,
                        label: '${event.finalDaysActive} days active',
                      ),
                      _StatChip(
                        icon: Icons.speed,
                        label: tensionText,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: CourtMidnightTheme.textTertiary,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: CourtMidnightTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
