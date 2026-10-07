import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_flutter/widgets/bag/app_navigation_destination.dart';

void main() {
  group('AppNavigationDestination', () {
    test('defines canonical destinations with ordered indices', () {
      expect(AppNavigationDestination.values.length, 3);
      expect(AppNavigationDestination.bag.index, 0);
      expect(AppNavigationDestination.sessions.index, 1);
      expect(AppNavigationDestination.account.index, 2);
    });

    test('defines labels and icons consistently', () {
      expect(AppNavigationDestination.bag.label, 'Bag');
      expect(AppNavigationDestination.bag.icon, Icons.sports_tennis);

      expect(AppNavigationDestination.sessions.label, 'Sessions');
      expect(AppNavigationDestination.sessions.icon, Icons.history);

      expect(AppNavigationDestination.account.label, 'Account');
      expect(
        AppNavigationDestination.account.icon,
        Icons.manage_accounts_outlined,
      );
    });

    test(
      'resolves destination from valid and invalid indices via fromIndex',
      () {
        expect(
          AppNavigationDestination.fromIndex(0),
          AppNavigationDestination.bag,
        );
        expect(
          AppNavigationDestination.fromIndex(1),
          AppNavigationDestination.sessions,
        );
        expect(
          AppNavigationDestination.fromIndex(2),
          AppNavigationDestination.account,
        );

        expect(AppNavigationDestination.fromIndex(-1), isNull);
        expect(AppNavigationDestination.fromIndex(3), isNull);
        expect(AppNavigationDestination.fromIndex(99), isNull);
      },
    );

    test('converts to BottomNavigationBarItem', () {
      for (final dest in AppNavigationDestination.values) {
        final item = dest.toBottomNavigationBarItem();
        expect(item.label, dest.label);
        expect((item.icon as Icon).icon, dest.icon);
      }
    });

    test('converts to NavigationRailDestination', () {
      for (final dest in AppNavigationDestination.values) {
        final railDest = dest.toNavigationRailDestination();
        expect((railDest.icon as Icon).icon, dest.icon);
        expect((railDest.label as Text).data, dest.label);
      }
    });

    test('converts to NavigationDrawerDestination', () {
      for (final dest in AppNavigationDestination.values) {
        final drawerDest = dest.toNavigationDrawerDestination();
        expect((drawerDest.icon as Icon).icon, dest.icon);
        expect((drawerDest.label as Text).data, dest.label);
      }
    });
  });
}
