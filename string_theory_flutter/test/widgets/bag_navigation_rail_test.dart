import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/bag/app_navigation_destination.dart';
import 'package:string_theory_flutter/widgets/bag/bag_navigation_rail.dart';

void main() {
  group('BagNavigationRail', () {
    testWidgets('renders all AppNavigationDestination labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            body: BagNavigationRail(
              selectedIndex: AppNavigationDestination.bag.index,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(BagNavigationRail.keyNavigationRail), findsOneWidget);
      for (final dest in AppNavigationDestination.values) {
        expect(find.text(dest.label), findsOneWidget);
      }
    });

    testWidgets('triggers onDestinationSelected with destination index', (
      tester,
    ) async {
      int? tappedIndex;
      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            body: BagNavigationRail(
              selectedIndex: AppNavigationDestination.bag.index,
              onDestinationSelected: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.text(AppNavigationDestination.sessions.label));
      await tester.pumpAndSettle();
      expect(tappedIndex, AppNavigationDestination.sessions.index);

      await tester.tap(find.text(AppNavigationDestination.account.label));
      await tester.pumpAndSettle();
      expect(tappedIndex, AppNavigationDestination.account.index);

      await tester.tap(find.text(AppNavigationDestination.bag.label));
      await tester.pumpAndSettle();
      expect(tappedIndex, AppNavigationDestination.bag.index);
    });
  });
}
