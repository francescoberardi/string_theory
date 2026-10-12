import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Informational banner shown when Apple Health or Health Connect permissions
/// are missing or denied (Story 6.2, AC-4).
class HealthPermissionGuidance extends StatelessWidget {
  final bool isMobile;
  final VoidCallback? onRequestPermission;

  const HealthPermissionGuidance({
    super.key,
    required this.isMobile,
    this.onRequestPermission,
  });

  static const keyHealthPermissionGuidance = Key('health_permission_guidance');

  @override
  Widget build(BuildContext context) {
    final horizontal = isMobile ? 16.0 : 24.0;
    return Semantics(
      container: true,
      label:
          'Health permissions required. Grant access to sync tennis workouts automatically.',
      child: Container(
        key: keyHealthPermissionGuidance,
        margin: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: CourtMidnightTheme.healthCritical.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CourtMidnightTheme.healthCritical.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.health_and_safety_outlined,
                color: CourtMidnightTheme.healthCritical,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Health permissions required',
                    style: GoogleFonts.inter(
                      color: CourtMidnightTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grant workout read permissions in Apple Health or Health Connect to automatically sync tennis sessions.',
                    style: GoogleFonts.inter(
                      color: CourtMidnightTheme.textSecondary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (onRequestPermission != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onRequestPermission,
                style: TextButton.styleFrom(
                  foregroundColor: CourtMidnightTheme.primaryVolt,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Enable',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
