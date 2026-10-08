import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:patrol_finders/patrol_finders.dart';
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

  final sampleBlade = Racquet(
    id: 1,
    userId: Namespace.nil.uuidValue,
    name: 'Wilson Blade 98',
    brand: 'Wilson',
    model: 'Blade 98',
    isPrimary: true,
    activeStringJobId: 101,
    activeStringJob: StringJob(
      id: 101,
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
  );

  final samplePureAero = Racquet(
    id: 2,
    userId: Namespace.nil.uuidValue,
    name: 'Babolat Pure Aero',
    brand: 'Babolat',
    model: 'Pure Aero',
    isPrimary: false,
    activeStringJobId: 102,
    activeStringJob: StringJob(
      id: 102,
      userId: Namespace.nil.uuidValue,
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

  final sampleRadical = Racquet(
    id: 3,
    userId: Namespace.nil.uuidValue,
    name: 'Head Radical MP',
    brand: 'Head',
    model: 'Radical MP',
    isPrimary: false,
    activeStringJobId: 103,
    activeStringJob: StringJob(
      id: 103,
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

  Widget buildSubject({BagState? state}) {
    when(() => mockBagBloc.state).thenReturn(state ?? const BagLoaded([]));

    return MaterialApp(
      theme: CourtMidnightTheme.themeData,
      home: VirtualBagScreen(
        bagBloc: mockBagBloc,
        healthSyncService: fakeHealth,
      ),
    );
  }

  group('Story 5.4: Patrol Headless E2E Verification', () {
    patrolWidgetTest(
      'runs critical path headlessly: onboarding -> bag seeding -> workout simulation -> decay -> restring',
      ($) async {
        // 1. Initial Launch
        await $.pumpWidget(buildSubject(state: const BagLoaded([])));
        expect($(find.text('YOUR BAG IS EMPTY')), findsOneWidget);
        expect($(find.text('⚡ Load Sample Bag')), findsOneWidget);

        // 2. Load Sample Bag
        when(
          () => mockBagBloc.add(const SeedSampleBag()),
        ).thenAnswer((_) async {});
        await $(find.text('⚡ Load Sample Bag')).tap();

        final seededRacquets = [sampleBlade, samplePureAero, sampleRadical];
        when(() => mockBagBloc.state).thenReturn(BagLoaded(seededRacquets));
        bagStateController.add(BagLoaded(seededRacquets));
        await $.pumpAndSettle();

        expect($(find.text('Wilson Blade 98')), findsOneWidget);
        expect($(find.text('Babolat Pure Aero')), findsOneWidget);
        expect($(find.text('Head Radical MP')), findsOneWidget);

        // 3. Simulated Workout Ingestion
        fakeHealth.emit(
          DetectedWorkout(
            externalWorkoutId: 'patrol-ci-match-90m',
            startTime: DateTime.utc(2026, 10, 4, 16, 30),
            durationMinutes: 90,
            source: DetectedWorkout.sourceSimulated,
          ),
        );
        await $.pumpAndSettle();

        expect($(find.text('1h 30m Tennis Match Detected')), findsOneWidget);
        expect($(find.text('Assign')), findsOneWidget);
        expect($(find.byType(WorkoutAssignmentSheet)), findsOneWidget);

        // 4. Decay Wilson Blade (76% -> 67%)
        final decayedBlade = sampleBlade.copyWith(
          activeStringJob: sampleBlade.activeStringJob!.copyWith(
            currentHealthScore: 67,
            totalCourtHours: 6.5,
          ),
        );
        final decayedRacquets = [decayedBlade, samplePureAero, sampleRadical];

        when(() => mockBagBloc.state).thenReturn(BagLoaded(decayedRacquets));
        bagStateController.add(BagLoaded(decayedRacquets));

        // Dismiss assignment sheet
        Navigator.of(
          $.tester.element(find.byType(WorkoutAssignmentSheet)),
        ).pop();
        await $.pumpAndSettle();

        ScaffoldMessenger.of(
          $.tester.element(find.byType(Scaffold)),
        ).clearSnackBars();
        await $.pumpAndSettle();

        expect($(find.text('67%')), findsOneWidget);

        // 5. Restring Head Radical
        final restringButton = $(RacquetCard.restrungTodayKey(3));
        expect(restringButton, findsOneWidget);

        await $.tester.ensureVisible(
          find.byKey(RacquetCard.restrungTodayKey(3)),
        );
        await $.pumpAndSettle();
        await restringButton.tap();
        await $.pumpAndSettle();

        expect($(find.byType(RestringSheet)), findsOneWidget);

        final restrungRadical = sampleRadical.copyWith(
          activeStringJobId: 104,
          activeStringJob: StringJob(
            id: 104,
            userId: Namespace.nil.uuidValue,
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
          samplePureAero,
          restrungRadical,
        ];

        when(() => mockBagBloc.state).thenReturn(BagLoaded(restrungRacquets));
        bagStateController.add(BagLoaded(restrungRacquets));

        Navigator.of($.tester.element(find.byType(RestringSheet))).pop();
        await $.pumpAndSettle();

        expect($(find.text('100%')), findsOneWidget);

        // 6. Inspect Timeline
        when(
          () => mockBag.getRestringHistory(racquetId: any(named: 'racquetId')),
        ).thenAnswer(
          (_) async => [
            RestringEvent(
              id: 101,
              userId: Namespace.nil.uuidValue,
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

        final radicalTextFinder = find.text('Head Radical MP');
        await $.tester.ensureVisible(radicalTextFinder);
        await $.pumpAndSettle();
        await $(radicalTextFinder).tap();
        await $.pumpAndSettle();

        expect($(find.byType(RacquetDetailScreen)), findsOneWidget);
        expect($(find.byType(RadialHealthGauge)), findsOneWidget);

        await $(find.text('History')).tap();
        await $.pumpAndSettle();

        expect($(find.text('Head Velocity MLT')), findsOneWidget);
        expect($(find.textContaining('25.0 court hours')), findsOneWidget);
      },
    );
  });
}
