import 'package:flutter/material.dart';

import '../../theme/court_midnight_theme.dart';

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
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.sports_tennis),
          label: 'Bag',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Sessions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.manage_accounts_outlined),
          label: 'Account',
        ),
      ],
    );
  }
}
