import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Empty-bag card offering to add a racquet or seed the sample bag.
class BagEmptyState extends StatelessWidget {
  final VoidCallback onAddRacquet;
  final VoidCallback onLoadSampleBag;

  const BagEmptyState({
    super.key,
    required this.onAddRacquet,
    required this.onLoadSampleBag,
  });

  static const keyEmptyState = Key('virtual_bag_empty_state');
  static const keyEmptyAddButton = Key('virtual_bag_empty_add_button');
  static const keyLoadSampleBagButton = Key(
    'virtual_bag_load_sample_bag_button',
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          key: keyEmptyState,
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: CourtMidnightTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: CourtMidnightTheme.surfaceBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: CourtMidnightTheme.primaryVolt.withValues(alpha: 0.12),
                  border: Border.all(
                    color: CourtMidnightTheme.primaryVolt.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: const Icon(
                  Icons.sports_tennis,
                  size: 38,
                  color: CourtMidnightTheme.primaryVolt,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'YOUR BAG IS EMPTY',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: CourtMidnightTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add your racquets to track stringbed decay, tension loss, and court hours.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: CourtMidnightTheme.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  key: keyEmptyAddButton,
                  onPressed: onAddRacquet,
                  icon: const Icon(Icons.add, color: Colors.black),
                  label: Text(
                    '+ Add Racquet',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CourtMidnightTheme.primaryVolt,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  key: keyLoadSampleBagButton,
                  onPressed: onLoadSampleBag,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CourtMidnightTheme.primaryVolt,
                    side: const BorderSide(
                      color: CourtMidnightTheme.primaryVolt,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '⚡ Load Sample Bag',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: CourtMidnightTheme.primaryVolt,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
