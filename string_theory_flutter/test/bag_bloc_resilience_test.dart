import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/bloc/bag_error_messages.dart';
import 'package:string_theory_flutter/services/offline_session_queue.dart';

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
    List<Racquet> racquets, {
    Duration resyncDelay = const Duration(seconds: 5),
  }) async {
    var loads = 0;
    when(() => mockBagEndpoint.getVirtualBag()).thenAnswer((_) async {
      if (loads++ == 0) return racquets;
      throw Exception('Connection timed out');
    });
    final bloc = BagBloc(
      client: mockClient,
      offlineQueue: queue,
      resyncDelay: resyncDelay,
    );
    bloc.add(const LoadBag());
    await pumpEventQueue();
    final states = <BagState>[];
    bloc.stream.listen(states.add);
    return (bloc, states);
  }

  void stubCreate(Racquet created) {
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
        initialCourtHours: any(named: 'initialCourtHours'),
      ),
    ).thenAnswer((_) async => created);
  }

  void stubTargetMutations(Racquet target) {
    when(
      () => mockBagEndpoint.deleteRacquet(racquetId: 1),
    ).thenAnswer((_) async => true);
    when(
      () => mockBagEndpoint.setPrimary(racquetId: 1),
    ).thenAnswer((_) async => target);
    when(
      () => mockBagEndpoint.fastForwardRacquetAge(racquetId: 1, days: 30),
    ).thenAnswer((_) async => target);
  }

  BagEvent mutation(String name) => switch (name) {
    'DeleteRacquet' => const DeleteRacquet(1),
    'SetPrimaryRacquet' => const SetPrimaryRacquet(1),
    _ => const FastForwardRacquetAge(1),
  };

  AddRacquet addEzone({bool isPrimary = false}) => AddRacquet(
    name: 'Yonex Ezone 98',
    isPrimary: isPrimary,
    stringBrand: 'Yonex',
    stringModel: 'Poly Tour Pro',
    tension: 50.0,
    maxRatedHours: 20.0,
    stringingDate: stringingDate,
  );

  group('Story 6.1 mutation refresh decoupling', () {
    test('[P1] AC-1 a failed createRacquet still reports a failed add, '
        'with no reload or re-sync', () async {
      final existing = racquet(id: 1, name: 'Wilson Blade 98');
      final (bloc, states) = await loadedBlocWithFailingReload([
        existing,
      ], resyncDelay: const Duration(milliseconds: 10));
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
          initialCourtHours: any(named: 'initialCourtHours'),
        ),
      ).thenThrow(Exception('Connection refused'));

      bloc.add(addEzone());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(states, [
        BagError(
          bagErrorMessage(
            BagOperation.addRacquet,
            Exception('Connection refused'),
            racquetName: 'Yonex Ezone 98',
          ),
        ),
      ]);
      verify(() => mockBagEndpoint.getVirtualBag()).called(1);
      await bloc.close();
    });

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
            initialCourtHours: any(named: 'initialCourtHours'),
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
    );

    test(
      '[P1] AC-1 a primary racquet kept after a failed reload demotes the others',
      () async {
        final existing = racquet(id: 1, name: 'Wilson Blade 98');
        final created = racquet(
          id: 2,
          name: 'Yonex Ezone 98',
        ).copyWith(isPrimary: true);
        final (bloc, _) = await loadedBlocWithFailingReload([existing]);
        stubCreate(created);

        bloc.add(addEzone(isPrimary: true));
        await pumpEventQueue();

        final latest = bloc.state as BagLoaded;
        expect(latest.errorMessage, isNull);
        expect(latest.racquets.map((r) => (r.id, r.isPrimary)), [
          (1, false),
          (2, true),
        ]);
        await bloc.close();
      },
    );

    test(
      '[P1] AC-1 a reload that exceeds the timeout is treated as failed',
      () async {
        final existing = racquet(id: 1, name: 'Wilson Blade 98');
        final created = racquet(id: 2, name: 'Yonex Ezone 98');
        var loads = 0;
        when(() => mockBagEndpoint.getVirtualBag()).thenAnswer((_) {
          if (loads++ == 0) return Future.value([existing]);
          return Completer<List<Racquet>>().future; // never settles
        });
        final bloc = BagBloc(
          client: mockClient,
          offlineQueue: queue,
          reloadTimeout: const Duration(milliseconds: 20),
          resyncDelay: const Duration(hours: 1),
        );
        bloc.add(const LoadBag());
        await pumpEventQueue();
        final states = <BagState>[];
        bloc.stream.listen(states.add);
        stubCreate(created);

        bloc.add(addEzone());
        await pumpEventQueue();
        expect(states, isEmpty, reason: 'still waiting on the reload');

        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(states.whereType<BagError>(), isEmpty);
        expect(
          (bloc.state as BagLoaded).racquets.map((r) => r.id),
          [1, 2],
        );
        await bloc.close();
      },
    );

    for (final (name, stateLabel) in [
      ('DeleteRacquet', 'BagError'),
      ('SetPrimaryRacquet', 'BagError'),
      ('FastForwardRacquetAge', 'BagError'),
      ('DeleteRacquet', 'BagLoading'),
      ('SetPrimaryRacquet', 'BagLoading'),
      ('FastForwardRacquetAge', 'BagLoading'),
    ]) {
      test(
        '[P1] AC-1 $name from $stateLabel: RPC ok, reload fails, no failure copy, re-sync recovers',
        () async {
          final target = racquet(id: 1, name: 'Wilson Blade 98');
          final server = name == 'DeleteRacquet' ? <Racquet>[] : [target];
          final hold = Completer<List<Racquet>>();
          addTearDown(() {
            if (!hold.isCompleted) hold.complete([target]);
          });
          var loads = 0;
          when(() => mockBagEndpoint.getVirtualBag()).thenAnswer((_) {
            loads++;
            if (loads == 1) {
              return stateLabel == 'BagLoading'
                  ? hold.future
                  : Future.error(Exception('Connection timed out'));
            }
            if (loads == 2) {
              return Future.error(Exception('Connection timed out'));
            }
            return Future.value(server);
          });
          stubTargetMutations(target);
          final bloc = BagBloc(
            client: mockClient,
            offlineQueue: queue,
            resyncDelay: const Duration(milliseconds: 10),
          );
          bloc.add(const LoadBag());
          await pumpEventQueue();
          expect(bloc.state.runtimeType.toString(), stateLabel);
          final states = <BagState>[];
          bloc.stream.listen(states.add);

          bloc.add(mutation(name));
          await pumpEventQueue();
          expect(states, isEmpty, reason: 'no failure copy, no new state');

          await Future<void>.delayed(const Duration(milliseconds: 100));
          expect(loads, 3, reason: 'one background re-sync');
          expect(states, [BagLoaded(server)]);
          await bloc.close();
        },
      );
    }

    for (final name in ['DeleteRacquet', 'SetPrimaryRacquet']) {
      test(
        '[P1] AC-1 $name from an unloaded state adopts a successful reload',
        () async {
          final target = racquet(id: 1, name: 'Wilson Blade 98');
          final server = name == 'DeleteRacquet' ? <Racquet>[] : [target];
          var loads = 0;
          when(() => mockBagEndpoint.getVirtualBag()).thenAnswer((_) {
            if (loads++ == 0) {
              return Future.error(Exception('Connection timed out'));
            }
            return Future.value(server);
          });
          stubTargetMutations(target);
          final bloc = BagBloc(client: mockClient, offlineQueue: queue);
          bloc.add(const LoadBag());
          await pumpEventQueue();
          expect(bloc.state, isA<BagError>());

          bloc.add(mutation(name));
          await pumpEventQueue();

          expect(bloc.state, BagLoaded(server));
          verify(() => mockBagEndpoint.getVirtualBag()).called(2);
          await bloc.close();
        },
      );
    }
  });

  group('Story 6.1 background re-sync', () {
    test('[P1] AC-1 re-sync reconciles the bag with the server', () async {
      final existing = racquet(id: 1, name: 'Wilson Blade 98');
      final created = racquet(id: 2, name: 'Yonex Ezone 98');
      final server = [existing, created.copyWith(name: 'Yonex Ezone 98 (7th)')];
      var loads = 0;
      when(() => mockBagEndpoint.getVirtualBag()).thenAnswer((_) async {
        loads++;
        if (loads == 1) return [existing];
        if (loads == 2) throw Exception('Connection timed out');
        return server;
      });
      final bloc = BagBloc(
        client: mockClient,
        offlineQueue: queue,
        resyncDelay: const Duration(milliseconds: 10),
      );
      bloc.add(const LoadBag());
      await pumpEventQueue();
      final states = <BagState>[];
      bloc.stream.listen(states.add);
      stubCreate(created);

      bloc.add(addEzone());
      await pumpEventQueue();
      expect((bloc.state as BagLoaded).racquets, [existing, created]);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(loads, 3);
      expect(states.whereType<BagLoading>(), isEmpty);
      expect(states.whereType<BagError>(), isEmpty);
      expect((bloc.state as BagLoaded).racquets, server);
      await bloc.close();
    });

    test('[P1] AC-1 re-sync gives up after 3 attempts, silently', () async {
      final existing = racquet(id: 1, name: 'Wilson Blade 98');
      final (bloc, states) = await loadedBlocWithFailingReload(
        [existing],
        resyncDelay: const Duration(milliseconds: 5),
      );
      stubCreate(racquet(id: 2, name: 'Yonex Ezone 98'));

      bloc.add(addEzone());
      await Future<void>.delayed(const Duration(milliseconds: 300));

      // 1 initial load + 1 post-add reload + 3 re-sync attempts.
      verify(() => mockBagEndpoint.getVirtualBag()).called(5);
      expect(states.whereType<BagLoading>(), isEmpty);
      expect(states.whereType<BagError>(), isEmpty);
      expect(
        states.whereType<BagLoaded>().where((s) => s.errorMessage != null),
        isEmpty,
      );
      await bloc.close();
    });

    test(
      '[P1] AC-1 a stale re-sync snapshot never overwrites newer state',
      () async {
        final first = racquet(id: 1, name: 'Wilson Blade 98');
        final second = racquet(id: 2, name: 'Babolat Pure Drive');
        final created = racquet(id: 3, name: 'Yonex Ezone 98');
        final resyncFetch = Completer<List<Racquet>>();
        addTearDown(() {
          if (!resyncFetch.isCompleted) resyncFetch.complete([]);
        });
        var loads = 0;
        when(() => mockBagEndpoint.getVirtualBag()).thenAnswer((_) {
          loads++;
          if (loads == 1) return Future.value([first, second]);
          if (loads == 2) {
            return Future.error(Exception('Connection timed out'));
          }
          return resyncFetch.future;
        });
        when(
          () => mockBagEndpoint.deleteRacquet(racquetId: 2),
        ).thenAnswer((_) async => true);
        final bloc = BagBloc(
          client: mockClient,
          offlineQueue: queue,
          resyncDelay: const Duration(milliseconds: 10),
        );
        bloc.add(const LoadBag());
        await pumpEventQueue();
        stubCreate(created);

        bloc.add(addEzone());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(loads, 3, reason: 're-sync fetch in flight');

        bloc.add(const DeleteRacquet(2));
        await pumpEventQueue();
        expect((bloc.state as BagLoaded).racquets.map((r) => r.id), [1, 3]);

        // The re-sync resolves with the pre-delete list.
        resyncFetch.complete([first, second, created]);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect((bloc.state as BagLoaded).racquets.map((r) => r.id), [1, 3]);
        expect(loads, 3, reason: 'a dropped snapshot does not re-arm');
        await bloc.close();
      },
    );

    test('[P1] AC-1 a successful LoadBag cancels a pending re-sync', () async {
      final existing = racquet(id: 1, name: 'Wilson Blade 98');
      var loads = 0;
      when(() => mockBagEndpoint.getVirtualBag()).thenAnswer((_) {
        loads++;
        if (loads == 2) return Future.error(Exception('Connection timed out'));
        return Future.value([existing]);
      });
      final bloc = BagBloc(
        client: mockClient,
        offlineQueue: queue,
        resyncDelay: const Duration(milliseconds: 30),
      );
      bloc.add(const LoadBag());
      await pumpEventQueue();
      stubCreate(racquet(id: 2, name: 'Yonex Ezone 98'));

      bloc.add(addEzone());
      await pumpEventQueue();
      expect(loads, 2, reason: 'post-add reload failed, re-sync scheduled');

      bloc.add(const LoadBag());
      await pumpEventQueue();
      expect(loads, 3);

      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(loads, 3, reason: 'no re-sync after a successful LoadBag');
      await bloc.close();
    });

    test('[P1] AC-1 no re-sync runs after close()', () async {
      final existing = racquet(id: 1, name: 'Wilson Blade 98');
      final (bloc, _) = await loadedBlocWithFailingReload(
        [existing],
        resyncDelay: const Duration(milliseconds: 20),
      );
      stubCreate(racquet(id: 2, name: 'Yonex Ezone 98'));

      bloc.add(addEzone());
      await pumpEventQueue();
      await bloc.close();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 1 initial load + 1 post-add reload; no re-sync.
      verify(() => mockBagEndpoint.getVirtualBag()).called(2);
    });
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
        expect((bloc.state as BagLoaded).reauthRequired, isTrue);
        await bloc.close();
      },
    );

    test(
      '[P1] AC-3 BagException(401) is routed like ServerpodClientUnauthorized and reverts the gauge',
      () async {
        final target = racquet(id: 1, name: 'Wilson Blade 98');
        final (bloc, states) = await loadedBlocWithFailingReload([target]);
        when(() => mockSessionEndpoint.logSession(any())).thenThrow(
          BagException(message: 'expired', statusCode: 401),
        );
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

        expect(queue.pendingCount, 0);
        expect(onLoggedCalls, 0);
        // Optimistic gauge first, then reverted to the pre-log racquets.
        expect(
          states.first,
          isA<BagLoaded>().having(
            (s) => s.racquets.first.activeStringJob!.totalCourtHours,
            'hours',
            6.0,
          ),
        );
        final latest = bloc.state as BagLoaded;
        expect(latest.racquets, [target]);
        expect(latest.reauthRequired, isTrue);
        expect(latest.errorMessage, logSessionExpiredMessage);
        expect(
          states.whereType<BagLoaded>().map((s) => s.infoMessage),
          isNot(contains(BagBloc.offlineSavedMessage)),
        );
        await bloc.close();
      },
    );

    for (final statusCode in [400, 404]) {
      test(
        '[P1] logSession rejected with $statusCode is dropped, not queued (regression)',
        () async {
          final target = racquet(id: 1, name: 'Wilson Blade 98');
          final (bloc, _) = await loadedBlocWithFailingReload([target]);
          final rejection = BagException(
            message: 'rejected',
            statusCode: statusCode,
          );
          when(
            () => mockSessionEndpoint.logSession(any()),
          ).thenThrow(rejection);

          bloc.add(
            LogSession(
              racquetId: 1,
              startTime: DateTime.utc(2026, 10, 4, 17, 0),
              durationMinutes: 60,
              source: 'manual',
            ),
          );
          await pumpEventQueue();

          expect(queue.pendingCount, 0);
          final latest = bloc.state as BagLoaded;
          expect(latest.racquets, [target]);
          expect(latest.reauthRequired, isFalse);
          expect(
            latest.errorMessage,
            bagErrorMessage(
              BagOperation.logSession,
              rejection,
              racquet: target,
            ),
          );
          await bloc.close();
        },
      );
    }
  });
}
