import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/bag/app_navigation_destination.dart';
import 'package:string_theory_flutter/widgets/bag/bag_navigation_drawer.dart';

void main() {
  group('BagNavigationDrawer', () {
    testWidgets(
      'renders branded header with STRING THEORY and tennis ball icon',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: Scaffold(
              body: BagNavigationDrawer(
                selectedIndex: AppNavigationDestination.bag.index,
                onDestinationSelected: (_) {},
              ),
            ),
          ),
        );

        expect(
          find.byKey(BagNavigationDrawer.keyNavigationDrawer),
          findsOneWidget,
        );
        expect(find.text('STRING THEORY'), findsOneWidget);
        expect(find.byIcon(Icons.sports_tennis), findsWidgets);
      },
    );

    testWidgets('renders Bag, Sessions, Account destinations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            body: BagNavigationDrawer(
              selectedIndex: AppNavigationDestination.bag.index,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      for (final dest in AppNavigationDestination.values) {
        expect(find.text(dest.label), findsOneWidget);
      }
    });

    testWidgets('triggers onDestinationSelected when destination tapped', (
      tester,
    ) async {
      int? tappedIndex;
      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            body: BagNavigationDrawer(
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
