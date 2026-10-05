import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Indicator shown while sessions logged offline wait to reach the server.
class PendingSyncBanner extends StatelessWidget {
  final int count;
  final bool isMobile;

  const PendingSyncBanner({
    super.key,
    required this.count,
    required this.isMobile,
  });

  static const keyPendingSyncBanner = Key('virtual_bag_pending_sync_banner');

  @override
  Widget build(BuildContext context) {
    final sessions = count == 1 ? '1 session' : '$count sessions';
    final horizontal = isMobile ? 16.0 : 24.0;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '$sessions saved offline, waiting to sync',
      child: ExcludeSemantics(
        child: Container(
          key: keyPendingSyncBanner,
          margin: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: CourtMidnightTheme.healthDegraded.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: CourtMidnightTheme.healthDegraded.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: CourtMidnightTheme.healthDegraded,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$sessions waiting to sync',
                  style: GoogleFonts.inter(
                    color: CourtMidnightTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'OFFLINE',
                style: GoogleFonts.barlowCondensed(
                  color: CourtMidnightTheme.healthDegraded,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
