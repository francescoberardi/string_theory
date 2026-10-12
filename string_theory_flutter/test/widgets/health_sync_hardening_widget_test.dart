import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/screens/virtual_bag_screen.dart';
import 'package:string_theory_flutter/services/health/health_sync_service.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/workout_assignment_sheet.dart';

import '../helpers/fake_health_sync_service.dart';
import '../helpers/tdd_red_phase.dart';

class MockBagBloc extends Mock implements BagBloc {}

void main() {
  group(
    'Story 6.2: Health Ingestion Hardening Widget & Lifecycle Tests (AC-1, AC-3, AC-4)',
    () {
      late MockBagBloc mockBagBloc;
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
          totalCourtHours: 5.0,
          currentHealthScore: 78,
          isActive: true,
          createdAt: DateTime.utc(2026, 9, 20),
        ),
        createdAt: DateTime.utc(2026, 9, 20),
        updatedAt: DateTime.utc(2026, 9, 20),
      );

      setUp(() {
        mockBagBloc = MockBagBloc();
        fakeHealthService = FakeHealthSyncService();
        when(() => mockBagBloc.state).thenReturn(BagLoaded([sampleRacquet]));
        when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());
      });

      tearDown(() {
        fakeHealthService.dispose();
      });

      Widget createBagScreen({HealthSyncService? healthSyncService}) {
        return MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: VirtualBagScreen(
            bagBloc: mockBagBloc,
            healthSyncService: healthSyncService ?? fakeHealthService,
          ),
        );
      }

      testWidgets(
        '[P1] [AC-1] app lifecycle resumed triggers workout sync when 60s cooldown gate has elapsed',
        skip: tddRedPhase,
        (tester) async {
          await tester.pumpWidget(createBagScreen());
          await tester.pumpAndSettle();

          // Initial mount triggers 1 sync.
          expect(fakeHealthService.syncCalls, equals(1));

          // Resumed before 60 seconds (e.g. 10s later) -> cooldown blocks duplicate sync.
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pump(const Duration(seconds: 10));
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();

          expect(
            fakeHealthService.syncCalls,
            equals(1),
            reason:
                'Cooldown gate (60s) must prevent duplicate sync on rapid resume',
          );

          // Resumed after 60 seconds elapsed -> sync executes automatically.
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          await tester.pump(const Duration(seconds: 65));
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();

          expect(
            fakeHealthService.syncCalls,
            equals(2),
            reason:
                'App resuming after cooldown must automatically trigger syncWorkouts()',
          );
        },
      );

      testWidgets(
        '[P1] [AC-3] multiple workouts or arrivals while sheet is active are buffered in FIFO order and presented sequentially',
        skip: tddRedPhase,
        (tester) async {
          await tester.pumpWidget(createBagScreen());
          await tester.pumpAndSettle();

          final workout1 = DetectedWorkout(
            externalWorkoutId: 'batch-workout-1',
            startTime: DateTime.utc(2026, 10, 12, 14, 0),
            durationMinutes: 60,
            source: DetectedWorkout.sourceHealthKit,
          );
          final workout2 = DetectedWorkout(
            externalWorkoutId: 'batch-workout-2',
            startTime: DateTime.utc(2026, 10, 12, 16, 0),
            durationMinutes: 90,
            source: DetectedWorkout.sourceHealthKit,
          );

          // Emit batch of two workouts while on the bag screen.
          fakeHealthService.emit(workout1);
          fakeHealthService.emit(workout2);
          await tester.pumpAndSettle();

          // First workout sheet is displayed.
          expect(find.byType(WorkoutAssignmentSheet), findsOneWidget);
          expect(find.text('1h'), findsOneWidget);

          // Dismiss the first sheet.
          final closeButton = find.byTooltip('Close');
          if (closeButton.evaluate().isNotEmpty) {
            await tester.tap(closeButton);
          } else {
            // Alternatively dismiss sheet by popping route or tapping dismiss
            Navigator.of(
              tester.element(find.byType(WorkoutAssignmentSheet)),
            ).pop();
          }
          await tester.pumpAndSettle();

          // FIFO queue: second workout sheet must now automatically appear!
          expect(
            find.byType(WorkoutAssignmentSheet),
            findsOneWidget,
            reason:
                'Second workout from the FIFO queue must be presented after dismissing the first',
          );
          expect(find.text('1h 30m'), findsOneWidget);
        },
      );

      testWidgets(
        '[P2] [AC-4] missing or denied health permission surfaces clear informational guidance in the UI',
        skip: tddRedPhase,
        (tester) async {
          // Build with denied permissions scenario
          await tester.pumpWidget(createBagScreen());
          await tester.pumpAndSettle();

          // The UI should surface clear guidance when permissions are denied/missing,
          // rather than silently displaying an empty bag with no hint.
          final guidanceFinder = find.textContaining(
            'Health permissions required',
            findRichText: true,
          );

          expect(
            guidanceFinder,
            findsOneWidget,
            reason:
                'UI must surface clear guidance when health permissions are missing or denied',
          );
        },
      );
    },
  );
}
