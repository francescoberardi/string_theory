import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/bag/bag_racquet_list.dart';
import 'package:string_theory_flutter/widgets/racquet_card.dart';
import 'package:string_theory_flutter/widgets/radial_health_gauge.dart';
import 'package:string_theory_flutter/widgets/restring_sheet.dart';

class MockBagBloc extends Mock implements BagBloc {}

void main() {
  late MockBagBloc mockBagBloc;

  setUp(() {
    mockBagBloc = MockBagBloc();
  });

  Racquet createRacquet({
    required int id,
    required String name,
    int? healthScore,
    bool isPrimary = false,
  }) {
    return Racquet(
      id: id,
      userId: 1,
      name: name,
      brand: 'Wilson',
      model: name,
      isPrimary: isPrimary,
      activeStringJob: healthScore != null
          ? StringJob(
              id: id,
              userId: 1,
              racquetId: id,
              materialCategory: StringMaterialCategory.coPoly,
              brand: 'Luxilon',
              model: 'ALU Power',
              stringingDate: DateTime.utc(2026, 9, 20),
              installedTension: 52.0,
              maxRatedHours: 20.0,
              totalCourtHours: 8.0,
              currentHealthScore: healthScore,
              isActive: true,
              createdAt: DateTime.utc(2026, 9, 20),
            )
          : null,
      createdAt: DateTime.utc(2026, 9, 20),
      updatedAt: DateTime.utc(2026, 9, 20),
    );
  }

  group('Story 2.2 - RacquetCard Integration Tests', () {
    testWidgets(
      '[AC-1/AC-3] Integrates RadialHealthGauge widget with current health score',
      (tester) async {
        final racquet = createRacquet(
          id: 1,
          name: 'Wilson Blade 98',
          healthScore: 76,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RacquetCard(
                racquet: racquet,
                bloc: mockBagBloc,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(RadialHealthGauge), findsOneWidget);
        expect(find.text('Wilson Blade 98'), findsOneWidget);
      },
    );

    testWidgets(
      '[AC-4] Displays cautionary badge "Dead Stringbed — High Shock Risk" when health < 40%',
      (tester) async {
        final criticalRacquet = createRacquet(
          id: 2,
          name: 'Head Radical MP',
          healthScore: 34,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RacquetCard(
                racquet: criticalRacquet,
                bloc: mockBagBloc,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dead Stringbed — High Shock Risk'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      },
    );

    testWidgets(
      '[AC-4] Does NOT display cautionary badge when health >= 40%',
      (tester) async {
        final healthyRacquet = createRacquet(
          id: 3,
          name: 'Babolat Pure Aero',
          healthScore: 72,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RacquetCard(
                racquet: healthyRacquet,
                bloc: mockBagBloc,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dead Stringbed — High Shock Risk'), findsNothing);
      },
    );

    testWidgets(
      '[AC-4] Does NOT display cautionary badge when health is in amber range (40-69%)',
      (tester) async {
        final amberRacquet = createRacquet(
          id: 4,
          name: 'Yonex EZONE 98',
          healthScore: 55,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RacquetCard(
                racquet: amberRacquet,
                bloc: mockBagBloc,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dead Stringbed — High Shock Risk'), findsNothing);
      },
    );

    testWidgets(
      'Renders unstrung status and "--" when racquet has no active string job',
      (tester) async {
        final unstrungRacquet = createRacquet(
          id: 5,
          name: 'Pro Staff 97',
          healthScore: null,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RacquetCard(
                racquet: unstrungRacquet,
                bloc: mockBagBloc,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pro Staff 97'), findsOneWidget);
        expect(find.text('No string mounted'), findsOneWidget);
      },
    );

    testWidgets(
      '[AC-4 Boundary] Exact 40% health is amber tier and does NOT display cautionary badge',
      (tester) async {
        final boundary40Racquet = createRacquet(
          id: 6,
          name: 'Blade 40',
          healthScore: 40,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RacquetCard(
                racquet: boundary40Racquet,
                bloc: mockBagBloc,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dead Stringbed — High Shock Risk'), findsNothing);
      },
    );

    testWidgets(
      '[AC-4 Boundary] Exact 39% health enters critical tier and displays cautionary badge',
      (tester) async {
        final boundary39Racquet = createRacquet(
          id: 7,
          name: 'Blade 39',
          healthScore: 39,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RacquetCard(
                racquet: boundary39Racquet,
                bloc: mockBagBloc,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dead Stringbed — High Shock Risk'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Triggers onTap callback when card is tapped',
      (tester) async {
        var tapped = false;
        final racquet = createRacquet(
          id: 8,
          name: 'Tapped Racquet',
          healthScore: 85,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RacquetCard(
                racquet: racquet,
                bloc: mockBagBloc,
                onTap: () => tapped = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tapped Racquet'));
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      '[Story 2.4] Tapping Fast-Forward 30 Days in popup menu dispatches FastForwardRacquetAge to bloc',
      (tester) async {
        final racquet = createRacquet(
          id: 9,
          name: 'Fast Forward Racquet',
          healthScore: 75,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RacquetCard(
                racquet: racquet,
                bloc: mockBagBloc,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open popup menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.text('Fast-Forward 30 Days'), findsOneWidget);

        await tester.tap(find.text('Fast-Forward 30 Days'));
        await tester.pumpAndSettle();

        verify(
          () => mockBagBloc.add(const FastForwardRacquetAge(9, days: 30)),
        ).called(1);
        expect(
          find.text('Aged "Fast Forward Racquet" by 30 days'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '[Story 2.4] Unstrung racquet does NOT show Fast-Forward option in popup menu',
      (tester) async {
        final unstrungRacquet = createRacquet(
          id: 10,
          name: 'Unstrung Frame',
          healthScore: null,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RacquetCard(
                racquet: unstrungRacquet,
                bloc: mockBagBloc,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.text('Fast-Forward 30 Days'), findsNothing);
      },
    );
  });

  group('Story 4.2 - Restrung Today button', () {
    Future<void> pumpCard(WidgetTester tester, Racquet racquet) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            body: RacquetCard(racquet: racquet, bloc: mockBagBloc),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('is prominent (filled) when health is below 40%', (
      tester,
    ) async {
      await pumpCard(
        tester,
        createRacquet(id: 4, name: 'Dead', healthScore: 20),
      );

      final button = find.byKey(RacquetCard.restrungTodayKey(4));
      expect(button, findsOneWidget);
      expect(find.text('Restrung Today'), findsOneWidget);
      expect(tester.widget(button), isA<ElevatedButton>());
    });

    testWidgets('is a quieter outlined button on a healthy racquet', (
      tester,
    ) async {
      await pumpCard(
        tester,
        createRacquet(id: 5, name: 'Fresh', healthScore: 90),
      );

      final button = find.byKey(RacquetCard.restrungTodayKey(5));
      expect(button, findsOneWidget);
      expect(tester.widget(button), isA<OutlinedButton>());
    });

    testWidgets('is hidden when the racquet has no active string job', (
      tester,
    ) async {
      await pumpCard(tester, createRacquet(id: 6, name: 'Bare'));

      expect(find.byKey(RacquetCard.restrungTodayKey(6)), findsNothing);
      expect(find.text('Restrung Today'), findsNothing);
    });

    testWidgets('opens the restring sheet with both options', (tester) async {
      await pumpCard(
        tester,
        createRacquet(id: 4, name: 'Dead', healthScore: 20),
      );

      await tester.tap(find.byKey(RacquetCard.restrungTodayKey(4)));
      await tester.pumpAndSettle();

      expect(find.byKey(RestringSheet.keySheet), findsOneWidget);
      expect(find.text('Keep Same & Reset'), findsOneWidget);
      expect(find.text('Change Specs'), findsOneWidget);
    });

    testWidgets('opens the same sheet from a healthy racquet', (tester) async {
      await pumpCard(
        tester,
        createRacquet(id: 5, name: 'Fresh', healthScore: 90),
      );

      await tester.tap(find.byKey(RacquetCard.restrungTodayKey(5)));
      await tester.pumpAndSettle();

      expect(find.byKey(RestringSheet.keySheet), findsOneWidget);
      expect(find.text('Keep Same & Reset'), findsOneWidget);
    });

    testWidgets('fits a tablet grid cell with the dead-stringbed badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: BagRacquetList.gridCardExtent,
              child: RacquetCard(
                racquet: createRacquet(id: 4, name: 'Dead', healthScore: 20),
                bloc: mockBagBloc,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
