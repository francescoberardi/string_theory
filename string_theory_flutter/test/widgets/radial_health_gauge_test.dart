import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/radial_health_gauge.dart';

void main() {
  group('Story 2.2 - RadialHealthGauge Component Tests', () {
    testWidgets(
      '[AC-1] Smoothly animates radial ring progress to target score at 60 fps',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: RadialHealthGauge(
                  healthScore: 80,
                  animate: true,
                  animationDuration: Duration(milliseconds: 600),
                ),
              ),
            ),
          ),
        );

        // Before settling, animation should be in flight
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(RadialHealthGauge), findsOneWidget);

        // Settle animation
        await tester.pumpAndSettle();
        expect(find.text('80%'), findsOneWidget);
      },
    );

    testWidgets(
      '[AC-1] Re-animates smoothly when health score updates',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: RadialHealthGauge(
                  healthScore: 80,
                  animate: true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('80%'), findsOneWidget);

        // Rebuild with updated health score
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: RadialHealthGauge(
                  healthScore: 50,
                  animate: true,
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();
        expect(find.text('50%'), findsOneWidget);
      },
    );

    testWidgets(
      '[AC-2] Renders optimal green (#10B981) ring and glow for health >= 70%',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: RadialHealthGauge(
                  healthScore: 76,
                  animate: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('76%'), findsOneWidget);

        // Verify color indicator matches CourtMidnightTheme.healthOptimal (#10B981)
        final progressFinder = find.byType(CircularProgressIndicator);
        expect(progressFinder, findsOneWidget);
        final progress = tester.widget<CircularProgressIndicator>(
          progressFinder,
        );
        final valueColor =
            progress.valueColor as AlwaysStoppedAnimation<Color>?;
        expect(valueColor?.value, equals(CourtMidnightTheme.healthOptimal));
      },
    );

    testWidgets(
      '[AC-2] Renders degraded amber (#F59E0B) ring and glow for health 40-69%',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: RadialHealthGauge(
                  healthScore: 58,
                  animate: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('58%'), findsOneWidget);

        final progressFinder = find.byType(CircularProgressIndicator);
        expect(progressFinder, findsOneWidget);
        final progress = tester.widget<CircularProgressIndicator>(
          progressFinder,
        );
        final valueColor =
            progress.valueColor as AlwaysStoppedAnimation<Color>?;
        expect(valueColor?.value, equals(CourtMidnightTheme.healthDegraded));
      },
    );

    testWidgets(
      '[AC-2] Renders critical red (#EF4444) ring and glow for health < 40%',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: RadialHealthGauge(
                  healthScore: 34,
                  animate: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('34%'), findsOneWidget);

        final progressFinder = find.byType(CircularProgressIndicator);
        expect(progressFinder, findsOneWidget);
        final progress = tester.widget<CircularProgressIndicator>(
          progressFinder,
        );
        final valueColor =
            progress.valueColor as AlwaysStoppedAnimation<Color>?;
        expect(valueColor?.value, equals(CourtMidnightTheme.healthCritical));
      },
    );

    testWidgets(
      '[AC-2] Renders neutral unstrung styling when healthScore is null',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: RadialHealthGauge(
                  healthScore: null,
                  animate: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('--'), findsOneWidget);
        expect(find.text('UNSTRUNG'), findsOneWidget);
      },
    );

    testWidgets(
      '[AC-3] Displays bold percentage in center with secondary tension loss text below',
      (tester) async {
        const tensionLossText = '~1.5 kg / ~3.3 lbs drop';

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: RadialHealthGauge(
                  healthScore: 65,
                  tensionLossText: tensionLossText,
                  animate: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('65%'), findsOneWidget);
        expect(find.text(tensionLossText), findsOneWidget);
      },
    );
  });
}
