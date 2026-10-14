import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/screens/virtual_bag_screen.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/bag/bag_racquet_list.dart';

import '../helpers/fake_health_sync_service.dart';

class MockClient extends Mock implements Client {}

class MockEndpointBag extends Mock implements EndpointBag {}

/// Story 6.1: pull-to-refresh keeps its spinner until the bag reload settles.
void main() {
  late MockClient mockClient;
  late MockEndpointBag mockBagEndpoint;

  final racquet = Racquet(
    id: 1,
    userId: Namespace.nil.uuidValue,
    name: 'Tour 98',
    isPrimary: true,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 1),
  );

  setUp(() {
    mockClient = MockClient();
    mockBagEndpoint = MockEndpointBag();
    when(() => mockClient.bag).thenReturn(mockBagEndpoint);
    when(
      () => mockBagEndpoint.bagUpdates(),
    ).thenAnswer((_) => const Stream<BagStreamMessage>.empty());
  });

  Future<void> pumpList(
    WidgetTester tester,
    BagBloc bloc, {
    bool isMobile = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CourtMidnightTheme.themeData,
        home: Scaffold(
          body: BagRacquetList(
            racquets: [racquet],
            bloc: bloc,
            isMobile: isMobile,
            crossAxisCount: 2,
          ),
        ),
      ),
    );
  }

  /// Pulls to refresh, then lets 2 s pass with the reload in flight.
  Future<void> pullAndWait(WidgetTester tester, Key listKey) async {
    await tester.fling(find.byKey(listKey), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  int spinnerCount() => find.byType(RefreshProgressIndicator).evaluate().length;

  testWidgets(
    '[P1] AC-2 pull-to-refresh keeps the spinner until the reload emits BagLoaded',
    (tester) async {
      final reload = Completer<List<Racquet>>();
      when(
        () => mockBagEndpoint.getVirtualBag(),
      ).thenAnswer((_) => reload.future);
      final bloc = BagBloc(client: mockClient);
      addTearDown(bloc.close);

      await pumpList(tester, bloc);
      await pullAndWait(tester, BagRacquetList.keyRacquetList);
      final spinnersWhileReloading = spinnerCount();

      // Settle the reload before asserting, so a failure doesn't leave the
      // LoadBag handler pending and bloc.close hanging.
      reload.complete([racquet]);
      await tester.pumpAndSettle();

      // Criterion-defining assertion: the reload was still in flight, so the
      // spinner must still have been showing.
      expect(
        spinnersWhileReloading,
        1,
        reason: 'onRefresh must await BagLoaded/BagError',
      );
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    },
  );

  testWidgets('[P1] AC-2 a reload ending in BagError releases the spinner', (
    tester,
  ) async {
    final reload = Completer<List<Racquet>>();
    when(
      () => mockBagEndpoint.getVirtualBag(),
    ).thenAnswer((_) => reload.future);
    final bloc = BagBloc(client: mockClient);
    addTearDown(bloc.close);

    await pumpList(tester, bloc);
    await pullAndWait(tester, BagRacquetList.keyRacquetList);
    expect(spinnerCount(), 1);

    reload.completeError(Exception('Connection timed out'));
    await tester.pumpAndSettle();

    expect(bloc.state, isA<BagError>());
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets(
    '[P1] AC-2 a reload that never settles releases the spinner at 8 s',
    (tester) async {
      final reload = Completer<List<Racquet>>();
      when(
        () => mockBagEndpoint.getVirtualBag(),
      ).thenAnswer((_) => reload.future);
      final bloc = BagBloc(client: mockClient);
      addTearDown(bloc.close);

      await pumpList(tester, bloc);
      await pullAndWait(tester, BagRacquetList.keyRacquetList);

      // ~2.3 s elapsed since the pull: still before the cap.
      await tester.pump(const Duration(seconds: 5));
      expect(spinnerCount(), 1, reason: 'spinner held before 8 s');

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(RefreshProgressIndicator), findsNothing);

      reload.complete([racquet]);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('[P1] AC-2 grid layout holds the spinner the same way', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final reload = Completer<List<Racquet>>();
    when(
      () => mockBagEndpoint.getVirtualBag(),
    ).thenAnswer((_) => reload.future);
    final bloc = BagBloc(client: mockClient);
    addTearDown(bloc.close);

    await pumpList(tester, bloc, isMobile: false);
    await pullAndWait(tester, BagRacquetList.keyRacquetGrid);
    final spinnersWhileReloading = spinnerCount();

    reload.complete([racquet]);
    await tester.pumpAndSettle();

    expect(spinnersWhileReloading, 1);
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets(
    '[P1] AC-2 VirtualBagScreen keeps the list mounted while a refresh reloads',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final fakeHealth = FakeHealthSyncService();
      addTearDown(fakeHealth.dispose);
      var loads = 0;
      final reload = Completer<List<Racquet>>();
      when(() => mockBagEndpoint.getVirtualBag()).thenAnswer((_) {
        if (loads++ == 0) return Future.value([racquet]);
        return reload.future;
      });
      final bloc = BagBloc(client: mockClient);
      addTearDown(bloc.close);
      bloc.add(const LoadBag());

      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: VirtualBagScreen(bagBloc: bloc, healthSyncService: fakeHealth),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(VirtualBagScreen.keyRacquetList), findsOneWidget);

      await pullAndWait(tester, VirtualBagScreen.keyRacquetList);

      expect(bloc.state, isA<BagLoading>());
      expect(find.byKey(VirtualBagScreen.keyRacquetList), findsOneWidget);
      expect(find.byKey(VirtualBagScreen.keyLoadingIndicator), findsNothing);
      expect(spinnerCount(), 1);

      reload.complete([racquet.copyWith(name: 'Tour 98 v9')]);
      await tester.pumpAndSettle();

      expect(find.text('Tour 98 v9'), findsOneWidget);
      expect(find.byType(RefreshProgressIndicator), findsNothing);
    },
  );
}
