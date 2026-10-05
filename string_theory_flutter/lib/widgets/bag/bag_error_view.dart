import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Error message with a reload action, shown when the bag fails to load.
class BagErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onReload;

  const BagErrorView({
    super.key,
    required this.message,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: CourtMidnightTheme.healthCritical,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                color: CourtMidnightTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onReload,
              icon: const Icon(Icons.refresh),
              label: const Text('Reload Bag'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CourtMidnightTheme.primaryVolt,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
