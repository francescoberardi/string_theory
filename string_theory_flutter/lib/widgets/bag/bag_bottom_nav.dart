import 'package:flutter/material.dart';

import '../../theme/court_midnight_theme.dart';
import 'app_navigation_destination.dart';

/// Mobile bottom navigation: Bag, Sessions, Account.
class BagBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BagBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const keyBottomNav = Key('virtual_bag_bottom_nav');

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      key: keyBottomNav,
      type: BottomNavigationBarType.fixed,
      backgroundColor: CourtMidnightTheme.surface,
      selectedItemColor: CourtMidnightTheme.primaryVolt,
      unselectedItemColor: CourtMidnightTheme.textSecondary,
      currentIndex: currentIndex,
      onTap: onTap,
      items: AppNavigationDestination.values
          .map((dest) => dest.toBottomNavigationBarItem())
          .toList(),
    );
  }
}
