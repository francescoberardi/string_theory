import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:flutter_test/flutter_test.dart' hide test;
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/screens/virtual_bag_screen.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/add_racquet_modal.dart';

/// ATDD Red-Phase test runner helper allowing `test.skip(...)` syntax in Dart.
// ignore: camel_case_types
class test {
  static void skipWidgets(
    String description,
    flutter_test.WidgetTesterCallback callback, {
    String? reason,
  }) {
    flutter_test.testWidgets(
      description,
      callback,
      skip: true,
    );
  }
}

class MockBagBloc extends Mock implements BagBloc {}

void main() {
  late MockBagBloc mockBagBloc;

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
  });

  group('Story 1.5: Virtual Bag Responsive Screen & Demo Bag Seeder', () {
    test.skipWidgets(
      '[P0] AC-1 should render empty state with Add Racquet and Load Sample Bag buttons when bag is empty',
      (tester) async {
        when(() => mockBagBloc.state).thenReturn(const BagLoaded([]));
        when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: VirtualBagScreen(bagBloc: mockBagBloc),
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

    test.skipWidgets(
      '[P0] AC-2 should open AddRacquetModal when [+ Add Racquet] is tapped on empty state',
      (tester) async {
        when(() => mockBagBloc.state).thenReturn(const BagLoaded([]));
        when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: VirtualBagScreen(bagBloc: mockBagBloc),
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
          reason: 'Tapping Add Racquet on empty state must open AddRacquetModal',
        );
      },
    );

    test.skipWidgets(
      '[P0] AC-3 should dispatch SeedSampleBag event to BagBloc when [⚡ Load Sample Bag] is tapped',
      (tester) async {
        when(() => mockBagBloc.state).thenReturn(const BagLoaded([]));
        when(() => mockBagBloc.stream).thenAnswer((_) => const Stream.empty());

        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: VirtualBagScreen(bagBloc: mockBagBloc),
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

    test.skipWidgets(
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
            home: VirtualBagScreen(bagBloc: mockBagBloc),
          ),
        );
        await tester.pumpAndSettle();

        // Criterion-defining primary assertion: single column list is rendered on mobile
        expect(
          find.byKey(VirtualBagScreen.keyRacquetList),
          findsOneWidget,
          reason: 'Mobile screen must render racquets in a single-column list',
        );

        // Bottom navigation bar is visible on mobile
        expect(find.byKey(VirtualBagScreen.keyBottomNav), findsOneWidget);
        expect(find.byKey(VirtualBagScreen.keyNavigationRail), findsNothing);
      },
    );

    test.skipWidgets(
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
            home: VirtualBagScreen(bagBloc: mockBagBloc),
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

        // NavigationRail is visible on tablet/desktop
        expect(find.byKey(VirtualBagScreen.keyNavigationRail), findsOneWidget);
        expect(find.byKey(VirtualBagScreen.keyBottomNav), findsNothing);
      },
    );
  });
}
