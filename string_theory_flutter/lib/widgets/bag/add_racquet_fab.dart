import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';

/// Extended FAB opening the add-racquet form.
class AddRacquetFab extends StatelessWidget {
  final VoidCallback onPressed;

  const AddRacquetFab({super.key, required this.onPressed});

  static const keyAddRacquetFab = Key('virtual_bag_fab_add');

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      key: keyAddRacquetFab,
      heroTag: 'virtual_bag_fab_add_hero',
      backgroundColor: CourtMidnightTheme.primaryVolt,
      foregroundColor: Colors.black,
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: Text(
        'Add Racquet',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
    );
  }
}
