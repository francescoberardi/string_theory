import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/bloc/bag_error_messages.dart';
import 'package:string_theory_flutter/services/offline_session_queue.dart';

import 'helpers/tdd_red_phase.dart';

class MockClient extends Mock implements Client {}

class MockEndpointBag extends Mock implements EndpointBag {}

class MockEndpointSession extends Mock implements EndpointSession {}

class FakeSessionLog extends Fake implements SessionLog {}

/// Story 6.1: BagBloc must not report a successful mutation as failed, and
/// must route an expired session to re-authentication instead of the offline
/// queue.
void main() {
  late MockClient mockClient;
  late MockEndpointBag mockBagEndpoint;
  late MockEndpointSession mockSessionEndpoint;
  late OfflineSessionQueue queue;

  final stringingDate = DateTime.utc(2026, 10, 1);

  Racquet racquet({required int id, required String name}) => Racquet(
    id: id,
    userId: Namespace.nil.uuidValue,
    name: name,
    isPrimary: id == 1,
    activeStringJob: StringJob(
      id: id * 10,
      userId: Namespace.nil.uuidValue,
      racquetId: id,
      materialCategory: StringMaterialCategory.coPoly,
      brand: 'Luxilon',
      model: 'ALU Power',
      stringingDate: stringingDate,
      installedTension: 52.0,
      maxRatedHours: 20.0,
      totalCourtHours: 5.0,
      currentHealthScore: 76,
      isActive: true,
      createdAt: stringingDate,
    ),
    createdAt: stringingDate,
    updatedAt: stringingDate,
  );

  setUpAll(() {
    registerFallbackValue(FakeSessionLog());
  });

  setUp(() {
    mockClient = MockClient();
    mockBagEndpoint = MockEndpointBag();
    mockSessionEndpoint = MockEndpointSession();
    queue = OfflineSessionQueue(storage: InMemorySessionQueueStorage());
    when(() => mockClient.bag).thenReturn(mockBagEndpoint);
    when(() => mockClient.session).thenReturn(mockSessionEndpoint);
    when(
      () => mockBagEndpoint.bagUpdates(),
    ).thenAnswer((_) => const Stream<BagStreamMessage>.empty());
  });

  /// A bloc loaded with [racquets]; every later `getVirtualBag` throws, as if
  /// the network dropped right after the initial load.
  Future<(BagBloc, List<BagState>)> loadedBlocWithFailingReload(
    List<Racquet> racquets,
  ) async {
    var loads = 0;
    when(() => mockBagEndpoint.getVirtualBag()).thenAnswer((_) async {
      if (loads++ == 0) return racquets;
      throw Exception('Connection timed out');
    });
    final bloc = BagBloc(client: mockClient, offlineQueue: queue);
    bloc.add(const LoadBag());
    await pumpEventQueue();
    final states = <BagState>[];
    bloc.stream.listen(states.add);
    return (bloc, states);
  }

  group('Story 6.1 mutation refresh decoupling', () {
    test(
      '[P1] AC-1 AddRacquet succeeds but the bag reload fails: no error, the new racquet is kept',
      () async {
        final existing = racquet(id: 1, name: 'Wilson Blade 98');
        final created = racquet(id: 2, name: 'Yonex Ezone 98');
        final (bloc, states) = await loadedBlocWithFailingReload([existing]);
        when(
          () => mockBagEndpoint.createRacquet(
            racquetName: any(named: 'racquetName'),
            brand: any(named: 'brand'),
            model: any(named: 'model'),
            isPrimary: any(named: 'isPrimary'),
            materialCategory: any(named: 'materialCategory'),
            stringBrand: any(named: 'stringBrand'),
            stringModel: any(named: 'stringModel'),
            tension: any(named: 'tension'),
            maxRatedHours: any(named: 'maxRatedHours'),
            stringingDate: any(named: 'stringingDate'),
          ),
        ).thenAnswer((_) async => created);

        bloc.add(
          AddRacquet(
            name: 'Yonex Ezone 98',
            stringBrand: 'Yonex',
            stringModel: 'Poly Tour Pro',
            tension: 50.0,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
          ),
        );
        await pumpEventQueue();

        // Criterion-defining assertion: the saved racquet is never reported
        // as a failed add.
        expect(
          states.whereType<BagError>(),
          isEmpty,
          reason:
              'A failed reload after a successful createRacquet is not '
              'a failed add',
        );
        expect(
          states.whereType<BagLoaded>().where((s) => s.errorMessage != null),
          isEmpty,
        );
        final latest = bloc.state as BagLoaded;
        expect(latest.racquets.map((r) => r.id), containsAll([1, 2]));
        await bloc.close();
      },
      skip: tddRedPhaseReason,
    );
  });

  group('Story 6.1 auth 401 routing', () {
    test(
      '[P1] AC-3 logSession rejected with 401 is not queued offline and prompts re-authentication',
      () async {
        final target = racquet(id: 1, name: 'Wilson Blade 98');
        final (bloc, states) = await loadedBlocWithFailingReload([target]);
        final unauthorized = ServerpodClientUnauthorized();
        when(
          () => mockSessionEndpoint.logSession(any()),
        ).thenThrow(unauthorized);
        var onLoggedCalls = 0;

        bloc.add(
          LogSession(
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 17, 0),
            durationMinutes: 60,
            source: 'manual',
            onLogged: () => onLoggedCalls++,
          ),
        );
        await pumpEventQueue();

        // Criterion-defining assertion: an expired session is permanent, so
        // the session never enters the offline queue.
        expect(queue.pendingCount, 0, reason: '401 must not be queued');
        expect(
          states.whereType<BagLoaded>().map((s) => s.infoMessage),
          isNot(contains(BagBloc.offlineSavedMessage)),
        );
        expect(onLoggedCalls, 0);
        expect(
          (bloc.state as BagLoaded).errorMessage,
          bagErrorMessage(
            BagOperation.logSession,
            unauthorized,
            racquet: target,
          ),
        );
        await bloc.close();
      },
      skip: tddRedPhaseReason,
    );
  });
}
