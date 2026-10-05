import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../../theme/court_midnight_theme.dart';

/// "Select racquet" heading and horizontal carousel; unstrung racquets are
/// shown but cannot be selected.
class RacquetSelector extends StatelessWidget {
  final List<Racquet> racquets;
  final int? selectedRacquetId;
  final ValueChanged<int?> onSelected;

  const RacquetSelector({
    super.key,
    required this.racquets,
    required this.selectedRacquetId,
    required this.onSelected,
  });

  static Key keyRacquetTile(int id) => Key('workout_assignment_racquet_$id');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SELECT RACQUET',
          style: GoogleFonts.barlowCondensed(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
            color: CourtMidnightTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: racquets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final racquet = racquets[index];
              final isStrung = racquet.activeStringJob != null;
              return _RacquetTile(
                tileKey: keyRacquetTile(racquet.id ?? index),
                racquet: racquet,
                isStrung: isStrung,
                isSelected: isStrung && racquet.id == selectedRacquetId,
                onTap: isStrung ? () => onSelected(racquet.id) : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RacquetTile extends StatelessWidget {
  final Key tileKey;
  final Racquet racquet;
  final bool isStrung;
  final bool isSelected;
  final VoidCallback? onTap;

  const _RacquetTile({
    required this.tileKey,
    required this.racquet,
    required this.isStrung,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stringModel = racquet.activeStringJob?.model ?? 'Unstrung';

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: isStrung,
      child: InkWell(
        key: tileKey,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: isStrung ? 1.0 : 0.45,
          child: Container(
            width: 160,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? CourtMidnightTheme.primaryVolt.withValues(alpha: 0.10)
                  : CourtMidnightTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? CourtMidnightTheme.primaryVolt
                    : CourtMidnightTheme.surfaceBorder,
                width: isSelected ? 2.0 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        racquet.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: CourtMidnightTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isStrung)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CourtMidnightTheme.healthCritical.withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'UNSTRUNG',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: CourtMidnightTheme.healthCritical,
                          ),
                        ),
                      )
                    else if (racquet.isPrimary)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CourtMidnightTheme.primaryVolt,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PRI',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  stringModel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: CourtMidnightTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
