import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/bag/bag_racquet_list.dart';

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
              model: 'ALU Power 125 Rough',
              stringingDate: DateTime.utc(2026, 9, 20),
              installedTension: 54.0,
              maxRatedHours: 20.0,
              totalCourtHours: 15.0,
              currentHealthScore: healthScore,
              isActive: true,
              createdAt: DateTime.utc(2026, 9, 20),
            )
          : null,
      createdAt: DateTime.utc(2026, 9, 20),
      updatedAt: DateTime.utc(2026, 9, 20),
    );
  }

  group('BagRacquetList Grid Extent Resolution', () {
    test('gridCardExtent remains 176.0 for backwards compatibility', () {
      expect(BagRacquetList.gridCardExtent, 176.0);
    });

    test(
      'resolveGridCardExtentForScaler returns base extent at 1.0x or below',
      () {
        expect(
          BagRacquetList.resolveGridCardExtentForScaler(TextScaler.noScaling),
          176.0,
        );
        expect(
          BagRacquetList.resolveGridCardExtentForScaler(
            const TextScaler.linear(0.8),
          ),
          176.0,
        );
        expect(
          BagRacquetList.resolveGridCardExtentForScaler(
            const TextScaler.linear(1.0),
          ),
          176.0,
        );
      },
    );

    test('resolveGridCardExtentForScaler expands dynamically above 1.0x', () {
      final extent15 = BagRacquetList.resolveGridCardExtentForScaler(
        const TextScaler.linear(1.5),
      );
      final extent20 = BagRacquetList.resolveGridCardExtentForScaler(
        const TextScaler.linear(2.0),
      );

      expect(extent15, greaterThan(176.0));
      expect(extent20, greaterThan(extent15));
      expect(extent15, closeTo(229.0, 5.0));
      expect(extent20, closeTo(288.0, 5.0));
    });

    testWidgets('resolveGridCardExtent reads MediaQuery textScaler', (
      tester,
    ) async {
      double? capturedExtent1;
      double? capturedExtent2;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.0)),
            child: Builder(
              builder: (context) {
                capturedExtent1 = BagRacquetList.resolveGridCardExtent(context);
                return const Placeholder();
              },
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: Builder(
              builder: (context) {
                capturedExtent2 = BagRacquetList.resolveGridCardExtent(context);
                return const Placeholder();
              },
            ),
          ),
        ),
      );

      expect(capturedExtent1, 176.0);
      expect(capturedExtent2, greaterThan(176.0));
    });
  });

  group('BagRacquetList Layout & Accessibility Scaling', () {
    testWidgets(
      'tablet grid renders without overflow under 1.5x and 2.0x scaling',
      (
        tester,
      ) async {
        final racquets = [
          createRacquet(
            id: 1,
            name: 'Pro Staff 97',
            healthScore: 85,
            isPrimary: true,
          ),
          createRacquet(
            id: 2,
            name: 'Blade 98 V8',
            healthScore: 25,
          ), // Dead stringbed badge
        ];

        // Test under 1.5x text scaling
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(800, 1200),
                textScaler: TextScaler.linear(1.5),
              ),
              child: Scaffold(
                body: BagRacquetList(
                  racquets: racquets,
                  bloc: mockBagBloc,
                  isMobile: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(BagRacquetList.keyRacquetGrid), findsOneWidget);

        final gridView = tester.widget<GridView>(
          find.byKey(BagRacquetList.keyRacquetGrid),
        );
        final delegate =
            gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.mainAxisExtent, greaterThan(176.0));

        // Test under 2.0x text scaling
        await tester.pumpWidget(
          MaterialApp(
            theme: CourtMidnightTheme.themeData,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(800, 1200),
                textScaler: TextScaler.linear(2.0),
              ),
              child: Scaffold(
                body: BagRacquetList(
                  racquets: racquets,
                  bloc: mockBagBloc,
                  isMobile: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final gridView20 = tester.widget<GridView>(
          find.byKey(BagRacquetList.keyRacquetGrid),
        );
        final delegate20 =
            gridView20.gridDelegate
                as SliverGridDelegateWithFixedCrossAxisCount;
        expect(
          delegate20.mainAxisExtent,
          greaterThan(delegate.mainAxisExtent!),
        );
      },
    );

    testWidgets('allows explicit mainAxisExtent override', (tester) async {
      final racquets = [
        createRacquet(id: 1, name: 'Pro Staff 97', healthScore: 85),
      ];

      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            body: BagRacquetList(
              racquets: racquets,
              bloc: mockBagBloc,
              isMobile: false,
              mainAxisExtent: 250.0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(
        find.byKey(BagRacquetList.keyRacquetGrid),
      );
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.mainAxisExtent, 250.0);
    });

    testWidgets('mobile mode renders ListView and triggers pull-to-refresh', (
      tester,
    ) async {
      final racquets = [
        createRacquet(id: 1, name: 'Pro Staff 97', healthScore: 85),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            body: BagRacquetList(
              racquets: racquets,
              bloc: mockBagBloc,
              isMobile: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(BagRacquetList.keyRacquetList), findsOneWidget);
      expect(find.text('Pro Staff 97'), findsOneWidget);

      // Trigger pull-to-refresh
      await tester.fling(
        find.byKey(BagRacquetList.keyRacquetList),
        const Offset(0.0, 300.0),
        1000.0,
      );
      await tester.pumpAndSettle();

      verify(() => mockBagBloc.add(const LoadBag())).called(1);
    });

    testWidgets('desktop mode (>1024dp) defaults to 3 columns', (tester) async {
      final racquets = [
        createRacquet(id: 1, name: 'Pro Staff 97', healthScore: 85),
      ];

      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1280, 800)),
            child: Scaffold(
              body: BagRacquetList(
                racquets: racquets,
                bloc: mockBagBloc,
                isMobile: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(
        find.byKey(BagRacquetList.keyRacquetGrid),
      );
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    });

    testWidgets('empty racquets list renders without errors in both modes', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            body: BagRacquetList(
              racquets: const [],
              bloc: mockBagBloc,
              isMobile: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BagRacquetList.keyRacquetList), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            body: BagRacquetList(
              racquets: const [],
              bloc: mockBagBloc,
              isMobile: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(BagRacquetList.keyRacquetGrid), findsOneWidget);
    });
  });
}
