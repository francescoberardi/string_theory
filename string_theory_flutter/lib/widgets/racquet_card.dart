import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/domain/decay_engine.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/radial_health_gauge.dart';
import 'package:string_theory_flutter/widgets/restring_sheet.dart';

/// Athletic racquet card displaying stringbed health, specs, and status badges.
///
/// Integrates [RadialHealthGauge] and displays cautionary badge
/// "Dead Stringbed — High Shock Risk" when health drops below 40%.
/// Supports desktop mouse hover states with border glow and elevation.
class RacquetCard extends StatefulWidget {
  final Racquet racquet;
  final BagBloc bloc;
  final VoidCallback? onTap;

  const RacquetCard({
    super.key,
    required this.racquet,
    required this.bloc,
    this.onTap,
  });

  /// Key of the `[Restrung Today]` button on the card of racquet [racquetId].
  static Key restrungTodayKey(int racquetId) =>
      Key('racquet_restrung_today_$racquetId');

  @override
  State<RacquetCard> createState() => _RacquetCardState();
}

class _RacquetCardState extends State<RacquetCard> {
  bool _isHovered = false;

  /// `[Restrung Today]` CTA: filled and prominent on a dead stringbed,
  /// outlined otherwise (UX-DR5).
  Widget _buildRestrungButton(
    BuildContext context, {
    required bool isCritical,
  }) {
    void open() => RestringSheet.show(
      context,
      racquet: widget.racquet,
      bagBloc: widget.bloc,
    );
    const icon = Icon(Icons.restart_alt, size: 16);
    final label = Text(
      'Restrung Today',
      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
    );
    const padding = EdgeInsets.symmetric(horizontal: 12);
    const minimumSize = Size(0, 32);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    final key = RacquetCard.restrungTodayKey(widget.racquet.id!);

    return Align(
      alignment: Alignment.centerLeft,
      child: isCritical
          ? ElevatedButton.icon(
              key: key,
              onPressed: open,
              icon: icon,
              label: label,
              style: ElevatedButton.styleFrom(
                backgroundColor: CourtMidnightTheme.healthCritical,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: padding,
                minimumSize: minimumSize,
                shape: shape,
              ),
            )
          : OutlinedButton.icon(
              key: key,
              onPressed: open,
              icon: icon,
              label: label,
              style: OutlinedButton.styleFrom(
                foregroundColor: CourtMidnightTheme.primaryVolt,
                side: const BorderSide(color: CourtMidnightTheme.primaryMuted),
                padding: padding,
                minimumSize: minimumSize,
                shape: shape,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final racquet = widget.racquet;
    final bloc = widget.bloc;
    final onTap = widget.onTap;
    final job = racquet.activeStringJob;
    final hasJob = job != null;
    final health = hasJob ? job.currentHealthScore : null;

    final isCritical = health != null && health < 40;
    final cardBg = isCritical
        ? CourtMidnightTheme.healthCriticalBg
        : (_isHovered
              ? CourtMidnightTheme.surfaceElevated
              : CourtMidnightTheme.surface);

    final cardBorder = isCritical
        ? Border.all(
            color: _isHovered
                ? CourtMidnightTheme.healthCritical
                : CourtMidnightTheme.healthCritical.withValues(alpha: 0.8),
            width: _isHovered ? 2.0 : 1.5,
          )
        : Border.all(
            color: _isHovered
                ? CourtMidnightTheme.primaryVolt.withValues(alpha: 0.6)
                : CourtMidnightTheme.surfaceBorder,
            width: _isHovered ? 1.5 : 1.0,
          );

    final cardShadow = _isHovered
        ? [
            BoxShadow(
              color: isCritical
                  ? CourtMidnightTheme.healthCritical.withValues(alpha: 0.2)
                  : CourtMidnightTheme.primaryVolt.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ]
        : const <BoxShadow>[];

    final stringParts = <String>[];
    if (job != null) {
      final nameParts = [
        if (job.brand != null && job.brand!.trim().isNotEmpty)
          job.brand!.trim(),
        if (job.model != null && job.model!.trim().isNotEmpty)
          job.model!.trim(),
      ].join(' ');
      if (nameParts.isNotEmpty) stringParts.add(nameParts);
      if (job.installedTension != null) {
        stringParts.add('${job.installedTension!.toStringAsFixed(0)} lbs');
      }
    }
    final stringSpecs = stringParts.isNotEmpty
        ? stringParts.join(' • ')
        : 'No string mounted';

    final tensionLossText = (hasJob && health != null)
        ? DecayEngine.calculateTensionLossText(
            healthScore: health,
            installedTensionLbs: job.installedTension ?? 52.0,
          )
        : null;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: onTap,
        onHover: (hovered) {
          if (_isHovered != hovered) {
            setState(() => _isHovered = hovered);
          }
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: cardBorder,
            boxShadow: cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Standalone Animated Radial Health Gauge
              RadialHealthGauge(
                healthScore: health,
                size: 54,
                animate: true,
              ),
              const SizedBox(width: 14),

              // Center: Racquet specs & strings
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            racquet.name,
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: CourtMidnightTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (racquet.isPrimary) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CourtMidnightTheme.primaryVolt,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PRIMARY',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      stringSpecs,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: hasJob
                            ? CourtMidnightTheme.textSecondary
                            : CourtMidnightTheme.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (job != null)
                      Text(
                        '${job.materialCategory.displayName} • ${job.totalCourtHours.toStringAsFixed(1)}h / ${job.maxRatedHours.toStringAsFixed(0)}h max'
                        '${tensionLossText != null ? ' • $tensionLossText' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: CourtMidnightTheme.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (isCritical) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CourtMidnightTheme.healthCritical.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: CourtMidnightTheme.healthCritical.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 12,
                              color: CourtMidnightTheme.healthCritical,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Dead Stringbed — High Shock Risk',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: CourtMidnightTheme.healthCritical,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (job != null && racquet.id != null) ...[
                      const SizedBox(height: 6),
                      _buildRestrungButton(context, isCritical: isCritical),
                    ],
                  ],
                ),
              ),

              // Right: Quick context menu
              if (racquet.id != null)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: CourtMidnightTheme.textTertiary,
                    size: 20,
                  ),
                  color: CourtMidnightTheme.surfaceElevated,
                  onSelected: (value) async {
                    if (value == 'fast_forward' && racquet.id != null) {
                      bloc.add(FastForwardRacquetAge(racquet.id!, days: 30));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Aged "${racquet.name}" by 30 days',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: CourtMidnightTheme.primaryVolt,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else if (value == 'primary' && racquet.id != null) {
                      bloc.add(SetPrimaryRacquet(racquet.id!));
                    } else if (value == 'delete' && racquet.id != null) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: CourtMidnightTheme.surfaceElevated,
                          title: Text(
                            'Delete Racquet',
                            style: GoogleFonts.barlowCondensed(
                              color: CourtMidnightTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to remove "${racquet.name}" from your bag? This cannot be undone.',
                            style: GoogleFonts.inter(
                              color: CourtMidnightTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: CourtMidnightTheme.textTertiary,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: CourtMidnightTheme.healthCritical,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && racquet.id != null) {
                        bloc.add(DeleteRacquet(racquet.id!));
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    if (racquet.activeStringJob != null && racquet.id != null)
                      const PopupMenuItem(
                        value: 'fast_forward',
                        child: Row(
                          children: [
                            Icon(
                              Icons.fast_forward,
                              size: 16,
                              color: CourtMidnightTheme.primaryVolt,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fast-Forward 30 Days',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!racquet.isPrimary && racquet.id != null)
                      const PopupMenuItem(
                        value: 'primary',
                        child: Text('Set as Primary'),
                      ),
                    if (racquet.id != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete Racquet',
                          style: TextStyle(
                            color: CourtMidnightTheme.healthCritical,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
