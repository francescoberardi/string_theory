import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/screens/racquet_detail_screen.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/radial_health_gauge.dart';
import 'package:string_theory_flutter/widgets/restring_sheet.dart';
import 'package:string_theory_flutter/widgets/timeline/restring_timeline_tile.dart';

class MockClient extends Mock implements Client {}

class MockEndpointBag extends Mock implements EndpointBag {}

class MockBagBloc extends Mock implements BagBloc {}

void main() {
  late MockClient mockClient;
  late MockEndpointBag mockBag;
  late MockBagBloc mockBagBloc;
  late StreamController<BagState> bagStateController;

  Racquet createRacquet({
    int id = 1,
    String name = 'Wilson Blade 98',
    bool isPrimary = true,
    int healthScore = 76,
    double totalCourtHours = 8.0,
    double maxRatedHours = 20.0,
    double? installedTension = 52.0,
    String brand = 'Luxilon',
    String model = 'ALU Power',
    StringMaterialCategory materialCategory = StringMaterialCategory.coPoly,
    int activeStringJobId = 10,
  }) {
    return Racquet(
      id: id,
      userId: 1,
      name: name,
      brand: 'Wilson',
      model: name,
      isPrimary: isPrimary,
      activeStringJobId: activeStringJobId,
      activeStringJob: StringJob(
        id: activeStringJobId,
        userId: 1,
        racquetId: id,
        materialCategory: materialCategory,
        brand: brand,
        model: model,
        stringingDate: DateTime.utc(2026, 9, 20),
        installedTension: installedTension,
        maxRatedHours: maxRatedHours,
        totalCourtHours: totalCourtHours,
        currentHealthScore: healthScore,
        isActive: true,
        createdAt: DateTime.utc(2026, 9, 20),
      ),
      createdAt: DateTime.utc(2026, 9, 20),
      updatedAt: DateTime.utc(2026, 9, 20),
    );
  }

  setUp(() {
    mockClient = MockClient();
    mockBag = MockEndpointBag();
    mockBagBloc = MockBagBloc();
    bagStateController = StreamController<BagState>.broadcast();

    when(() => mockClient.bag).thenReturn(mockBag);
    when(() => mockBagBloc.client).thenReturn(mockClient);
    when(() => mockBagBloc.state).thenReturn(
      BagLoaded([createRacquet()]),
    );
    when(() => mockBagBloc.stream).thenAnswer((_) => bagStateController.stream);
  });

  tearDown(() {
    bagStateController.close();
  });

  Widget buildSubject({
    required Racquet racquet,
    Client? client,
    BagBloc? bloc,
  }) {
    final effectiveBloc = bloc ?? mockBagBloc;
    return MaterialApp(
      theme: CourtMidnightTheme.themeData,
      home: BlocProvider<BagBloc>.value(
        value: effectiveBloc,
        child: RacquetDetailScreen(
          racquet: racquet,
          bagBloc: effectiveBloc,
          client: client ?? mockClient,
        ),
      ),
    );
  }

  group('RacquetDetailScreen - Overview Tab', () {
    testWidgets('renders active string specs, gauge, and court hours', (
      tester,
    ) async {
      final racquet = createRacquet(
        name: 'Wilson Blade 98',
        isPrimary: true,
        healthScore: 76,
        totalCourtHours: 8.0,
        maxRatedHours: 20.0,
        installedTension: 52.0,
      );

      when(
        () => mockBag.getRestringHistory(racquetId: any(named: 'racquetId')),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(buildSubject(racquet: racquet));
      await tester.pumpAndSettle();

      // Racquet name & Primary badge
      expect(find.text('Wilson Blade 98'), findsWidgets);
      expect(find.text('PRIMARY'), findsOneWidget);

      // String specs & Material
      expect(find.textContaining('Luxilon ALU Power'), findsOneWidget);
      expect(find.textContaining('Co-Polyester'), findsWidgets);
      expect(find.textContaining('52'), findsWidgets);

      // Radial Health Gauge
      expect(find.byType(RadialHealthGauge), findsOneWidget);

      // Court hours and remaining hours
      expect(find.textContaining('8.0'), findsWidgets);
      expect(find.textContaining('12.0'), findsWidgets);

      // Estimated Tension Loss Card
      expect(find.byKey(RacquetDetailKeys.tensionLossCard), findsOneWidget);
      expect(find.text('ESTIMATED TENSION LOSS'), findsOneWidget);
      expect(find.text('~1.4 kg / ~3.1 lbs drop'), findsOneWidget);

      // Restrung Today button
      expect(find.byKey(RacquetDetailKeys.restrungTodayButton), findsOneWidget);
      expect(find.text('Restrung Today'), findsOneWidget);
    });

    testWidgets('tapping [Restrung Today] opens RestringSheet', (tester) async {
      final racquet = createRacquet();

      when(
        () => mockBag.getRestringHistory(racquetId: any(named: 'racquetId')),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(buildSubject(racquet: racquet));
      await tester.pumpAndSettle();

      final restrungButton = find.text('Restrung Today');
      await tester.ensureVisible(restrungButton);
      await tester.pumpAndSettle();

      await tester.tap(restrungButton);
      await tester.pumpAndSettle();

      expect(find.byType(RestringSheet), findsOneWidget);
    });

    testWidgets(
      'real-time BagBloc update with new activeStringJobId updates overview and reloads history',
      (tester) async {
        final initialRacquet = createRacquet(
          id: 1,
          healthScore: 35,
          totalCourtHours: 25.0,
          activeStringJobId: 10,
        );

        var historyCallCount = 0;
        when(() => mockBagBloc.state).thenReturn(
          BagLoaded([initialRacquet]),
        );
        when(
          () => mockBag.getRestringHistory(racquetId: 1),
        ).thenAnswer((_) async {
          historyCallCount++;
          return [];
        });

        await tester.pumpWidget(buildSubject(racquet: initialRacquet));
        await tester.pumpAndSettle();

        expect(historyCallCount, equals(1));
        expect(find.textContaining('35%'), findsWidgets);

        // Emit BagLoaded with fresh string job (activeStringJobId = 11, health = 100%, courtHours = 0.0)
        final restrungRacquet = initialRacquet.copyWith(
          activeStringJobId: 11,
          activeStringJob: initialRacquet.activeStringJob!.copyWith(
            id: 11,
            currentHealthScore: 100,
            totalCourtHours: 0.0,
            brand: 'Babolat',
            model: 'RPM Blast',
          ),
        );

        bagStateController.add(BagLoaded([restrungRacquet]));
        await tester.pumpAndSettle();

        // Overview updated with fresh specs
        expect(find.textContaining('100%'), findsWidgets);
        expect(find.textContaining('Babolat RPM Blast'), findsOneWidget);

        // History re-fetch was triggered
        expect(historyCallCount, equals(2));
      },
    );
  });

  group('RacquetDetailScreen - History Tab', () {
    testWidgets('renders chronological timeline of past string jobs', (
      tester,
    ) async {
      final racquet = createRacquet(id: 1);
      final events = [
        RestringEvent(
          id: 101,
          userId: 1,
          racquetId: 1,
          stringJobId: 5,
          stringDescription: 'Luxilon ALU Power',
          materialCategory: StringMaterialCategory.coPoly,
          installedTension: 52.0,
          stringingDate: DateTime.utc(2026, 8, 10),
          restringDate: DateTime.utc(2026, 10, 2),
          finalCourtHours: 18.5,
          finalDaysActive: 53,
          finalHealthScore: 72,
          createdAt: DateTime.utc(2026, 10, 2),
        ),
        RestringEvent(
          id: 100,
          userId: 1,
          racquetId: 1,
          stringJobId: 4,
          stringDescription: 'Babolat RPM Blast',
          materialCategory: StringMaterialCategory.coPoly,
          installedTension: 54.0,
          stringingDate: DateTime.utc(2026, 6, 1),
          restringDate: DateTime.utc(2026, 8, 9),
          finalCourtHours: 22.0,
          finalDaysActive: 69,
          finalHealthScore: 35,
          createdAt: DateTime.utc(2026, 8, 9),
        ),
      ];

      when(
        () => mockBag.getRestringHistory(racquetId: 1),
      ).thenAnswer((_) async => events);

      await tester.pumpWidget(buildSubject(racquet: racquet));
      await tester.pumpAndSettle();

      // Tap History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.byType(RestringTimelineTile), findsNWidgets(2));
      expect(find.text('Luxilon ALU Power'), findsOneWidget);
      expect(find.text('Babolat RPM Blast'), findsOneWidget);
      expect(find.textContaining('18.5 court hours'), findsOneWidget);
      expect(find.textContaining('53 days active'), findsOneWidget);
      expect(find.textContaining('72%'), findsOneWidget);
      expect(find.textContaining('52.0 lbs'), findsOneWidget);
      expect(find.textContaining('Aug 10 – Oct 2'), findsOneWidget);
    });

    testWidgets('renders friendly empty state when no restrings exist', (
      tester,
    ) async {
      final racquet = createRacquet(id: 2);

      when(
        () => mockBag.getRestringHistory(racquetId: 2),
      ).thenAnswer((_) async => []);

      await tester.pumpWidget(buildSubject(racquet: racquet));
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.byType(RestringTimelineTile), findsNothing);
      expect(
        find.text(
          'No past restrings recorded for this racquet yet. Restring history will appear here once you retire your first stringbed.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows error state with [Retry] button and refetches on tap', (
      tester,
    ) async {
      final racquet = createRacquet(id: 3);

      var attempt = 0;
      when(() => mockBag.getRestringHistory(racquetId: 3)).thenAnswer((_) {
        attempt++;
        if (attempt == 1) {
          throw Exception('Network connection timed out');
        }
        return Future.value([
          RestringEvent(
            id: 200,
            userId: 1,
            racquetId: 3,
            stringJobId: 9,
            stringDescription: 'Solinco Hyper-G',
            materialCategory: StringMaterialCategory.coPoly,
            installedTension: 48.0,
            stringingDate: DateTime.utc(2026, 9, 1),
            restringDate: DateTime.utc(2026, 9, 25),
            finalCourtHours: 15.0,
            finalDaysActive: 24,
            finalHealthScore: 68,
            createdAt: DateTime.utc(2026, 9, 25),
          ),
        ]);
      });

      await tester.pumpWidget(buildSubject(racquet: racquet));
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Network connection timed out'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);

      // Tap Retry
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(RestringTimelineTile), findsOneWidget);
      expect(find.text('Solinco Hyper-G'), findsOneWidget);
    });

    testWidgets(
      'gracefully handles missing installedTension without crashing',
      (
        tester,
      ) async {
        final racquet = createRacquet(id: 4);
        final events = [
          RestringEvent(
            id: 300,
            userId: 1,
            racquetId: 4,
            stringJobId: 12,
            stringDescription: 'Vintage Gut Setup',
            materialCategory: StringMaterialCategory.naturalGut,
            installedTension: null,
            stringingDate: DateTime.utc(2026, 7, 1),
            restringDate: DateTime.utc(2026, 7, 30),
            finalCourtHours: 10.0,
            finalDaysActive: 29,
            finalHealthScore: 80,
            createdAt: DateTime.utc(2026, 7, 30),
          ),
        ];

        when(
          () => mockBag.getRestringHistory(racquetId: 4),
        ).thenAnswer((_) async => events);

        await tester.pumpWidget(buildSubject(racquet: racquet));
        await tester.pumpAndSettle();

        await tester.tap(find.text('History'));
        await tester.pumpAndSettle();

        expect(find.byType(RestringTimelineTile), findsOneWidget);
        expect(find.text('Vintage Gut Setup'), findsOneWidget);
        expect(find.text('—'), findsOneWidget);
      },
    );

    testWidgets(
      'includes years when stringingDate and restringDate span different years',
      (tester) async {
        final racquet = createRacquet(id: 5);
        final multiYearEvent = RestringEvent(
          id: 400,
          userId: 1,
          racquetId: 5,
          stringJobId: 20,
          stringDescription: 'Multi-Year String',
          materialCategory: StringMaterialCategory.coPoly,
          installedTension: 50.0,
          stringingDate: DateTime.utc(2025, 11, 15),
          restringDate: DateTime.utc(2026, 2, 10),
          finalCourtHours: 12.0,
          finalDaysActive: 87,
          finalHealthScore: 65,
          createdAt: DateTime.utc(2026, 2, 10),
        );

        when(
          () => mockBag.getRestringHistory(racquetId: 5),
        ).thenAnswer((_) async => [multiYearEvent]);

        await tester.pumpWidget(buildSubject(racquet: racquet));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(RacquetDetailKeys.historyTab));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Nov 15, 2025 – Feb 10, 2026'),
          findsOneWidget,
        );
      },
    );
  });
}
