import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/screens/virtual_bag_screen.dart';
import 'package:string_theory_flutter/services/health/health_sync_service.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/add_racquet_modal.dart';

import 'helpers/fake_health_sync_service.dart';

class MockBagBloc extends Mock implements BagBloc {}

void main() {
  late MockBagBloc mockBagBloc;
  late FakeHealthSyncService fakeHealth;

  final sampleRacquets = [
    Racquet(
      id: 1,
      userId: 1,
      name: 'Wilson Blade 98',
      brand: 'Wilson',
      model: 'Blade 98',
      isPrimary: true,
      activeStringJob: StringJob(
        id: 1,
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
    ),
    Racquet(
      id: 2,
      userId: 1,
      name: 'Babolat Pure Drive',
      brand: 'Babolat',
      model: 'Pure Drive',
      isPrimary: false,
      activeStringJob: StringJob(
        id: 2,
        userId: 1,
        racquetId: 2,
        materialCategory: StringMaterialCategory.coPoly,
        brand: 'Babolat',
        model: 'RPM Blast',
        stringingDate: DateTime.utc(2026, 9, 10),
        installedTension: 54.0,
        maxRatedHours: 20.0,
        totalCourtHours: 9.0,
        currentHealthScore: 58,
        isActive: true,
        createdAt: DateTime.utc(2026, 9, 10),
      ),
      createdAt: DateTime.utc(2026, 9, 10),
      updatedAt: DateTime.utc(2026, 9, 10),
    ),
    Racquet(
      id: 3,
      userId: 1,
      name: 'Head Radical MP',
      brand: 'Head',
      model: 'Radical MP',
      isPrimary: false,
      activeStringJob: StringJob(
        id: 3,
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
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const LoadBag());
    registerFallbackValue(const SeedSampleBag());
  });

  setUp(() {
    mockBagBloc = MockBagBloc();
    fakeHealth = FakeHealthSyncService();
  });

  tearDown(() => fakeHealth.dispose());

  group('Story 1.5: Virtual Bag Responsive Screen & Demo Bag Seeder', () {
    testWidgets(
      '[P0] AC-1 should render empty state with Add Racquet and Load Sample Bag buttons when bag is empty',
      (tester) async {
        when(() => mockBagBloc.state).thenReturn(const BagLoaded([]));
        when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: VirtualBagScreen(
              bagBloc: mockBagBloc,
              healthSyncService: fakeHealth,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Criterion-defining primary assertion: empty state is visible
        expect(
          find.byKey(VirtualBagScreen.keyEmptyState),
          findsOneWidget,
          reason:
              'Virtual Bag must render empty state container when no racquets exist',
        );

        // Secondary assertions: Add Racquet button and Load Sample Bag button
        expect(find.byKey(VirtualBagScreen.keyEmptyAddButton), findsOneWidget);
        expect(
          find.byKey(VirtualBagScreen.keyLoadSampleBagButton),
          findsOneWidget,
        );
        expect(find.text('⚡ Load Sample Bag'), findsOneWidget);
      },
    );

    testWidgets(
      '[P0] AC-2 should open AddRacquetModal when [+ Add Racquet] is tapped on empty state',
      (tester) async {
        when(() => mockBagBloc.state).thenReturn(const BagLoaded([]));
        when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: VirtualBagScreen(
              bagBloc: mockBagBloc,
              healthSyncService: fakeHealth,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Add Racquet button
        await tester.tap(find.byKey(VirtualBagScreen.keyEmptyAddButton));
        await tester.pumpAndSettle();

        // Criterion-defining primary assertion: AddRacquetModal is shown
        expect(
          find.byType(AddRacquetModal),
          findsOneWidget,
          reason:
              'Tapping Add Racquet on empty state must open AddRacquetModal',
        );
      },
    );

    testWidgets(
      '[P0] AC-3 should dispatch SeedSampleBag event to BagBloc when [⚡ Load Sample Bag] is tapped',
      (tester) async {
        when(() => mockBagBloc.state).thenReturn(const BagLoaded([]));
        when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: VirtualBagScreen(
              bagBloc: mockBagBloc,
              healthSyncService: fakeHealth,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Load Sample Bag
        await tester.tap(find.byKey(VirtualBagScreen.keyLoadSampleBagButton));
        await tester.pumpAndSettle();

        // Criterion-defining primary assertion: SeedSampleBag event dispatched to BagBloc
        verify(() => mockBagBloc.add(const SeedSampleBag())).called(1);
      },
    );

    testWidgets(
      '[P0] AC-4 should display single-column card list with bottom navigation bar on mobile screen width (<600dp)',
      (tester) async {
        // Configure mobile screen size (e.g. 400 x 800)
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        when(() => mockBagBloc.state).thenReturn(BagLoaded(sampleRacquets));
        when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: VirtualBagScreen(
              bagBloc: mockBagBloc,
              healthSyncService: fakeHealth,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Criterion-defining primary assertion: single column list is rendered on mobile
        expect(
          find.byKey(VirtualBagScreen.keyRacquetList),
          findsOneWidget,
          reason: 'Mobile screen must render racquets in a single-column list',
        );

        expect(find.byType(RacquetCard), findsNWidgets(sampleRacquets.length));
        expect(find.text('Wilson Blade 98'), findsOneWidget);

        // Bottom navigation bar is visible on mobile
        expect(find.byKey(VirtualBagScreen.keyBottomNav), findsOneWidget);
        expect(find.byKey(VirtualBagScreen.keyNavigationRail), findsNothing);
      },
    );

    testWidgets(
      '[P0] AC-5 should display adaptive 2-column grid with NavigationRail on tablet/desktop screen width (>=600dp)',
      (tester) async {
        // Configure tablet screen size (e.g. 900 x 1200)
        tester.view.physicalSize = const Size(900, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        when(() => mockBagBloc.state).thenReturn(BagLoaded(sampleRacquets));
        when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: VirtualBagScreen(
              bagBloc: mockBagBloc,
              healthSyncService: fakeHealth,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Criterion-defining primary assertion: 2-column grid is rendered on tablet/desktop
        expect(
          find.byKey(VirtualBagScreen.keyRacquetGrid),
          findsOneWidget,
          reason:
              'Tablet/desktop screen must render racquets in a multi-column grid',
        );

        expect(find.byType(RacquetCard), findsNWidgets(sampleRacquets.length));
        expect(find.text('Wilson Blade 98'), findsOneWidget);

        // NavigationRail is visible on tablet/desktop
        expect(find.byKey(VirtualBagScreen.keyNavigationRail), findsOneWidget);
        expect(find.byKey(VirtualBagScreen.keyBottomNav), findsNothing);
      },
    );

    testWidgets(
      'should display loading indicator when state is BagLoading',
      (tester) async {
        when(() => mockBagBloc.state).thenReturn(const BagLoading());
        when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: VirtualBagScreen(
              bagBloc: mockBagBloc,
              healthSyncService: fakeHealth,
            ),
          ),
        );

        expect(
          find.byKey(VirtualBagScreen.keyLoadingIndicator),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should display error message and reload button when state is BagError',
      (tester) async {
        when(() => mockBagBloc.state).thenReturn(
          const BagError('Failed to load virtual bag: connection error'),
        );
        when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: VirtualBagScreen(
              bagBloc: mockBagBloc,
              healthSyncService: fakeHealth,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Failed to load virtual bag: connection error'),
          findsOneWidget,
        );
        expect(find.text('Reload Bag'), findsOneWidget);

        await tester.tap(find.text('Reload Bag'));
        verify(() => mockBagBloc.add(const LoadBag())).called(1);
      },
    );

    testWidgets(
      'should display UNSTRUNG status for racquet without active string job',
      (tester) async {
        final unstrungRacquet = Racquet(
          id: 99,
          userId: 1,
          name: 'Pro Staff 97',
          brand: 'Wilson',
          model: 'Pro Staff',
          isPrimary: false,
          activeStringJob: null,
          createdAt: DateTime.utc(2026, 9, 25),
          updatedAt: DateTime.utc(2026, 9, 25),
        );

        when(() => mockBagBloc.state).thenReturn(BagLoaded([unstrungRacquet]));
        when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: VirtualBagScreen(
              bagBloc: mockBagBloc,
              healthSyncService: fakeHealth,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pro Staff 97'), findsOneWidget);
        expect(find.text('No string mounted'), findsOneWidget);
        expect(find.text('UNSTRUNG'), findsOneWidget);
        expect(find.text('--'), findsOneWidget);
      },
    );
  });

  group('Story 3.3: Judge Simulation Badge', () {
    Future<void> pumpBag(
      WidgetTester tester,
      FakeHealthSyncService service, {
      BagState state = const BagLoaded([]),
    }) async {
      when(() => mockBagBloc.state).thenReturn(state);
      when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());
      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: VirtualBagScreen(
            bagBloc: mockBagBloc,
            healthSyncService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'shows the simulate badge when the service supports simulation',
      (tester) async {
        final service = FakeHealthSyncService(supportsSimulation: true);
        addTearDown(service.dispose);

        await pumpBag(tester, service, state: BagLoaded(sampleRacquets));

        expect(
          find.byKey(VirtualBagScreen.keySimulateWorkoutBadge),
          findsOneWidget,
        );
        expect(find.text('🧪 Simulate Workout'), findsOneWidget);
        // Coexists with the Add Racquet FAB.
        expect(find.byKey(const Key('virtual_bag_fab_add')), findsOneWidget);
      },
    );

    testWidgets('hides the simulate badge on native services', (tester) async {
      await pumpBag(tester, fakeHealth, state: BagLoaded(sampleRacquets));

      expect(
        find.byKey(VirtualBagScreen.keySimulateWorkoutBadge),
        findsNothing,
      );
    });

    testWidgets(
      'tapping the badge simulates a workout and surfaces the detection',
      (tester) async {
        final service = FakeHealthSyncService(supportsSimulation: true);
        addTearDown(service.dispose);

        await pumpBag(tester, service);

        await tester.tap(find.byKey(VirtualBagScreen.keySimulateWorkoutBadge));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750));

        expect(service.simulateCalls, 1);
        expect(service.pendingWorkouts, hasLength(1));
        expect(find.text('1h 30m Tennis Match Detected'), findsOneWidget);
      },
    );

    testWidgets('pulls workouts from the service when the bag opens', (
      tester,
    ) async {
      await pumpBag(tester, fakeHealth);

      expect(fakeHealth.syncCalls, 1);
    });

    DetectedWorkout workout(String id, {int minutes = 90}) => DetectedWorkout(
      externalWorkoutId: id,
      startTime: DateTime.utc(2026, 10, 4, 16, 30),
      durationMinutes: minutes,
      source: DetectedWorkout.sourceHealthKit,
    );

    testWidgets(
      'a sync detecting 3 workouts shows one "3 Tennis Matches Detected" '
      'SnackBar',
      (tester) async {
        fakeHealth.nextSyncBatch = [
          workout('hk-1'),
          workout('hk-2', minutes: 60),
          workout('hk-3', minutes: 45),
        ];

        await pumpBag(tester, fakeHealth);

        expect(find.text('3 Tennis Matches Detected'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.textContaining('Tennis Match Detected'), findsNothing);

        // Nothing else is queued behind it.
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(seconds: 1));
        }
        expect(find.byType(SnackBar), findsNothing);
      },
    );

    testWidgets(
      'a detection in a later frame replaces the current SnackBar immediately',
      (tester) async {
        await pumpBag(tester, fakeHealth);

        fakeHealth.emit(workout('hk-1', minutes: 60));
        await tester.pumpAndSettle();
        expect(find.text('1h Tennis Match Detected'), findsOneWidget);

        fakeHealth.emit(workout('hk-2', minutes: 45));
        // Well before the first SnackBar's 4s timeout.
        await tester.pumpAndSettle();
        expect(find.text('1h Tennis Match Detected'), findsNothing);
        expect(find.text('45m Tennis Match Detected'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );
  });

  group('formatWorkoutDuration', () {
    const cases = {
      45: '45m',
      60: '1h',
      90: '1h 30m',
      120: '2h',
      135: '2h 15m',
    };
    cases.forEach((minutes, expected) {
      test('$minutes min -> $expected', () {
        expect(VirtualBagScreen.formatWorkoutDuration(minutes), expected);
      });
    });
  });
}
