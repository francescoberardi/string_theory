import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/bag/app_navigation_destination.dart';
import 'package:string_theory_flutter/widgets/bag/bag_bottom_nav.dart';

void main() {
  group('BagBottomNav', () {
    testWidgets('renders all AppNavigationDestination labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            bottomNavigationBar: BagBottomNav(
              currentIndex: AppNavigationDestination.bag.index,
              onTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(BagBottomNav.keyBottomNav), findsOneWidget);
      for (final dest in AppNavigationDestination.values) {
        expect(find.text(dest.label), findsOneWidget);
      }
    });

    testWidgets('triggers onTap with corresponding destination index', (
      tester,
    ) async {
      int? tappedIndex;
      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            bottomNavigationBar: BagBottomNav(
              currentIndex: AppNavigationDestination.bag.index,
              onTap: (index) => tappedIndex = index,
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
