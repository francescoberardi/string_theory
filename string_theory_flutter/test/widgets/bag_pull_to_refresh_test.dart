import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/theme/court_midnight_theme.dart';
import 'package:string_theory_flutter/widgets/bag/bag_racquet_list.dart';

import '../helpers/tdd_red_phase.dart';

class MockClient extends Mock implements Client {}

class MockEndpointBag extends Mock implements EndpointBag {}

/// Story 6.1: pull-to-refresh keeps its spinner until the bag reload settles.
void main() {
  late MockClient mockClient;
  late MockEndpointBag mockBagEndpoint;

  final racquet = Racquet(
    id: 1,
    userId: Namespace.nil.uuidValue,
    name: 'Wilson Blade 98',
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

  testWidgets(
    '[P1] AC-2 pull-to-refresh keeps the spinner until the reload emits BagLoaded',
    (tester) async {
      final reload = Completer<List<Racquet>>();
      when(
        () => mockBagEndpoint.getVirtualBag(),
      ).thenAnswer((_) => reload.future);
      final bloc = BagBloc(client: mockClient);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: CourtMidnightTheme.themeData,
          home: Scaffold(
            body: BagRacquetList(
              racquets: [racquet],
              bloc: bloc,
              isMobile: true,
            ),
          ),
        ),
      );

      await tester.fling(
        find.byKey(BagRacquetList.keyRacquetList),
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      final spinnersWhileReloading = find
          .byType(RefreshProgressIndicator)
          .evaluate()
          .length;

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
    skip: tddRedPhase,
  );
}
