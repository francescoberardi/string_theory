import 'package:flutter/material.dart';

/// Navigation destinations shared across mobile bottom nav, tablet rail,
/// and desktop navigation drawer.
enum AppNavigationDestination {
  bag(
    label: 'Bag',
    icon: Icons.sports_tennis,
  ),
  sessions(
    label: 'Sessions',
    icon: Icons.history,
  ),
  account(
    label: 'Account',
    icon: Icons.manage_accounts_outlined,
  );

  final String label;
  final IconData icon;

  const AppNavigationDestination({
    required this.label,
    required this.icon,
  });

  /// Builds a [BottomNavigationBarItem] for mobile bottom navigation.
  BottomNavigationBarItem toBottomNavigationBarItem() {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      label: label,
    );
  }

  /// Builds a [NavigationRailDestination] for tablet navigation rail.
  NavigationRailDestination toNavigationRailDestination() {
    return NavigationRailDestination(
      icon: Icon(icon),
      label: Text(label),
    );
  }

  /// Builds a [NavigationDrawerDestination] for desktop navigation drawer.
  NavigationDrawerDestination toNavigationDrawerDestination() {
    return NavigationDrawerDestination(
      icon: Icon(icon),
      label: Text(label),
    );
  }

  /// Returns the [AppNavigationDestination] matching [index], or `null` if out of bounds.
  static AppNavigationDestination? fromIndex(int index) {
    if (index < 0 || index >= values.length) return null;
    return values[index];
  }
}
