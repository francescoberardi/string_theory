import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/bloc/bag_error_messages.dart';
import 'package:string_theory_flutter/screens/sessions_screen.dart';
import 'package:string_theory_flutter/screens/virtual_bag_screen.dart';
import 'package:string_theory_flutter/services/health/health_sync_service.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/add_racquet_modal.dart';
import 'package:string_theory_flutter/widgets/workout_assignment_sheet.dart';

import 'helpers/fake_health_sync_service.dart';

class MockBagBloc extends Mock implements BagBloc {}

void main() {
  late MockBagBloc mockBagBloc;
  late FakeHealthSyncService fakeHealth;

  final sampleRacquets = [
    Racquet(
      id: 1,
      userId: Namespace.nil.uuidValue,
      name: 'Wilson Blade 98',
      brand: 'Wilson',
      model: 'Blade 98',
      isPrimary: true,
      activeStringJob: StringJob(
        id: 1,
        userId: Namespace.nil.uuidValue,
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
      userId: Namespace.nil.uuidValue,
      name: 'Babolat Pure Drive',
      brand: 'Babolat',
      model: 'Pure Drive',
      isPrimary: false,
      activeStringJob: StringJob(
        id: 2,
        userId: Namespace.nil.uuidValue,
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
      userId: Namespace.nil.uuidValue,
      name: 'Head Radical MP',
      brand: 'Head',
      model: 'Radical MP',
      isPrimary: false,
      activeStringJob: StringJob(
        id: 3,
        userId: Namespace.nil.uuidValue,
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
        expect(find.byKey(VirtualBagScreen.keyNavigationDrawer), findsNothing);
      },
    );

    testWidgets(
      '[P0] AC-5 should display adaptive 2-column grid with NavigationRail on tablet screen width (600–1024dp)',
      (tester) async {
        // Configure tablet screen size (e.g. 800 x 1000)
        tester.view.physicalSize = const Size(800, 1000);
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

        // Criterion-defining primary assertion: 2-column grid is rendered on tablet
        expect(
          find.byKey(VirtualBagScreen.keyRacquetGrid),
          findsOneWidget,
          reason: 'Tablet screen must render racquets in a multi-column grid',
        );

        expect(find.byType(RacquetCard), findsNWidgets(sampleRacquets.length));
        expect(find.text('Wilson Blade 98'), findsOneWidget);

        // NavigationRail is visible on tablet
        expect(find.byKey(VirtualBagScreen.keyNavigationRail), findsOneWidget);
        expect(find.byKey(VirtualBagScreen.keyBottomNav), findsNothing);
        expect(find.byKey(VirtualBagScreen.keyNavigationDrawer), findsNothing);

        final grid = tester.widget<GridView>(
          find.byKey(VirtualBagScreen.keyRacquetGrid),
        );
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, 2);
      },
    );

    testWidgets(
      '[P0] AC-6 should display persistent NavigationDrawer with 3-column grid on desktop/web screen width (>1024dp)',
      (tester) async {
        // Configure desktop screen size (e.g. 1280 x 900)
        tester.view.physicalSize = const Size(1280, 900);
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

        // Persistent NavigationDrawer is visible on desktop (>1024dp)
        expect(
          find.byKey(VirtualBagScreen.keyNavigationDrawer),
          findsOneWidget,
        );
        expect(find.byKey(VirtualBagScreen.keyNavigationRail), findsNothing);
        expect(find.byKey(VirtualBagScreen.keyBottomNav), findsNothing);

        // Header branding
        expect(find.text('STRING THEORY'), findsOneWidget);

        // 3-column grid is rendered
        expect(find.byKey(VirtualBagScreen.keyRacquetGrid), findsOneWidget);
        final grid = tester.widget<GridView>(
          find.byKey(VirtualBagScreen.keyRacquetGrid),
        );
        final delegate =
            grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, 3);
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
          const BagError(
            "Couldn't load your bag. Check your connection and try again.",
          ),
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
          find.text(
            "Couldn't load your bag. Check your connection and try again.",
          ),
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
          userId: Namespace.nil.uuidValue,
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
        // Coexists with the Add Racquet FAB and Log Session FAB.
        expect(find.byKey(VirtualBagScreen.keyLogSessionFab), findsOneWidget);
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

  group('Story 3.4: Quick Logger FAB & Workout Assignment Sheet Launch', () {
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
      'renders [+ Log Session] FAB when racquets exist and coexists with Add Racquet FAB',
      (tester) async {
        await pumpBag(tester, fakeHealth, state: BagLoaded(sampleRacquets));

        expect(find.byKey(VirtualBagScreen.keyLogSessionFab), findsOneWidget);
        expect(find.text('+ Log Session'), findsOneWidget);
        expect(find.byKey(const Key('virtual_bag_fab_add')), findsOneWidget);
      },
    );

    testWidgets(
      'does not render [+ Log Session] FAB when bag is empty',
      (tester) async {
        await pumpBag(tester, fakeHealth, state: const BagLoaded([]));

        expect(find.byKey(VirtualBagScreen.keyLogSessionFab), findsNothing);
      },
    );

    testWidgets(
      'tapping [+ Log Session] FAB opens WorkoutAssignmentSheet in manual mode',
      (tester) async {
        await pumpBag(tester, fakeHealth, state: BagLoaded(sampleRacquets));

        await tester.tap(find.byKey(VirtualBagScreen.keyLogSessionFab));
        await tester.pumpAndSettle();

        expect(find.text('LOG COURT SESSION'), findsOneWidget);
        expect(
          find.byKey(WorkoutAssignmentSheet.keyDurationChip('1h')),
          findsOneWidget,
        );
        expect(
          find.byKey(WorkoutAssignmentSheet.keyConfirmButton),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'when workout is detected and racquets exist, automatically opens assignment sheet with Assign action on SnackBar',
      (tester) async {
        await pumpBag(tester, fakeHealth, state: BagLoaded(sampleRacquets));

        fakeHealth.emit(
          DetectedWorkout(
            externalWorkoutId: 'sim-auto-1',
            startTime: DateTime.utc(2026, 10, 4, 17, 0),
            durationMinutes: 90,
            source: DetectedWorkout.sourceSimulated,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1h 30m Tennis Match Detected'), findsOneWidget);
        expect(find.text('Assign'), findsOneWidget);
        expect(find.text('ASSIGN WORKOUT'), findsOneWidget);
        expect(
          find.byKey(WorkoutAssignmentSheet.keyConfirmButton),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping Assign SnackBar action launches workout assignment sheet and dismisses SnackBar',
      (tester) async {
        await pumpBag(tester, fakeHealth, state: BagLoaded(sampleRacquets));

        fakeHealth.emit(
          DetectedWorkout(
            externalWorkoutId: 'sim-auto-2',
            startTime: DateTime.utc(2026, 10, 4, 17, 0),
            durationMinutes: 60,
            source: DetectedWorkout.sourceSimulated,
          ),
        );
        await tester.pumpAndSettle();

        // Dismiss the auto-opened sheet by tapping barrier
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        expect(find.text('ASSIGN WORKOUT'), findsNothing);
        expect(find.text('Assign'), findsOneWidget);

        // Tap Assign in SnackBar
        await tester.tap(find.text('Assign'));
        await tester.pumpAndSettle();

        expect(find.text('ASSIGN WORKOUT'), findsOneWidget);
        expect(
          find.byKey(WorkoutAssignmentSheet.keyConfirmButton),
          findsOneWidget,
        );
      },
    );

    DetectedWorkout detected(String id, {int minutes = 60}) => DetectedWorkout(
      externalWorkoutId: id,
      startTime: DateTime.utc(2026, 10, 4, 17, 0),
      durationMinutes: minutes,
      source: DetectedWorkout.sourceSimulated,
    );

    testWidgets(
      'confirming the auto-opened sheet logs the session and clears the pending workout once logged',
      (tester) async {
        await pumpBag(tester, fakeHealth, state: BagLoaded(sampleRacquets));

        fakeHealth.emit(detected('sim-confirm-1', minutes: 90));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(WorkoutAssignmentSheet.keyConfirmButton));
        await tester.pumpAndSettle();

        final logged =
            verify(
                  () => mockBagBloc.add(captureAny(that: isA<LogSession>())),
                ).captured.single
                as LogSession;
        expect(logged.externalWorkoutId, 'sim-confirm-1');
        expect(logged.racquetId, sampleRacquets.first.id);
        expect(fakeHealth.pendingWorkouts, hasLength(1));

        logged.onLogged!();
        expect(fakeHealth.pendingWorkouts, isEmpty);
      },
    );

    testWidgets(
      'a second detection while a sheet is open does not stack another sheet',
      (tester) async {
        await pumpBag(tester, fakeHealth, state: BagLoaded(sampleRacquets));

        fakeHealth.emit(detected('sim-a'));
        await tester.pumpAndSettle();
        expect(find.text('ASSIGN WORKOUT'), findsOneWidget);

        fakeHealth.emit(detected('sim-b', minutes: 45));
        await tester.pumpAndSettle();

        expect(find.text('ASSIGN WORKOUT'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Assign with an empty bag prompts the user to add a racquet',
      (tester) async {
        await pumpBag(tester, fakeHealth, state: const BagLoaded([]));

        fakeHealth.emit(detected('sim-empty'));
        await tester.pumpAndSettle();
        expect(find.text('ASSIGN WORKOUT'), findsNothing);

        await tester.tap(find.text('Assign'));
        await tester.pumpAndSettle();

        expect(
          find.text('Please add a racquet to your bag first'),
          findsOneWidget,
        );
        expect(find.text('ASSIGN WORKOUT'), findsNothing);
      },
    );

    testWidgets(
      'does not auto-open the sheet while the Sessions tab is selected',
      (tester) async {
        await pumpBag(tester, fakeHealth, state: BagLoaded(sampleRacquets));

        await tester.tap(find.text('Sessions'));
        await tester.pumpAndSettle();

        fakeHealth.emit(detected('sim-tab'));
        await tester.pumpAndSettle();

        expect(find.text('ASSIGN WORKOUT'), findsNothing);
        expect(find.text('1h Tennis Match Detected'), findsOneWidget);
      },
    );

    testWidgets(
      'does not auto-open the sheet over another route',
      (tester) async {
        await pumpBag(tester, fakeHealth, state: BagLoaded(sampleRacquets));

        unawaited(
          tester
              .state<NavigatorState>(find.byType(Navigator))
              .push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Other Route')),
                ),
              ),
        );
        await tester.pumpAndSettle();

        fakeHealth.emit(detected('sim-covered'));
        await tester.pumpAndSettle();

        expect(find.text('Other Route'), findsOneWidget);
        expect(find.text('ASSIGN WORKOUT'), findsNothing);
      },
    );

    testWidgets(
      'surfaces transient errorMessage in BagLoaded via SnackBar without fatal error screen',
      (tester) async {
        final stateController = StreamController<BagState>.broadcast();
        when(() => mockBagBloc.state).thenReturn(BagLoaded(sampleRacquets));
        when(
          () => mockBagBloc.stream,
        ).thenAnswer((_) => stateController.stream);

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

        // Emit failure with transient errorMessage while retaining racquets
        stateController.add(
          BagLoaded(
            sampleRacquets,
            errorMessage: "Couldn't log this session. Please try again.",
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text("Couldn't log this session. Please try again."),
          findsOneWidget,
        );
        // Racquets are still displayed
        expect(find.text('Wilson Blade 98'), findsOneWidget);
        // Fatal error screen is NOT displayed
        expect(find.byIcon(Icons.error_outline), findsNothing);

        await stateController.close();
      },
    );
  });

  group('Story 3.5: Offline session feedback & pending sync indicator', () {
    Future<StreamController<BagState>> pumpWithStream(
      WidgetTester tester,
      BagState initial, {
      Size size = const Size(400, 800),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final controller = StreamController<BagState>.broadcast();
      addTearDown(controller.close);
      when(() => mockBagBloc.state).thenReturn(initial);
      when(() => mockBagBloc.stream).thenAnswer((_) => controller.stream);
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
      return controller;
    }

    testWidgets(
      'shows an informational SnackBar when a session is saved offline',
      (tester) async {
        final controller = await pumpWithStream(
          tester,
          BagLoaded(sampleRacquets),
        );

        final offlineState = BagLoaded(
          sampleRacquets,
          infoMessage: BagBloc.offlineSavedMessage,
          pendingSyncCount: 1,
        );
        when(() => mockBagBloc.state).thenReturn(offlineState);
        controller.add(offlineState);
        await tester.pumpAndSettle();

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.backgroundColor, CourtMidnightTheme.surface);
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.text(
              'Session saved offline. Will sync when back online.',
            ),
          ),
          findsOneWidget,
        );
        // Not treated as a failure.
        expect(find.byIcon(Icons.error_outline), findsNothing);
        expect(find.text('Wilson Blade 98'), findsOneWidget);
      },
    );

    testWidgets('shows a confirmation SnackBar after syncing', (tester) async {
      final controller = await pumpWithStream(
        tester,
        BagLoaded(sampleRacquets, pendingSyncCount: 2),
      );

      final synced = BagLoaded(
        sampleRacquets,
        infoMessage: 'Synced 2 offline sessions',
      );
      when(() => mockBagBloc.state).thenReturn(synced);
      controller.add(synced);
      await tester.pumpAndSettle();

      expect(find.text('Synced 2 offline sessions'), findsOneWidget);
      expect(find.byKey(VirtualBagScreen.keyPendingSyncBanner), findsNothing);
    });

    testWidgets(
      'displays the pending sync banner while sessions are queued',
      (tester) async {
        await pumpWithStream(
          tester,
          BagLoaded(sampleRacquets, pendingSyncCount: 2),
        );

        final banner = find.byKey(VirtualBagScreen.keyPendingSyncBanner);
        expect(banner, findsOneWidget);
        expect(
          find.descendant(
            of: banner,
            matching: find.text('2 sessions waiting to sync'),
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
        expect(
          find.bySemanticsLabel(
            RegExp('2 sessions saved offline, waiting to sync'),
          ),
          findsOneWidget,
        );
        expect(find.text('Wilson Blade 98'), findsOneWidget);
      },
    );

    testWidgets('uses singular wording for one queued session', (
      tester,
    ) async {
      await pumpWithStream(
        tester,
        BagLoaded(sampleRacquets, pendingSyncCount: 1),
      );

      expect(find.text('1 session waiting to sync'), findsOneWidget);
    });

    testWidgets('displays the banner on the tablet grid layout', (
      tester,
    ) async {
      await pumpWithStream(
        tester,
        BagLoaded(sampleRacquets, pendingSyncCount: 1),
        size: const Size(1024, 800),
      );

      expect(find.byKey(VirtualBagScreen.keyRacquetGrid), findsOneWidget);
      expect(
        find.byKey(VirtualBagScreen.keyPendingSyncBanner),
        findsOneWidget,
      );
    });

    testWidgets('hides the banner when nothing is queued', (tester) async {
      await pumpWithStream(tester, BagLoaded(sampleRacquets));

      expect(find.byKey(VirtualBagScreen.keyPendingSyncBanner), findsNothing);
    });
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

  group('Epic 3 retro 3: wiring of extracted bag widgets', () {
    // Enough racquets to overflow the viewport so pull-to-refresh can engage.
    final manyRacquets = List.generate(
      24,
      (i) => sampleRacquets.first.copyWith(id: 100 + i, name: 'Racquet $i'),
    );

    Future<void> pumpBag(
      WidgetTester tester,
      BagState state, {
      Size size = const Size(400, 800),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(() => mockBagBloc.state).thenReturn(state);
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
    }

    testWidgets('pull-to-refresh on the mobile list dispatches LoadBag', (
      tester,
    ) async {
      await pumpBag(tester, BagLoaded(manyRacquets));

      await tester.fling(
        find.byKey(VirtualBagScreen.keyRacquetList),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      verify(() => mockBagBloc.add(const LoadBag())).called(1);
    });

    testWidgets('pull-to-refresh on the tablet grid dispatches LoadBag', (
      tester,
    ) async {
      await pumpBag(
        tester,
        BagLoaded(manyRacquets),
        size: const Size(900, 1200),
      );

      await tester.fling(
        find.byKey(VirtualBagScreen.keyRacquetGrid),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      verify(() => mockBagBloc.add(const LoadBag())).called(1);
    });

    testWidgets('tapping the Add Racquet FAB opens AddRacquetModal', (
      tester,
    ) async {
      // Default test surface: the modal header overflows the 400dp phone width
      // under the test font, which is unrelated to the FAB wiring under test.
      await pumpBag(
        tester,
        BagLoaded(sampleRacquets),
        size: const Size(800, 600),
      );
      expect(find.byType(AddRacquetModal), findsNothing);

      await tester.tap(find.byKey(const Key('virtual_bag_fab_add')));
      await tester.pumpAndSettle();

      expect(find.byType(AddRacquetModal), findsOneWidget);
    });

    testWidgets(
      'navigation rail switches between Bag and Sessions screen',
      (tester) async {
        await pumpBag(
          tester,
          BagLoaded(sampleRacquets),
          size: const Size(900, 1200),
        );
        final rail = find.byKey(VirtualBagScreen.keyNavigationRail);
        NavigationRail railWidget() =>
            tester.widget<NavigationRail>(find.byType(NavigationRail));

        expect(railWidget().selectedIndex, 0);
        expect(find.byType(SessionsScreen), findsNothing);

        await tester.tap(
          find.descendant(of: rail, matching: find.text('Sessions')),
        );
        await tester.pumpAndSettle();

        expect(railWidget().selectedIndex, 1);
        expect(find.byType(SessionsScreen), findsOneWidget);
        expect(find.byKey(SessionsScreen.keySessionsScreen), findsOneWidget);
        expect(find.byKey(VirtualBagScreen.keyRacquetGrid), findsNothing);

        await tester.tap(find.descendant(of: rail, matching: find.text('Bag')));
        await tester.pumpAndSettle();

        expect(railWidget().selectedIndex, 0);
        expect(find.byType(SessionsScreen), findsNothing);
        expect(find.byKey(VirtualBagScreen.keyRacquetGrid), findsOneWidget);
      },
    );

    testWidgets(
      'bottom navigation switches between Bag and Sessions screen',
      (tester) async {
        await pumpBag(tester, BagLoaded(sampleRacquets));
        final nav = find.byKey(VirtualBagScreen.keyBottomNav);

        await tester.tap(
          find.descendant(of: nav, matching: find.text('Sessions')),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SessionsScreen), findsOneWidget);
        expect(find.byKey(SessionsScreen.keySessionsScreen), findsOneWidget);
        expect(find.textContaining('Epic'), findsNothing);
        expect(find.textContaining('coming soon'), findsNothing);
        expect(find.byKey(VirtualBagScreen.keyRacquetList), findsNothing);

        await tester.tap(find.descendant(of: nav, matching: find.text('Bag')));
        await tester.pumpAndSettle();

        expect(find.byType(SessionsScreen), findsNothing);
        expect(find.byKey(VirtualBagScreen.keyRacquetList), findsOneWidget);
      },
    );
  });

  group('Story 4.2: Restrung Today', () {
    Future<StreamController<BagState>> pumpWithStream(
      WidgetTester tester,
      BagState initial,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final controller = StreamController<BagState>.broadcast();
      addTearDown(controller.close);
      when(() => mockBagBloc.state).thenReturn(initial);
      when(() => mockBagBloc.stream).thenAnswer((_) => controller.stream);
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
      return controller;
    }

    testWidgets('shows the green celebratory toast once the server confirms', (
      tester,
    ) async {
      final controller = await pumpWithStream(
        tester,
        BagLoaded(sampleRacquets),
      );

      final restrung = BagLoaded(
        sampleRacquets,
        successMessage: BagBloc.restringSuccessMessage,
      );
      when(() => mockBagBloc.state).thenReturn(restrung);
      controller.add(restrung);
      await tester.pumpAndSettle();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, CourtMidnightTheme.healthOptimal);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text(
            'Fresh stringbed mounted! Restrung to 100% health.',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows no success toast for an ordinary state', (tester) async {
      await pumpWithStream(tester, BagLoaded(sampleRacquets));

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets(
      'tapping Restrung Today then Keep Same dispatches RestringRacquet for that racquet',
      (tester) async {
        await pumpWithStream(tester, BagLoaded(sampleRacquets));

        // Head Radical MP is the 34% (dead) racquet, third in the list.
        final button = find.byKey(RacquetCard.restrungTodayKey(3));
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Keep Same & Reset'));
        await tester.pumpAndSettle();

        verify(
          () => mockBagBloc.add(const RestringRacquet(3, keepSame: true)),
        ).called(1);
      },
    );
  });

  group(
    'Story 5.1: Multi-Platform Responsive Layout (NavigationRail & Desktop Grid)',
    () {
      testWidgets(
        'navigation drawer switches between Bag and Sessions placeholder',
        (tester) async {
          tester.view.physicalSize = const Size(1280, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          when(() => mockBagBloc.state).thenReturn(BagLoaded(sampleRacquets));
          when(
            () => mockBagBloc.stream,
          ).thenAnswer((_) => const Stream.empty());

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

          final drawer = find.byKey(VirtualBagScreen.keyNavigationDrawer);
          expect(find.byType(SessionsScreen), findsNothing);
          expect(find.byKey(VirtualBagScreen.keyRacquetGrid), findsOneWidget);

          await tester.tap(
            find.descendant(of: drawer, matching: find.text('Sessions')),
          );
          await tester.pumpAndSettle();

          expect(find.byType(SessionsScreen), findsOneWidget);
          expect(find.byKey(SessionsScreen.keySessionsScreen), findsOneWidget);
          expect(find.byKey(VirtualBagScreen.keyRacquetGrid), findsNothing);

          await tester.tap(
            find.descendant(of: drawer, matching: find.text('Bag')),
          );
          await tester.pumpAndSettle();

          expect(find.byType(SessionsScreen), findsNothing);
          expect(find.byKey(VirtualBagScreen.keyRacquetGrid), findsOneWidget);
        },
      );

      testWidgets(
        'dynamic resize between mobile, tablet, and desktop preserves tab selection',
        (tester) async {
          // Start on desktop
          tester.view.physicalSize = const Size(1280, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          when(() => mockBagBloc.state).thenReturn(BagLoaded(sampleRacquets));
          when(
            () => mockBagBloc.stream,
          ).thenAnswer((_) => const Stream.empty());

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

          // Switch to Sessions tab on desktop
          await tester.tap(
            find.descendant(
              of: find.byKey(VirtualBagScreen.keyNavigationDrawer),
              matching: find.text('Sessions'),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(SessionsScreen), findsOneWidget);

          // Resize to tablet (800dp)
          tester.view.physicalSize = const Size(800, 1000);
          await tester.pumpAndSettle();

          expect(
            find.byKey(VirtualBagScreen.keyNavigationRail),
            findsOneWidget,
          );
          expect(
            find.byKey(VirtualBagScreen.keyNavigationDrawer),
            findsNothing,
          );
          expect(find.byType(SessionsScreen), findsOneWidget);

          // Resize to mobile (400dp)
          tester.view.physicalSize = const Size(400, 800);
          await tester.pumpAndSettle();

          expect(find.byKey(VirtualBagScreen.keyBottomNav), findsOneWidget);
          expect(find.byKey(VirtualBagScreen.keyNavigationRail), findsNothing);
          expect(find.byType(SessionsScreen), findsOneWidget);
        },
      );

      testWidgets(
        'renders centered empty state across all 3 tiers (mobile, tablet, desktop)',
        (tester) async {
          when(() => mockBagBloc.state).thenReturn(const BagLoaded([]));
          when(
            () => mockBagBloc.stream,
          ).thenAnswer((_) => const Stream.empty());

          // Desktop
          tester.view.physicalSize = const Size(1280, 900);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

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
            find.byKey(VirtualBagScreen.keyNavigationDrawer),
            findsOneWidget,
          );
          expect(find.byKey(VirtualBagScreen.keyEmptyState), findsOneWidget);

          // Tablet
          tester.view.physicalSize = const Size(800, 1000);
          await tester.pumpAndSettle();
          expect(
            find.byKey(VirtualBagScreen.keyNavigationRail),
            findsOneWidget,
          );
          expect(find.byKey(VirtualBagScreen.keyEmptyState), findsOneWidget);

          // Mobile
          tester.view.physicalSize = const Size(400, 800);
          await tester.pumpAndSettle();
          expect(find.byKey(VirtualBagScreen.keyBottomNav), findsOneWidget);
          expect(find.byKey(VirtualBagScreen.keyEmptyState), findsOneWidget);
        },
      );
    },
  );

  group(
    'Story 5.2: Keyboard Shortcuts (L, N, S, Esc)',
    () {
      testWidgets('pressing L opens WorkoutAssignmentSheet in manual mode', (
        tester,
      ) async {
        fakeHealth = FakeHealthSyncService(supportsSimulation: true);

        when(() => mockBagBloc.state).thenReturn(BagLoaded(sampleRacquets));
        when(
          () => mockBagBloc.stream,
        ).thenAnswer((_) => const Stream.empty());

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

        expect(find.byType(WorkoutAssignmentSheet), findsNothing);

        // Press 'L'
        await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
        await tester.pumpAndSettle();

        expect(find.byType(WorkoutAssignmentSheet), findsOneWidget);
        expect(find.text('LOG COURT SESSION'), findsOneWidget);
      });

      testWidgets('pressing N opens AddRacquetModal', (tester) async {
        fakeHealth = FakeHealthSyncService(supportsSimulation: true);

        when(() => mockBagBloc.state).thenReturn(BagLoaded(sampleRacquets));
        when(
          () => mockBagBloc.stream,
        ).thenAnswer((_) => const Stream.empty());

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

        expect(find.byType(AddRacquetModal), findsNothing);

        // Press 'N'
        await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
        await tester.pumpAndSettle();

        expect(find.byType(AddRacquetModal), findsOneWidget);
      });

      testWidgets('pressing S triggers workout simulator', (tester) async {
        fakeHealth = FakeHealthSyncService(supportsSimulation: true);

        when(() => mockBagBloc.state).thenReturn(BagLoaded(sampleRacquets));
        when(
          () => mockBagBloc.stream,
        ).thenAnswer((_) => const Stream.empty());

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

        expect(fakeHealth.simulateCalls, 0);

        // Press 'S'
        await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
        await tester.pumpAndSettle();

        expect(fakeHealth.simulateCalls, 1);
      });

      testWidgets('pressing Esc closes open modal/sheet', (tester) async {
        when(() => mockBagBloc.state).thenReturn(BagLoaded(sampleRacquets));
        when(
          () => mockBagBloc.stream,
        ).thenAnswer((_) => const Stream.empty());

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

        // Open AddRacquetModal
        await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
        await tester.pumpAndSettle();
        expect(find.byType(AddRacquetModal), findsOneWidget);

        // Press 'Esc'
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(AddRacquetModal), findsNothing);
      });

      testWidgets(
        'typing l, n, s into a focused text field does NOT trigger root shortcuts',
        (tester) async {
          when(() => mockBagBloc.state).thenReturn(BagLoaded(sampleRacquets));
          when(
            () => mockBagBloc.stream,
          ).thenAnswer((_) => const Stream.empty());

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

          // Open AddRacquetModal first
          await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
          await tester.pumpAndSettle();
          expect(find.byType(AddRacquetModal), findsOneWidget);

          // Focus name field
          await tester.tap(find.byKey(AddRacquetModal.keyNameField));
          await tester.pumpAndSettle();

          // Type 'l' into name field
          await tester.enterText(find.byKey(AddRacquetModal.keyNameField), 'l');
          await tester.pumpAndSettle();

          // WorkoutAssignmentSheet must NOT be opened
          expect(find.byType(WorkoutAssignmentSheet), findsNothing);
          expect(fakeHealth.simulateCalls, 0);
        },
      );
    },
  );

  group('Story 6.1: re-authentication prompt after a 401', () {
    const expired = logSessionExpiredMessage;

    Future<StreamController<BagState>> pumpWithReauth(
      WidgetTester tester,
      Future<bool> Function() onReauthenticate,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final controller = StreamController<BagState>.broadcast();
      addTearDown(controller.close);
      when(() => mockBagBloc.state).thenReturn(BagLoaded(sampleRacquets));
      when(() => mockBagBloc.stream).thenAnswer((_) => controller.stream);
      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: VirtualBagScreen(
            bagBloc: mockBagBloc,
            healthSyncService: fakeHealth,
            onReauthenticate: onReauthenticate,
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.add(
        BagLoaded(sampleRacquets, errorMessage: expired, reauthRequired: true),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('tapping Sign in re-authenticates, then reloads the bag', (
      tester,
    ) async {
      var signIns = 0;
      await pumpWithReauth(tester, () async {
        signIns++;
        return true;
      });

      expect(find.text(expired), findsOneWidget);
      await tester.tap(find.widgetWithText(SnackBarAction, 'Sign in'));
      await tester.pumpAndSettle();

      expect(signIns, 1);
      verify(() => mockBagBloc.add(const LoadBag())).called(1);
    });

    testWidgets('a failed sign-in shows an error and does not reload', (
      tester,
    ) async {
      await pumpWithReauth(tester, () async => throw Exception('offline'));

      await tester.tap(find.widgetWithText(SnackBarAction, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text(VirtualBagScreen.reauthFailedMessage), findsOneWidget);
      verifyNever(() => mockBagBloc.add(any()));
    });

    testWidgets('a sign-in resolving to false shows an error, no reload', (
      tester,
    ) async {
      await pumpWithReauth(tester, () async => false);

      await tester.tap(find.widgetWithText(SnackBarAction, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text(VirtualBagScreen.reauthFailedMessage), findsOneWidget);
      verifyNever(() => mockBagBloc.add(any()));
    });

    testWidgets('an ordinary error SnackBar has no Sign in action', (
      tester,
    ) async {
      final controller = await pumpWithReauth(tester, () async => true);
      ScaffoldMessenger.of(
        tester.element(find.byType(Scaffold).first),
      ).hideCurrentSnackBar();
      await tester.pumpAndSettle();

      controller.add(
        BagLoaded(sampleRacquets, errorMessage: "Couldn't log this session."),
      );
      await tester.pumpAndSettle();

      expect(find.text("Couldn't log this session."), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Sign in'), findsNothing);
    });
  });
}
