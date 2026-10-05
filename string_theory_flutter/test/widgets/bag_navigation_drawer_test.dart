import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
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
                selectedIndex: 0,
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
              selectedIndex: 0,
              onDestinationSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Bag'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
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
              selectedIndex: 0,
              onDestinationSelected: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Sessions'));
      await tester.pumpAndSettle();
      expect(tappedIndex, 1);

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(tappedIndex, 2);

      await tester.tap(find.text('Bag'));
      await tester.pumpAndSettle();
      expect(tappedIndex, 0);
    });
  });
}
