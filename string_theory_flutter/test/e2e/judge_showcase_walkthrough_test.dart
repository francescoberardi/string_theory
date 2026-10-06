import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/screens/racquet_detail_screen.dart';
import 'package:string_theory_flutter/screens/virtual_bag_screen.dart';
import 'package:string_theory_flutter/services/health/health_sync_service.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/radial_health_gauge.dart';
import 'package:string_theory_flutter/widgets/restring_sheet.dart';
import 'package:string_theory_flutter/widgets/workout_assignment_sheet.dart';

import '../helpers/fake_health_sync_service.dart';

class MockBagBloc extends Mock implements BagBloc {}

class MockClient extends Mock implements Client {}

class MockEndpointBag extends Mock implements EndpointBag {}

void main() {
  late MockBagBloc mockBagBloc;
  late FakeHealthSyncService fakeHealth;
  late StreamController<BagState> bagStateController;
  late MockClient mockClient;
  late MockEndpointBag mockBag;

  final initialBlade = Racquet(
    id: 1,
    userId: 1,
    name: 'Wilson Blade 98',
    brand: 'Wilson',
    model: 'Blade 98',
    isPrimary: true,
    activeStringJobId: 101,
    activeStringJob: StringJob(
      id: 101,
      userId: 1,
      racquetId: 1,
      materialCategory: StringMaterialCategory.coPoly,
      brand: 'Luxilon',
      model: 'ALU Power',
      stringingDate: DateTime.utc(2026, 9, 25),
      installedTension: 52.0,
      maxRatedHours: 20.0,
      totalCourtHours: 5.0,
      currentHealthScore: 76,
      isActive: true,
      createdAt: DateTime.utc(2026, 9, 25),
    ),
    createdAt: DateTime.utc(2026, 9, 25),
    updatedAt: DateTime.utc(2026, 9, 25),
  );

  final initialPureAero = Racquet(
    id: 2,
    userId: 1,
    name: 'Babolat Pure Aero',
    brand: 'Babolat',
    model: 'Pure Aero',
    isPrimary: false,
    activeStringJobId: 102,
    activeStringJob: StringJob(
      id: 102,
      userId: 1,
      racquetId: 2,
      materialCategory: StringMaterialCategory.coPoly,
      brand: 'Babolat',
      model: 'RPM Blast',
      stringingDate: DateTime.utc(2026, 9, 10),
      installedTension: 54.0,
      maxRatedHours: 20.0,
      totalCourtHours: 9.0,
      currentHealthScore: 48,
      isActive: true,
      createdAt: DateTime.utc(2026, 9, 10),
    ),
    createdAt: DateTime.utc(2026, 9, 10),
    updatedAt: DateTime.utc(2026, 9, 10),
  );

  final initialRadical = Racquet(
    id: 3,
    userId: 1,
    name: 'Head Radical MP',
    brand: 'Head',
    model: 'Radical MP',
    isPrimary: false,
    activeStringJobId: 103,
    activeStringJob: StringJob(
      id: 103,
      userId: 1,
      racquetId: 3,
      materialCategory: StringMaterialCategory.multifilament,
      brand: 'Head',
      model: 'Velocity MLT',
      stringingDate: DateTime.utc(2026, 8, 1),
      installedTension: 55.0,
      maxRatedHours: 35.0,
      totalCourtHours: 25.0,
      currentHealthScore: 34,
      isActive: true,
      createdAt: DateTime.utc(2026, 8, 1),
    ),
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 1),
  );

  setUpAll(() {
    registerFallbackValue(const LoadBag());
    registerFallbackValue(const SeedSampleBag());
    registerFallbackValue(const RestringRacquet(3));
  });

  setUp(() {
    mockBagBloc = MockBagBloc();
    fakeHealth = FakeHealthSyncService(supportsSimulation: true);
    bagStateController = StreamController<BagState>.broadcast();
    mockClient = MockClient();
    mockBag = MockEndpointBag();

    when(() => mockClient.bag).thenReturn(mockBag);
    when(() => mockBagBloc.client).thenReturn(mockClient);
    when(() => mockBagBloc.stream).thenAnswer((_) => bagStateController.stream);
  });

  tearDown(() async {
    await bagStateController.close();
    fakeHealth.dispose();
  });

  Widget buildTestApp({BagState? initialState}) {
    when(() => mockBagBloc.state).thenReturn(
      initialState ?? const BagLoaded([]),
    );

    return MaterialApp(
      theme: CourtMidnightTheme.themeData,
      home: VirtualBagScreen(
        bagBloc: mockBagBloc,
        healthSyncService: fakeHealth,
      ),
    );
  }

  group('Story 5.3: End-to-End Judge Showcase Walkthrough (<90s)', () {
    testWidgets(
      'Full Judge Showcase Sequence: Launch -> Seed Bag -> Ingest Workout -> Decay -> Restring -> Timeline',
      (tester) async {
        final stopwatch = Stopwatch()..start();

        // ---------------------------------------------------------------------
        // STEP 1: App Launch & Initial Empty State
        // ---------------------------------------------------------------------
        await tester.pumpWidget(
          buildTestApp(initialState: const BagLoaded([])),
        );
        await tester.pumpAndSettle();

        expect(find.text('YOUR BAG IS EMPTY'), findsOneWidget);
        expect(find.text('⚡ Load Sample Bag'), findsOneWidget);

        // ---------------------------------------------------------------------
        // STEP 2: Instant Demo Bag Seeding (3 Racquets)
        // ---------------------------------------------------------------------
        when(
          () => mockBagBloc.add(const SeedSampleBag()),
        ).thenAnswer((_) async {});

        await tester.tap(find.text('⚡ Load Sample Bag'));
        await tester.pump();

        verify(() => mockBagBloc.add(const SeedSampleBag())).called(1);

        // Emit loaded bag state with Wilson (76%), Babolat (48%), Radical (34%)
        final seededRacquets = [initialBlade, initialPureAero, initialRadical];
        when(() => mockBagBloc.state).thenReturn(BagLoaded(seededRacquets));
        bagStateController.add(BagLoaded(seededRacquets));
        await tester.pumpAndSettle();

        expect(find.text('Wilson Blade 98'), findsOneWidget);
        expect(find.text('Babolat Pure Aero'), findsOneWidget);
        expect(find.text('Head Radical MP'), findsOneWidget);

        // Verify initial health scores
        expect(find.text('76%'), findsOneWidget);
        expect(find.text('48%'), findsOneWidget);
        expect(find.text('34%'), findsOneWidget);

        // ---------------------------------------------------------------------
        // STEP 3: Ingest Simulated Workout (<3s ingestion notification)
        // ---------------------------------------------------------------------
        fakeHealth.emit(
          DetectedWorkout(
            externalWorkoutId: 'judge-match-90m',
            startTime: DateTime.utc(2026, 10, 4, 16, 30),
            durationMinutes: 90,
            source: DetectedWorkout.sourceSimulated,
          ),
        );
        await tester.pumpAndSettle();

        // Ingestion surfaces SnackBar and auto-opens assignment sheet
        expect(find.text('1h 30m Tennis Match Detected'), findsOneWidget);
        expect(find.text('Assign'), findsOneWidget);
        expect(find.byType(WorkoutAssignmentSheet), findsOneWidget);

        // ---------------------------------------------------------------------
        // STEP 4: Assign to Wilson Blade & Real-time Decay (76% -> 67%)
        // ---------------------------------------------------------------------
        // Simulate updated state after assignment (decay to 67%)
        final decayedBlade = initialBlade.copyWith(
          activeStringJob: initialBlade.activeStringJob!.copyWith(
            currentHealthScore: 67,
            totalCourtHours: 6.5,
          ),
        );
        final decayedRacquets = [decayedBlade, initialPureAero, initialRadical];

        when(() => mockBagBloc.state).thenReturn(BagLoaded(decayedRacquets));
        bagStateController.add(BagLoaded(decayedRacquets));

        // Close assignment sheet
        Navigator.of(tester.element(find.byType(WorkoutAssignmentSheet))).pop();
        await tester.pumpAndSettle();

        // Clear active snackbar to remove any overlay
        ScaffoldMessenger.of(
          tester.element(find.byType(Scaffold)),
        ).clearSnackBars();
        await tester.pumpAndSettle();

        expect(find.text('67%'), findsOneWidget);
        expect(find.text('76%'), findsNothing);

        // ---------------------------------------------------------------------
        // STEP 5: 1-Tap Restring Reset on Head Radical (34% -> 100%)
        // ---------------------------------------------------------------------
        final restringButton = find.byKey(RacquetCard.restrungTodayKey(3));
        expect(restringButton, findsOneWidget);

        await tester.ensureVisible(restringButton);
        await tester.pumpAndSettle();

        await tester.tap(restringButton);
        await tester.pumpAndSettle();

        // Confirm the RestringSheet is presented
        expect(find.byType(RestringSheet), findsOneWidget);

        // Simulate restringing completion to 100%
        final restrungRadical = initialRadical.copyWith(
          activeStringJobId: 104,
          activeStringJob: StringJob(
            id: 104,
            userId: 1,
            racquetId: 3,
            materialCategory: StringMaterialCategory.coPoly,
            brand: 'Luxilon',
            model: 'ALU Power',
            stringingDate: DateTime.now().toUtc(),
            installedTension: 52.0,
            maxRatedHours: 20.0,
            totalCourtHours: 0.0,
            currentHealthScore: 100,
            isActive: true,
            createdAt: DateTime.now().toUtc(),
          ),
        );
        final restrungRacquets = [
          decayedBlade,
          initialPureAero,
          restrungRadical,
        ];

        when(() => mockBagBloc.state).thenReturn(BagLoaded(restrungRacquets));
        bagStateController.add(BagLoaded(restrungRacquets));

        // Dismiss sheet
        Navigator.of(tester.element(find.byType(RestringSheet))).pop();
        await tester.pumpAndSettle();

        expect(find.text('100%'), findsOneWidget);
        expect(find.text('34%'), findsNothing);

        // ---------------------------------------------------------------------
        // STEP 6: Inspect Racquet Detail Timeline
        // ---------------------------------------------------------------------
        when(
          () => mockBag.getRestringHistory(racquetId: any(named: 'racquetId')),
        ).thenAnswer(
          (_) async => [
            RestringEvent(
              id: 101,
              userId: 1,
              racquetId: 3,
              stringJobId: 103,
              stringDescription: 'Head Velocity MLT',
              materialCategory: StringMaterialCategory.multifilament,
              installedTension: 55.0,
              stringingDate: DateTime.utc(2026, 8, 1),
              restringDate: DateTime.utc(2026, 10, 6),
              finalCourtHours: 25.0,
              finalDaysActive: 66,
              finalHealthScore: 34,
              createdAt: DateTime.utc(2026, 10, 6),
            ),
          ],
        );

        // Tap Head Radical card to push RacquetDetailScreen
        final radicalCardText = find.text('Head Radical MP');
        await tester.ensureVisible(radicalCardText);
        await tester.pumpAndSettle();
        await tester.tap(radicalCardText);
        await tester.pumpAndSettle();

        expect(find.byType(RacquetDetailScreen), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(RacquetDetailScreen),
            matching: find.text('Head Radical MP'),
          ),
          findsWidgets,
        );
        expect(find.byType(RadialHealthGauge), findsOneWidget);

        // Tap History tab to inspect timeline
        await tester.tap(find.text('History'));
        await tester.pumpAndSettle();

        expect(find.text('Head Velocity MLT'), findsOneWidget);
        expect(find.textContaining('25.0 court hours'), findsOneWidget);

        stopwatch.stop();

        // Verify total automated execution time is well under the 90-second benchmark
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(90000),
          reason: 'Walkthrough must complete deterministically in <90 seconds',
        );
      },
    );
  });
}
