import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/screens/virtual_bag_screen.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/bag/sessions_placeholder.dart';
import 'package:string_theory_flutter/widgets/workout_assignment_sheet.dart';

import '../helpers/fake_health_sync_service.dart';
import '../helpers/tdd_red_phase.dart';

class MockBagBloc extends Mock implements BagBloc {}

class MockClient extends Mock implements Client {}

class MockEndpointSession extends Mock implements EndpointSession {}

void main() {
  group('Story 6.4: Dedicated Sessions History Screen (AC-1, AC-2, AC-3)', () {
    late MockBagBloc mockBagBloc;
    late MockClient mockClient;
    late MockEndpointSession mockSessionEndpoint;
    late FakeHealthSyncService fakeHealthService;

    final sampleRacquet = Racquet(
      id: 1,
      userId: Namespace.nil.uuidValue,
      name: 'Wilson Blade 98',
      brand: 'Wilson',
      model: 'Blade 98',
      isPrimary: true,
      activeStringJob: StringJob(
        id: 101,
        userId: Namespace.nil.uuidValue,
        racquetId: 1,
        materialCategory: StringMaterialCategory.coPoly,
        brand: 'Luxilon',
        model: 'ALU Power',
        stringingDate: DateTime.utc(2026, 9, 20),
        installedTension: 52.0,
        maxRatedHours: 20.0,
        totalCourtHours: 6.5,
        currentHealthScore: 78,
        isActive: true,
        createdAt: DateTime.utc(2026, 9, 20),
      ),
      createdAt: DateTime.utc(2026, 9, 20),
      updatedAt: DateTime.utc(2026, 9, 20),
    );

    final session1 = SessionLog(
      id: 101,
      userId: Namespace.nil.uuidValue,
      racquetId: 1,
      startTime: DateTime.utc(2026, 10, 12, 14, 0),
      durationMinutes: 90,
      courtSurface: 'hard',
      notes: 'Practice rally with coach',
      source: 'manual',
      createdAt: DateTime.utc(2026, 10, 12, 15, 30),
    );

    final session2 = SessionLog(
      id: 102,
      userId: Namespace.nil.uuidValue,
      racquetId: 1,
      startTime: DateTime.utc(2026, 10, 10, 10, 30),
      durationMinutes: 60,
      courtSurface: 'clay',
      notes: 'Club league match',
      source: 'apple_health',
      createdAt: DateTime.utc(2026, 10, 10, 11, 30),
    );

    setUp(() {
      mockBagBloc = MockBagBloc();
      mockClient = MockClient();
      mockSessionEndpoint = MockEndpointSession();
      fakeHealthService = FakeHealthSyncService();

      when(() => mockBagBloc.state).thenReturn(BagLoaded([sampleRacquet]));
      when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockBagBloc.client).thenReturn(mockClient);
      when(() => mockClient.session).thenReturn(mockSessionEndpoint);
      when(
        () => mockSessionEndpoint.getSessionLogs(
          racquetId: any(named: 'racquetId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [session1, session2]);
    });

    tearDown(() {
      fakeHealthService.dispose();
    });

    Future<void> pumpBag(
      WidgetTester tester, {
      Size size = const Size(390, 844),
      List<Racquet>? racquets,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      if (racquets != null) {
        when(() => mockBagBloc.state).thenReturn(BagLoaded(racquets));
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: VirtualBagScreen(
            bagBloc: mockBagBloc,
            healthSyncService: fakeHealthService,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      '[P2] [AC-1] selecting Sessions tab renders dedicated SessionsScreen and replaces SessionsPlaceholder across navigation modalities',
      skip: tddRedPhase64,
      (tester) async {
        await pumpBag(tester, size: const Size(390, 844));
        final nav = find.byKey(VirtualBagScreen.keyBottomNav);
        expect(nav, findsOneWidget);

        // Switch to Sessions tab
        await tester.tap(
          find.descendant(of: nav, matching: find.text('Sessions')),
        );
        await tester.pumpAndSettle();

        // Criterion-defining assertion: SessionsPlaceholder is removed and replaced by dedicated SessionsScreen
        expect(
          find.byType(SessionsPlaceholder),
          findsNothing,
          reason:
              'SessionsPlaceholder must be replaced by dedicated SessionsScreen',
        );
        expect(
          find.text('COURT SESSIONS'),
          findsNothing,
          reason: 'Placeholder title must no longer be rendered',
        );
        expect(
          find.byKey(const Key('sessions_screen')),
          findsOneWidget,
          reason:
              'Dedicated SessionsScreen must be rendered when Sessions tab is selected',
        );
      },
    );

    testWidgets(
      '[P2] [AC-2] displays chronological list of logged sessions with date, duration, racquet name, and court hours added',
      skip: tddRedPhase64,
      (tester) async {
        await pumpBag(tester, size: const Size(390, 844));
        final nav = find.byKey(VirtualBagScreen.keyBottomNav);

        await tester.tap(
          find.descendant(of: nav, matching: find.text('Sessions')),
        );
        await tester.pumpAndSettle();

        // Criterion-defining assertion: list view of sessions is rendered
        expect(
          find.byKey(const Key('sessions_list_view')),
          findsOneWidget,
          reason:
              'SessionsScreen must render a list view of chronological sessions',
        );

        // Verifies session cards with racquet name, duration, and court hours added
        expect(find.text('Wilson Blade 98'), findsWidgets);
        expect(find.text('90 min'), findsOneWidget);
        expect(find.text('+1.5 hrs'), findsOneWidget);
        expect(find.text('60 min'), findsOneWidget);
        expect(find.text('+1.0 hrs'), findsOneWidget);
      },
    );

    testWidgets(
      '[P2] [AC-3] provides prominent [+ Log Session] action button that triggers quick-log workout assignment sheet',
      skip: tddRedPhase64,
      (tester) async {
        await pumpBag(tester, size: const Size(390, 844));
        final nav = find.byKey(VirtualBagScreen.keyBottomNav);

        await tester.tap(
          find.descendant(of: nav, matching: find.text('Sessions')),
        );
        await tester.pumpAndSettle();

        // Criterion-defining assertion: prominent [+ Log Session] action button exists on Sessions tab
        final logButton = find.byKey(const Key('sessions_log_session_button'));
        expect(
          logButton,
          findsOneWidget,
          reason:
              'SessionsScreen must provide a prominent [+ Log Session] action button',
        );

        await tester.tap(logButton);
        await tester.pumpAndSettle();

        expect(
          find.byType(WorkoutAssignmentSheet),
          findsOneWidget,
          reason:
              'Tapping [+ Log Session] must open the manual workout assignment sheet',
        );
      },
    );

    testWidgets(
      '[Edge] displays empty state guidance and log session button when no sessions are logged',
      skip: tddRedPhase64,
      (tester) async {
        when(
          () => mockSessionEndpoint.getSessionLogs(
            racquetId: any(named: 'racquetId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => []);

        await pumpBag(tester, size: const Size(390, 844));
        final nav = find.byKey(VirtualBagScreen.keyBottomNav);
        await tester.tap(
          find.descendant(of: nav, matching: find.text('Sessions')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sessions_empty_state')), findsOneWidget);
        expect(find.text('NO SESSIONS LOGGED'), findsOneWidget);
        expect(
          find.byKey(const Key('sessions_log_session_button')),
          findsOneWidget,
        );

        // Tapping log button in empty state opens WorkoutAssignmentSheet
        await tester.tap(find.byKey(const Key('sessions_log_session_button')));
        await tester.pumpAndSettle();
        expect(find.byType(WorkoutAssignmentSheet), findsOneWidget);
      },
    );

    testWidgets(
      '[Edge] displays error state with retry button on network failure',
      skip: tddRedPhase64,
      (tester) async {
        when(
          () => mockSessionEndpoint.getSessionLogs(
            racquetId: any(named: 'racquetId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenThrow(Exception('Network error'));

        await pumpBag(tester, size: const Size(390, 844));
        final nav = find.byKey(VirtualBagScreen.keyBottomNav);
        await tester.tap(
          find.descendant(of: nav, matching: find.text('Sessions')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Failed to load sessions. Please try again.'), findsOneWidget);
        final retryButton = find.byKey(const Key('sessions_retry_button'));
        expect(retryButton, findsOneWidget);

        // Now configure success and tap retry
        when(
          () => mockSessionEndpoint.getSessionLogs(
            racquetId: any(named: 'racquetId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => [session1]);

        await tester.tap(retryButton);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sessions_list_view')), findsOneWidget);
        expect(find.text('Wilson Blade 98'), findsOneWidget);
      },
    );

    testWidgets(
      '[Edge] sorts sessions in reverse-chronological order even if API returns ascending order',
      skip: tddRedPhase64,
      (tester) async {
        // Return older session2 (Oct 10) before newer session1 (Oct 12)
        when(
          () => mockSessionEndpoint.getSessionLogs(
            racquetId: any(named: 'racquetId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => [session2, session1]);

        await pumpBag(tester, size: const Size(390, 844));
        final nav = find.byKey(VirtualBagScreen.keyBottomNav);
        await tester.tap(
          find.descendant(of: nav, matching: find.text('Sessions')),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('sessions_list_view')), findsOneWidget);
        // Find session cards by ValueKey
        final card1Pos = tester.getTopLeft(find.byKey(const ValueKey('session_101')));
        final card2Pos = tester.getTopLeft(find.byKey(const ValueKey('session_102')));
        // Newer session (session_101) must be rendered above older session (session_102)
        expect(card1Pos.dy, lessThan(card2Pos.dy));
      },
    );
  });
}
