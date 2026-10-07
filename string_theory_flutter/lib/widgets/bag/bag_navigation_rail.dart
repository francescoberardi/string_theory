import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/court_midnight_theme.dart';
import 'app_navigation_destination.dart';

/// Tablet / desktop navigation rail: Bag, Sessions, Account.
class BagNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const BagNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const keyNavigationRail = Key('virtual_bag_navigation_rail');

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      key: keyNavigationRail,
      backgroundColor: CourtMidnightTheme.surface,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: const IconThemeData(
        color: CourtMidnightTheme.primaryVolt,
      ),
      selectedLabelTextStyle: GoogleFonts.barlowCondensed(
        color: CourtMidnightTheme.primaryVolt,
        fontWeight: FontWeight.bold,
      ),
      unselectedIconTheme: const IconThemeData(
        color: CourtMidnightTheme.textSecondary,
      ),
      unselectedLabelTextStyle: GoogleFonts.inter(
        color: CourtMidnightTheme.textSecondary,
        fontSize: 12,
      ),
      destinations: AppNavigationDestination.values
          .map((dest) => dest.toNavigationRailDestination())
          .toList(),
    );
  }
}
