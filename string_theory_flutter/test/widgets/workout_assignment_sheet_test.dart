import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/services/health/health_sync_service.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/workout_assignment_sheet.dart';

import '../helpers/fake_health_sync_service.dart';

class MockBagBloc extends Mock implements BagBloc {}

class FakeBagEvent extends Fake implements BagEvent {}

void main() {
  late MockBagBloc mockBagBloc;
  late FakeHealthSyncService fakeHealthService;

  final primaryRacquet = Racquet(
    id: 1,
    userId: Namespace.nil.uuidValue,
    name: 'Tour 98',
    brand: 'Baseline',
    model: 'Tour 98',
    isPrimary: true,
    activeStringJob: StringJob(
      id: 101,
      userId: Namespace.nil.uuidValue,
      racquetId: 1,
      materialCategory: StringMaterialCategory.coPoly,
      brand: 'Baseline',
      model: 'Poly Tour',
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

  final secondaryRacquet = Racquet(
    id: 2,
    userId: Namespace.nil.uuidValue,
    name: 'Spin 100',
    brand: 'Baseline',
    model: 'Spin 100',
    isPrimary: false,
    activeStringJob: StringJob(
      id: 102,
      userId: Namespace.nil.uuidValue,
      racquetId: 2,
      materialCategory: StringMaterialCategory.coPoly,
      brand: 'Baseline',
      model: 'Spin Poly',
      stringingDate: DateTime.utc(2026, 9, 10),
      installedTension: 54.0,
      maxRatedHours: 20.0,
      totalCourtHours: 8.0,
      currentHealthScore: 62,
      isActive: true,
      createdAt: DateTime.utc(2026, 9, 10),
    ),
    createdAt: DateTime.utc(2026, 9, 10),
    updatedAt: DateTime.utc(2026, 9, 10),
  );

  final detectedWorkout = DetectedWorkout(
    externalWorkoutId: 'sim-test-123',
    startTime: DateTime.utc(2026, 10, 4, 16, 0),
    durationMinutes: 90,
    source: DetectedWorkout.sourceSimulated,
  );

  setUpAll(() {
    registerFallbackValue(FakeBagEvent());
  });

  setUp(() {
    mockBagBloc = MockBagBloc();
    fakeHealthService = FakeHealthSyncService();
    fakeHealthService.emit(detectedWorkout);
  });

  tearDown(() {
    fakeHealthService.dispose();
  });

  Widget buildDetectedSheet({
    List<Racquet>? racquets,
    DetectedWorkout? workout,
  }) {
    return MaterialApp(
      theme: CourtMidnightTheme.themeData,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                WorkoutAssignmentSheet.showForDetected(
                  context,
                  workout: workout ?? detectedWorkout,
                  racquets: racquets ?? [primaryRacquet, secondaryRacquet],
                  bagBloc: mockBagBloc,
                  healthSyncService: fakeHealthService,
                );
              },
              child: const Text('Open Detected Sheet'),
            );
          },
        ),
      ),
    );
  }

  Widget buildManualSheet({List<Racquet>? racquets}) {
    return MaterialApp(
      theme: CourtMidnightTheme.themeData,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                WorkoutAssignmentSheet.showForManual(
                  context,
                  racquets: racquets ?? [primaryRacquet, secondaryRacquet],
                  bagBloc: mockBagBloc,
                );
              },
              child: const Text('Open Manual Sheet'),
            );
          },
        ),
      ),
    );
  }

  group('Story 3.4: WorkoutAssignmentSheet Detected Workout Mode', () {
    testWidgets(
      'pre-selects primary racquet and enables 1-tap confirmation (<= 2 taps total)',
      (tester) async {
        await tester.pumpWidget(buildDetectedSheet());
        await tester.tap(find.text('Open Detected Sheet'));
        await tester.pumpAndSettle();

        // Sheet is displayed with workout duration and racquet list
        expect(find.text('1h 30m'), findsOneWidget);
        expect(find.text('Tour 98'), findsOneWidget);
        expect(find.text('Spin 100'), findsOneWidget);

        // 1 tap on Confirm dispatches LogSession for primary racquet
        final confirmButton = find.byKey(
          WorkoutAssignmentSheet.keyConfirmButton,
        );
        expect(confirmButton, findsOneWidget);
        await tester.tap(confirmButton);
        await tester.pumpAndSettle();

        final logged =
            verify(
                  () => mockBagBloc.add(captureAny(that: isA<LogSession>())),
                ).captured.single
                as LogSession;
        expect(
          logged,
          LogSession(
            racquetId: primaryRacquet.id!,
            startTime: detectedWorkout.startTime,
            durationMinutes: 90,
            courtSurface: null,
            notes: null,
            source: detectedWorkout.source,
            externalWorkoutId: detectedWorkout.externalWorkoutId,
          ),
        );

        // Workout stays pending until the bloc confirms the log
        expect(fakeHealthService.pendingWorkouts, contains(detectedWorkout));
        logged.onLogged!();
        expect(fakeHealthService.pendingWorkouts, isEmpty);
      },
    );

    testWidgets(
      'keeps the workout pending when the log never succeeds',
      (tester) async {
        await tester.pumpWidget(buildDetectedSheet());
        await tester.tap(find.text('Open Detected Sheet'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(WorkoutAssignmentSheet.keyConfirmButton));
        await tester.pumpAndSettle();

        expect(find.text('ASSIGN WORKOUT'), findsNothing);
        expect(fakeHealthService.pendingWorkouts, contains(detectedWorkout));
      },
    );

    testWidgets(
      'fallbacks to first racquet if no primary is designated',
      (tester) async {
        final nonPrimary1 = primaryRacquet.copyWith(isPrimary: false);
        final nonPrimary2 = secondaryRacquet.copyWith(isPrimary: false);

        await tester.pumpWidget(
          buildDetectedSheet(racquets: [nonPrimary1, nonPrimary2]),
        );
        await tester.tap(find.text('Open Detected Sheet'));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(WorkoutAssignmentSheet.keyConfirmButton));
        await tester.pumpAndSettle();

        verify(
          () => mockBagBloc.add(
            LogSession(
              racquetId: nonPrimary1.id!,
              startTime: detectedWorkout.startTime,
              durationMinutes: 90,
              courtSurface: null,
              notes: null,
              source: detectedWorkout.source,
              externalWorkoutId: detectedWorkout.externalWorkoutId,
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'allows switching to secondary racquet before confirmation (2 taps total)',
      (tester) async {
        await tester.pumpWidget(buildDetectedSheet());
        await tester.tap(find.text('Open Detected Sheet'));
        await tester.pumpAndSettle();

        // Tap secondary racquet
        await tester.tap(
          find.byKey(
            WorkoutAssignmentSheet.keyRacquetTile(secondaryRacquet.id!),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Confirm
        await tester.tap(find.byKey(WorkoutAssignmentSheet.keyConfirmButton));
        await tester.pumpAndSettle();

        verify(
          () => mockBagBloc.add(
            LogSession(
              racquetId: secondaryRacquet.id!,
              startTime: detectedWorkout.startTime,
              durationMinutes: 90,
              courtSurface: null,
              notes: null,
              source: detectedWorkout.source,
              externalWorkoutId: detectedWorkout.externalWorkoutId,
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'expanding [+ Advanced Options] reveals court surfaces and notes text area',
      (tester) async {
        await tester.pumpWidget(buildDetectedSheet());
        await tester.tap(find.text('Open Detected Sheet'));
        await tester.pumpAndSettle();

        // Advanced options start collapsed
        expect(
          find.byKey(WorkoutAssignmentSheet.keySurfaceChip('Clay')),
          findsNothing,
        );
        expect(find.byKey(WorkoutAssignmentSheet.keyNotesField), findsNothing);

        // Tap to expand
        await tester.tap(find.byKey(WorkoutAssignmentSheet.keyAdvancedToggle));
        await tester.pumpAndSettle();

        // Surfaces and notes are now visible
        expect(
          find.byKey(WorkoutAssignmentSheet.keySurfaceChip('Hard')),
          findsOneWidget,
        );
        expect(
          find.byKey(WorkoutAssignmentSheet.keySurfaceChip('Clay')),
          findsOneWidget,
        );
        expect(
          find.byKey(WorkoutAssignmentSheet.keySurfaceChip('Grass')),
          findsOneWidget,
        );
        expect(
          find.byKey(WorkoutAssignmentSheet.keySurfaceChip('Carpet')),
          findsOneWidget,
        );
        expect(
          find.byKey(WorkoutAssignmentSheet.keyNotesField),
          findsOneWidget,
        );

        // Select Clay and enter note
        await tester.tap(
          find.byKey(WorkoutAssignmentSheet.keySurfaceChip('Clay')),
        );
        await tester.enterText(
          find.byKey(WorkoutAssignmentSheet.keyNotesField),
          'Heavy baseline rally against top spin',
        );
        await tester.pumpAndSettle();

        // Tap Confirm
        await tester.tap(find.byKey(WorkoutAssignmentSheet.keyConfirmButton));
        await tester.pumpAndSettle();

        verify(
          () => mockBagBloc.add(
            LogSession(
              racquetId: primaryRacquet.id!,
              startTime: detectedWorkout.startTime,
              durationMinutes: 90,
              courtSurface: 'Clay',
              notes: 'Heavy baseline rally against top spin',
              source: detectedWorkout.source,
              externalWorkoutId: detectedWorkout.externalWorkoutId,
            ),
          ),
        ).called(1);
      },
    );
  });

  group('Story 3.4: WorkoutAssignmentSheet Manual Quick-Logger Mode', () {
    testWidgets(
      'displays duration chips (30m, 1h, 1.5h, 2h) with default 1h, source: manual',
      (tester) async {
        await tester.pumpWidget(buildManualSheet());
        await tester.tap(find.text('Open Manual Sheet'));
        await tester.pumpAndSettle();

        expect(
          find.byKey(WorkoutAssignmentSheet.keyDurationChip('30m')),
          findsOneWidget,
        );
        expect(
          find.byKey(WorkoutAssignmentSheet.keyDurationChip('1h')),
          findsOneWidget,
        );
        expect(
          find.byKey(WorkoutAssignmentSheet.keyDurationChip('1.5h')),
          findsOneWidget,
        );
        expect(
          find.byKey(WorkoutAssignmentSheet.keyDurationChip('2h')),
          findsOneWidget,
        );

        // Tap 1.5h duration chip
        await tester.tap(
          find.byKey(WorkoutAssignmentSheet.keyDurationChip('1.5h')),
        );
        await tester.pumpAndSettle();

        // Confirm
        final before = DateTime.now().toUtc();
        await tester.tap(find.byKey(WorkoutAssignmentSheet.keyConfirmButton));
        final after = DateTime.now().toUtc();
        await tester.pumpAndSettle();

        final captured = verify(
          () => mockBagBloc.add(captureAny(that: isA<LogSession>())),
        ).captured;
        expect(captured, hasLength(1));

        final session = captured.first as LogSession;
        expect(session.racquetId, primaryRacquet.id);
        expect(session.durationMinutes, 90);
        expect(session.source, 'manual');
        expect(session.externalWorkoutId, isNull);
        // A quick log happens after play: the session ended "now".
        const played = Duration(minutes: 90);
        expect(session.startTime.isUtc, isTrue);
        expect(session.startTime.isBefore(before.subtract(played)), isFalse);
        expect(session.startTime.isAfter(after.subtract(played)), isFalse);
      },
    );

    testWidgets(
      'immediately confirms default 1h preset without tapping duration chips',
      (tester) async {
        await tester.pumpWidget(buildManualSheet());
        await tester.tap(find.text('Open Manual Sheet'));
        await tester.pumpAndSettle();

        // Directly tap Confirm
        await tester.tap(find.byKey(WorkoutAssignmentSheet.keyConfirmButton));
        await tester.pumpAndSettle();

        final captured = verify(
          () => mockBagBloc.add(captureAny(that: isA<LogSession>())),
        ).captured;
        expect(captured, hasLength(1));

        final session = captured.first as LogSession;
        expect(session.racquetId, primaryRacquet.id);
        expect(session.durationMinutes, 60);
        expect(session.source, 'manual');
        expect(session.externalWorkoutId, isNull);
      },
    );

    testWidgets(
      'empty-bag guard in showForManual shows SnackBar and prevents opening',
      (tester) async {
        await tester.pumpWidget(buildManualSheet(racquets: []));
        await tester.tap(find.text('Open Manual Sheet'));
        await tester.pumpAndSettle();

        expect(
          find.text('Please add a racquet to your bag first'),
          findsOneWidget,
        );
        expect(find.text('LOG COURT SESSION'), findsNothing);
      },
    );
  });

  group('Story 3.4: Edge Cases & Guards in WorkoutAssignmentSheet', () {
    testWidgets(
      'empty-bag guard in showForDetected shows SnackBar and prevents opening',
      (tester) async {
        await tester.pumpWidget(buildDetectedSheet(racquets: []));
        await tester.tap(find.text('Open Detected Sheet'));
        await tester.pumpAndSettle();

        expect(
          find.text('Please add a racquet to your bag first'),
          findsOneWidget,
        );
        expect(find.text('ASSIGN WORKOUT'), findsNothing);
      },
    );

    testWidgets(
      'backdrop dismissal does not dismiss pending workouts',
      (tester) async {
        await tester.pumpWidget(buildDetectedSheet());
        await tester.tap(find.text('Open Detected Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('ASSIGN WORKOUT'), findsOneWidget);

        // Tap modal barrier outside the sheet to dismiss
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        expect(find.text('ASSIGN WORKOUT'), findsNothing);
        expect(fakeHealthService.pendingWorkouts, contains(detectedWorkout));
      },
    );

    testWidgets(
      'unstrung racquets cannot be selected and display UNSTRUNG badge',
      (tester) async {
        final unstrungRacquet = Racquet(
          id: 99,
          userId: Namespace.nil.uuidValue,
          name: 'Unstrung Frame',
          brand: 'Baseline',
          model: 'Pro Staff',
          isPrimary: true,
          activeStringJob: null,
          createdAt: DateTime.utc(2026, 9, 20),
          updatedAt: DateTime.utc(2026, 9, 20),
        );

        await tester.pumpWidget(
          buildDetectedSheet(
            racquets: [unstrungRacquet, secondaryRacquet],
          ),
        );
        await tester.tap(find.text('Open Detected Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('UNSTRUNG'), findsOneWidget);

        // Tapping the unstrung tile must not move the selection to it.
        await tester.tap(find.byKey(WorkoutAssignmentSheet.keyRacquetTile(99)));
        await tester.pumpAndSettle();

        // Because unstrungRacquet has activeStringJob == null, secondaryRacquet should be selected
        await tester.tap(find.byKey(WorkoutAssignmentSheet.keyConfirmButton));
        await tester.pumpAndSettle();

        verify(
          () => mockBagBloc.add(
            any(
              that: isA<LogSession>().having(
                (s) => s.racquetId,
                'racquetId',
                secondaryRacquet.id,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      'rapid double-tap on confirm button dispatches only one LogSession',
      (tester) async {
        await tester.pumpWidget(buildDetectedSheet());
        await tester.tap(find.text('Open Detected Sheet'));
        await tester.pumpAndSettle();

        final confirmFinder = find.byKey(
          WorkoutAssignmentSheet.keyConfirmButton,
        );
        await tester.tap(confirmFinder);
        await tester.tap(confirmFinder, warnIfMissed: false);
        await tester.pumpAndSettle();

        verify(
          () => mockBagBloc.add(any(that: isA<LogSession>())),
        ).called(1);
      },
    );

    testWidgets(
      'displays formatted workout start time in detected mode header',
      (tester) async {
        await tester.pumpWidget(buildDetectedSheet());
        await tester.tap(find.text('Open Detected Sheet'));
        await tester.pumpAndSettle();

        expect(find.textContaining('via simulated'), findsOneWidget);
      },
    );

    testWidgets('formats a past start time as month, day and time', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildDetectedSheet(
          workout: DetectedWorkout(
            externalWorkoutId: 'sim-past',
            startTime: DateTime(2025, 3, 7, 21, 5),
            durationMinutes: 60,
            source: DetectedWorkout.sourceSimulated,
          ),
        ),
      );
      await tester.tap(find.text('Open Detected Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Mar 7, 9:05 PM'), findsOneWidget);
    });

    testWidgets('formats a start time from today with a Today prefix', (
      tester,
    ) async {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day, 0, 30);
      await tester.pumpWidget(
        buildDetectedSheet(
          workout: DetectedWorkout(
            externalWorkoutId: 'sim-today',
            startTime: todayMidnight,
            durationMinutes: 60,
            source: DetectedWorkout.sourceSimulated,
          ),
        ),
      );
      await tester.tap(find.text('Open Detected Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Today, 12:30 AM'), findsOneWidget);
    });

    final unstrungOnly = Racquet(
      id: 99,
      userId: Namespace.nil.uuidValue,
      name: 'Unstrung Frame',
      brand: 'Baseline',
      model: 'Pro Staff',
      isPrimary: true,
      activeStringJob: null,
      createdAt: DateTime.utc(2026, 9, 20),
      updatedAt: DateTime.utc(2026, 9, 20),
    );

    testWidgets(
      'all-unstrung guard in showForDetected explains and prevents opening',
      (tester) async {
        await tester.pumpWidget(buildDetectedSheet(racquets: [unstrungOnly]));
        await tester.tap(find.text('Open Detected Sheet'));
        await tester.pumpAndSettle();

        expect(
          find.text('Restring a racquet before logging court time'),
          findsOneWidget,
        );
        expect(find.text('ASSIGN WORKOUT'), findsNothing);
      },
    );

    testWidgets(
      'all-unstrung guard in showForManual explains and prevents opening',
      (tester) async {
        await tester.pumpWidget(buildManualSheet(racquets: [unstrungOnly]));
        await tester.tap(find.text('Open Manual Sheet'));
        await tester.pumpAndSettle();

        expect(
          find.text('Restring a racquet before logging court time'),
          findsOneWidget,
        );
        expect(find.text('LOG COURT SESSION'), findsNothing);
      },
    );

    testWidgets('exposes selection state to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(buildManualSheet());
      await tester.tap(find.text('Open Manual Sheet'));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(
          find.byKey(WorkoutAssignmentSheet.keyRacquetTile(1)),
        ),
        isSemantics(isButton: true, isSelected: true),
      );
      expect(
        tester.getSemantics(
          find.byKey(WorkoutAssignmentSheet.keyRacquetTile(2)),
        ),
        isSemantics(isButton: true, isSelected: false),
      );
      expect(
        tester.getSemantics(
          find.byKey(WorkoutAssignmentSheet.keyDurationChip('1h')),
        ),
        isSemantics(isButton: true, isSelected: true),
      );
      handle.dispose();
    });
  });

  group('Epic 3 retro 3: advanced options wiring', () {
    testWidgets('tapping a selected surface chip again clears the surface', (
      tester,
    ) async {
      await tester.pumpWidget(buildDetectedSheet());
      await tester.tap(find.text('Open Detected Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WorkoutAssignmentSheet.keyAdvancedToggle));
      await tester.pumpAndSettle();

      final clay = find.byKey(WorkoutAssignmentSheet.keySurfaceChip('Clay'));
      await tester.tap(clay);
      await tester.pumpAndSettle();

      await tester.tap(clay);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WorkoutAssignmentSheet.keyConfirmButton));
      await tester.pumpAndSettle();

      final logged =
          verify(
                () => mockBagBloc.add(captureAny(that: isA<LogSession>())),
              ).captured.single
              as LogSession;
      expect(logged.courtSurface, isNull);
    });

    testWidgets('tapping the advanced toggle again collapses the panel', (
      tester,
    ) async {
      await tester.pumpWidget(buildDetectedSheet());
      await tester.tap(find.text('Open Detected Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(WorkoutAssignmentSheet.keyAdvancedToggle));
      await tester.pumpAndSettle();
      expect(find.byKey(WorkoutAssignmentSheet.keyNotesField), findsOneWidget);

      await tester.tap(find.byKey(WorkoutAssignmentSheet.keyAdvancedToggle));
      await tester.pumpAndSettle();

      expect(find.byKey(WorkoutAssignmentSheet.keyNotesField), findsNothing);
      expect(
        find.byKey(WorkoutAssignmentSheet.keySurfaceChip('Clay')),
        findsNothing,
      );
    });
  });
}
