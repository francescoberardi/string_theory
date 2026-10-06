import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';
import 'package:string_theory_flutter/domain/decay_engine.dart';
import 'package:string_theory_flutter/services/offline_session_queue.dart';

class MockClient extends Mock implements Client {}

class MockEndpointBag extends Mock implements EndpointBag {}

class MockEndpointSession extends Mock implements EndpointSession {}

class FakeSessionLog extends Fake implements SessionLog {}

/// Connectivity monitor whose status is driven by the test.
class TestConnectivityMonitor extends ConnectivityMonitor {
  void setConnected(bool connected) => notifyListeners(connected);
}

void main() {
  late MockClient mockClient;
  late MockEndpointBag mockBagEndpoint;
  late MockEndpointSession mockSessionEndpoint;

  final sampleRacquet = Racquet(
    id: 1,
    userId: 1,
    name: 'Babolat Pure Aero 2023',
    brand: 'Babolat',
    model: 'Pure Aero',
    isPrimary: true,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: DateTime.utc(2026, 10, 1),
  );

  setUpAll(() {
    registerFallbackValue(FakeSessionLog());
  });

  setUp(() {
    mockClient = MockClient();
    mockBagEndpoint = MockEndpointBag();
    mockSessionEndpoint = MockEndpointSession();
    when(() => mockClient.bag).thenReturn(mockBagEndpoint);
    when(() => mockClient.session).thenReturn(mockSessionEndpoint);
    when(
      () => mockBagEndpoint.bagUpdates(),
    ).thenAnswer((_) => const Stream<BagStreamMessage>.empty());
  });

  group('BagBloc Reactive State Management', () {
    test(
      '[P0] AC-2 should define BagBloc events and initial immutable state hierarchy',
      () {
        final bloc = BagBloc(client: mockClient);

        // Criterion-defining primary assertion: initial state is BagInitial
        expect(
          bloc.state,
          isA<BagInitial>(),
          reason: 'Initial state must be BagInitial',
        );

        // Event hierarchy checks
        expect(const LoadBag(), isA<BagEvent>());
        expect(const DeleteRacquet(1), isA<BagEvent>());
        expect(const SetPrimaryRacquet(1), isA<BagEvent>());
        expect(
          AddRacquet(
            name: 'Head Speed Pro',
            stringBrand: 'Head',
            stringModel: 'Hawk Touch',
            tension: 50.0,
            maxRatedHours: 20.0,
            stringingDate: DateTime.utc(2026, 10, 1),
          ),
          isA<BagEvent>(),
        );

        // State hierarchy checks
        expect(const BagInitial(), isA<BagState>());
        expect(const BagLoading(), isA<BagState>());
        expect(BagLoaded([sampleRacquet]), isA<BagState>());
        expect(const BagError('Failed to load bag'), isA<BagState>());

        bloc.close();
      },
    );

    test(
      '[P0] AC-3 should dispatch Serverpod client.bag RPC calls and emit BagLoaded with updated racquets',
      () async {
        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [sampleRacquet]);

        final bloc = BagBloc(client: mockClient);

        final states = <BagState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const LoadBag());
        await pumpEventQueue();

        // Criterion-defining primary assertion: BagLoaded is emitted with racquets
        expect(
          states,
          equals([
            const BagLoading(),
            BagLoaded([sampleRacquet]),
          ]),
          reason: 'Must emit BagLoading followed by BagLoaded with racquets',
        );

        verify(() => mockBagEndpoint.getVirtualBag()).called(1);

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      '[P0] AC-4 should handle RPC failures gracefully by emitting BagError with user-facing error messages',
      () async {
        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenThrow(Exception('Server unreachable'));

        final bloc = BagBloc(client: mockClient);

        final states = <BagState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const LoadBag());
        await pumpEventQueue();

        // Criterion-defining primary assertion: BagError is emitted on failure
        expect(
          states,
          equals([
            const BagLoading(),
            const BagError(
              "Couldn't load your bag. Check your connection and try again.",
            ),
          ]),
          reason: 'Must emit BagLoading followed by BagError on RPC failure',
        );

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      '[P0] AC-5 should verify comprehensive bloc_test coverage across AddRacquet, DeleteRacquet, and SetPrimaryRacquet transitions',
      () async {
        final secondRacquet = Racquet(
          id: 2,
          userId: 1,
          name: 'Head Speed Pro',
          brand: 'Head',
          model: 'Speed Pro',
          isPrimary: false,
          createdAt: DateTime.utc(2026, 10, 1),
          updatedAt: DateTime.utc(2026, 10, 1),
        );

        final secondRacquetPrimary = secondRacquet.copyWith(isPrimary: true);

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
        ).thenAnswer((_) async => secondRacquet);

        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [sampleRacquet, secondRacquet]);

        when(
          () => mockBagEndpoint.setPrimary(racquetId: 2),
        ).thenAnswer((_) async => secondRacquetPrimary);

        when(
          () => mockBagEndpoint.deleteRacquet(racquetId: 2),
        ).thenAnswer((_) async => true);

        final bloc = BagBloc(client: mockClient);

        final states = <BagState>[];
        final subscription = bloc.stream.listen(states.add);

        // --- AddRacquet transition → BagLoaded ---
        bloc.add(
          AddRacquet(
            name: 'Head Speed Pro',
            stringBrand: 'Head',
            stringModel: 'Hawk Touch',
            tension: 50.0,
            maxRatedHours: 20.0,
            stringingDate: DateTime.utc(2026, 10, 1),
          ),
        );
        await pumpEventQueue();

        expect(
          states.last,
          isA<BagLoaded>(),
          reason: 'AddRacquet must emit BagLoaded with refreshed racquets',
        );
        expect(
          (states.last as BagLoaded).racquets.length,
          equals(2),
          reason: 'Bag must contain both racquets after add',
        );
        verify(
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
        ).called(1);

        states.clear();

        // --- SetPrimaryRacquet transition → BagLoaded with updated flags ---
        // Switch primary to racquet 2 (currently non-primary) to produce
        // a distinct BagLoaded state (flutter_bloc deduplicates equal states).
        bloc.add(const SetPrimaryRacquet(2));
        await pumpEventQueue();

        expect(
          states.last,
          isA<BagLoaded>(),
          reason: 'SetPrimaryRacquet must emit BagLoaded with updated primary',
        );
        final afterSetPrimary = (states.last as BagLoaded).racquets;
        expect(
          afterSetPrimary.firstWhere((r) => r.id == 2).isPrimary,
          isTrue,
          reason: 'Designated racquet must be primary',
        );
        expect(
          afterSetPrimary.firstWhere((r) => r.id == 1).isPrimary,
          isFalse,
          reason: 'Previous primary must be demoted',
        );
        verify(() => mockBagEndpoint.setPrimary(racquetId: 2)).called(1);

        states.clear();

        // --- DeleteRacquet transition → BagLoaded with racquet removed ---
        bloc.add(const DeleteRacquet(2));
        await pumpEventQueue();

        expect(
          states.last,
          isA<BagLoaded>(),
          reason: 'DeleteRacquet must emit BagLoaded with racquet removed',
        );
        final afterDelete = (states.last as BagLoaded).racquets;
        expect(
          afterDelete.any((r) => r.id == 2),
          isFalse,
          reason: 'Deleted racquet must not appear in updated list',
        );
        expect(
          afterDelete.length,
          equals(1),
          reason: 'Only one racquet should remain',
        );
        verify(() => mockBagEndpoint.deleteRacquet(racquetId: 2)).called(1);

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      '[P0] AC-3 should create 3 demo racquets and emit BagLoaded when SeedSampleBag is dispatched',
      () async {
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
        ).thenAnswer((_) async => sampleRacquet);

        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [sampleRacquet]);

        final bloc = BagBloc(client: mockClient);

        final states = <BagState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const SeedSampleBag());
        await pumpEventQueue();

        expect(
          states,
          equals([
            const BagLoading(),
            BagLoaded([sampleRacquet]),
          ]),
          reason: 'SeedSampleBag must emit BagLoading then BagLoaded',
        );

        verify(
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
        ).called(3);
        verify(() => mockBagEndpoint.getVirtualBag()).called(1);

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'should emit [BagLoading, BagError] when SeedSampleBag encounters an RPC error',
      () async {
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
        ).thenThrow(Exception('Network timeout'));

        final bloc = BagBloc(client: mockClient);

        final states = <BagState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const SeedSampleBag());
        await pumpEventQueue();

        expect(
          states,
          equals([
            const BagLoading(),
            const BagError(
              "Couldn't load the sample bag. "
              'Check your connection and try again.',
            ),
          ]),
        );

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      '[Story 2.4] should call client.bag.fastForwardRacquetAge and emit BagLoaded with updated racquet',
      () async {
        final agedJob = StringJob(
          id: 1,
          userId: 1,
          racquetId: 1,
          materialCategory: StringMaterialCategory.coPoly,
          stringingDate: DateTime.utc(2026, 9, 1),
          currentHealthScore: 88,
          createdAt: DateTime.utc(2026, 10, 1),
        );
        final agedRacquet = sampleRacquet.copyWith(activeStringJob: agedJob);

        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [sampleRacquet]);

        when(
          () => mockBagEndpoint.fastForwardRacquetAge(
            racquetId: 1,
            days: 30,
          ),
        ).thenAnswer((_) async => agedRacquet);

        final bloc = BagBloc(client: mockClient);
        bloc.add(const LoadBag());
        await pumpEventQueue();

        bloc.add(const FastForwardRacquetAge(1, days: 30));
        await pumpEventQueue();

        expect(bloc.state, isA<BagLoaded>());
        final currentRacquets = (bloc.state as BagLoaded).racquets;
        expect(
          currentRacquets
              .firstWhere((r) => r.id == 1)
              .activeStringJob
              ?.currentHealthScore,
          equals(88),
        );

        verify(
          () => mockBagEndpoint.fastForwardRacquetAge(
            racquetId: 1,
            days: 30,
          ),
        ).called(1);

        await bloc.close();
      },
    );

    test(
      '[Story 2.4] should emit BagError when fastForwardRacquetAge encounters an RPC error',
      () async {
        when(
          () => mockBagEndpoint.fastForwardRacquetAge(
            racquetId: 1,
            days: 30,
          ),
        ).thenThrow(Exception('RPC failed'));

        final bloc = BagBloc(client: mockClient);
        bloc.add(const FastForwardRacquetAge(1, days: 30));
        await pumpEventQueue();

        expect(
          bloc.state,
          equals(
            const BagError(
              "Couldn't fast-forward this racquet. "
              'Check your connection and try again.',
            ),
          ),
        );

        await bloc.close();
      },
    );

    test(
      '[Story 2.4] should fetch virtual bag and emit BagLoaded when FastForwardRacquetAge dispatched from unloaded state',
      () async {
        final agedJob = StringJob(
          id: 1,
          userId: 1,
          racquetId: 1,
          materialCategory: StringMaterialCategory.coPoly,
          stringingDate: DateTime.utc(2026, 9, 1),
          currentHealthScore: 88,
          createdAt: DateTime.utc(2026, 10, 1),
        );
        final agedRacquet = sampleRacquet.copyWith(activeStringJob: agedJob);

        when(
          () => mockBagEndpoint.fastForwardRacquetAge(
            racquetId: 1,
            days: 30,
          ),
        ).thenAnswer((_) async => agedRacquet);

        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [agedRacquet]);

        final bloc = BagBloc(client: mockClient);
        bloc.add(const FastForwardRacquetAge(1, days: 30));
        await pumpEventQueue();

        expect(bloc.state, isA<BagLoaded>());
        expect(
          (bloc.state as BagLoaded)
              .racquets
              .first
              .activeStringJob
              ?.currentHealthScore,
          equals(88),
        );

        verify(() => mockBagEndpoint.getVirtualBag()).called(1);

        await bloc.close();
      },
    );
  });

  group('[Story 3.2] BagBloc real-time BagStreamMessage updates', () {
    late StreamController<BagStreamMessage> controller;

    final strungJob = StringJob(
      id: 10,
      userId: 1,
      racquetId: 1,
      materialCategory: StringMaterialCategory.coPoly,
      stringingDate: DateTime.utc(2026, 9, 20),
      totalCourtHours: 2.0,
      currentHealthScore: 90,
      createdAt: DateTime.utc(2026, 9, 20),
    );
    final racquetA = sampleRacquet.copyWith(activeStringJob: strungJob);
    final racquetB = Racquet(
      id: 2,
      userId: 1,
      name: 'Head Speed Pro',
      isPrimary: false,
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 1),
      activeStringJob: strungJob.copyWith(id: 20, racquetId: 2),
    );

    BagStreamMessage messageFor(int racquetId) => BagStreamMessage(
      eventType: 'sessionLogged',
      racquetId: racquetId,
      healthScore: 82,
      totalCourtHours: 3.5,
      timestamp: DateTime.utc(2026, 10, 4),
    );

    setUp(() {
      controller = StreamController<BagStreamMessage>.broadcast();
      when(
        () => mockBagEndpoint.bagUpdates(),
      ).thenAnswer((_) => controller.stream);
      when(
        () => mockBagEndpoint.getVirtualBag(),
      ).thenAnswer((_) async => [racquetA, racquetB]);
    });

    tearDown(() async {
      await controller.close();
    });

    // Serverpod models compare by identity, so match on field values.
    Matcher loadedWithJob(int racquetId, int healthScore, double hours) =>
        isA<BagLoaded>().having(
          (s) =>
              s.racquets.firstWhere((r) => r.id == racquetId).activeStringJob,
          'racquet $racquetId active job',
          isA<StringJob>()
              .having(
                (j) => j.currentHealthScore,
                'currentHealthScore',
                healthScore,
              )
              .having((j) => j.totalCourtHours, 'totalCourtHours', hours),
        );

    blocTest<BagBloc, BagState>(
      'subscribes to bagUpdates once after the bag loads',
      build: () => BagBloc(client: mockClient),
      act: (bloc) async {
        bloc.add(const LoadBag());
        await pumpEventQueue();
        bloc.add(const LoadBag());
        await pumpEventQueue();
        expect(controller.hasListener, isTrue);
      },
      verify: (_) {
        verify(() => mockBagEndpoint.bagUpdates()).called(1);
      },
    );

    blocTest<BagBloc, BagState>(
      'patches the matching racquet health score and court hours in place',
      build: () => BagBloc(client: mockClient),
      act: (bloc) async {
        bloc.add(const LoadBag());
        await pumpEventQueue();
        controller.add(messageFor(1));
        await pumpEventQueue();
      },
      expect: () => [
        const BagLoading(),
        BagLoaded([racquetA, racquetB]),
        allOf(
          loadedWithJob(1, 82, 3.5),
          loadedWithJob(2, 90, 2.0),
          isA<BagLoaded>().having(
            (s) => s.racquets[1],
            'untouched racquet',
            same(racquetB),
          ),
        ),
      ],
      verify: (_) {
        verify(() => mockBagEndpoint.getVirtualBag()).called(1);
      },
    );

    blocTest<BagBloc, BagState>(
      'ignores messages for racquets not in the loaded bag',
      build: () => BagBloc(client: mockClient),
      act: (bloc) async {
        bloc.add(const LoadBag());
        await pumpEventQueue();
        controller.add(messageFor(999));
        await pumpEventQueue();
      },
      expect: () => [
        const BagLoading(),
        BagLoaded([racquetA, racquetB]),
      ],
    );

    blocTest<BagBloc, BagState>(
      'ignores messages while the bag is not loaded',
      build: () => BagBloc(client: mockClient),
      act: (bloc) => bloc.add(BagStreamReceived(messageFor(1))),
      expect: () => <BagState>[],
    );

    blocTest<BagBloc, BagState>(
      'clears the subscription on stream error without emitting BagError, '
      'and re-subscribes on the next LoadBag',
      build: () => BagBloc(client: mockClient),
      act: (bloc) async {
        bloc.add(const LoadBag());
        await pumpEventQueue();
        controller.addError(Exception('socket closed'));
        await pumpEventQueue();
        bloc.add(const LoadBag());
        await pumpEventQueue();
      },
      expect: () => [
        const BagLoading(),
        BagLoaded([racquetA, racquetB]),
        const BagLoading(),
        BagLoaded([racquetA, racquetB]),
      ],
      verify: (_) {
        verify(() => mockBagEndpoint.bagUpdates()).called(2);
      },
    );

    blocTest<BagBloc, BagState>(
      'clears the subscription when the stream completes, '
      'and re-subscribes on the next LoadBag',
      build: () => BagBloc(client: mockClient),
      act: (bloc) async {
        final first = StreamController<BagStreamMessage>();
        when(
          () => mockBagEndpoint.bagUpdates(),
        ).thenAnswer((_) => first.stream);
        bloc.add(const LoadBag());
        await pumpEventQueue();
        expect(first.hasListener, isTrue);

        final second = StreamController<BagStreamMessage>();
        when(
          () => mockBagEndpoint.bagUpdates(),
        ).thenAnswer((_) => second.stream);
        await first.close();
        await pumpEventQueue();

        bloc.add(const LoadBag());
        await pumpEventQueue();
        expect(second.hasListener, isTrue);
      },
      verify: (_) {
        verify(() => mockBagEndpoint.bagUpdates()).called(2);
      },
    );

    test('close() cancels the bagUpdates subscription', () async {
      var cancelled = false;
      controller.onCancel = () => cancelled = true;

      final bloc = BagBloc(client: mockClient);
      bloc.add(const LoadBag());
      await pumpEventQueue();
      expect(controller.hasListener, isTrue);

      await bloc.close();

      expect(cancelled, isTrue);
    });
  });

  group('Story 3.4: LogSession', () {
    // A permanent server rejection; network failures are queued offline
    // instead (Story 3.5).
    final rejection = BagException(
      message: 'Racquet not found or unauthorized',
      statusCode: 404,
    );
    const goneMessage = 'That racquet is no longer in your bag.';

    test(
      'dispatches client.session.logSession and emits BagLoaded with updated racquets',
      () async {
        final now = DateTime.utc(2026, 10, 4, 18, 0);
        final sessionLog = SessionLog(
          userId: 1,
          racquetId: 1,
          startTime: now,
          durationMinutes: 90,
          courtSurface: 'Clay',
          notes: 'Great match',
          source: 'simulated',
          externalWorkoutId: 'sim-123',
        );
        when(
          () => mockSessionEndpoint.logSession(any()),
        ).thenAnswer((_) async => sessionLog);
        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [sampleRacquet]);

        final bloc = BagBloc(client: mockClient);
        final states = <BagState>[];
        final subscription = bloc.stream.listen(states.add);
        var loggedCalls = 0;

        bloc.add(
          LogSession(
            racquetId: 1,
            startTime: now,
            durationMinutes: 90,
            courtSurface: 'Clay',
            notes: 'Great match',
            source: 'simulated',
            externalWorkoutId: 'sim-123',
            onLogged: () => loggedCalls++,
          ),
        );
        await pumpEventQueue();

        verify(
          () => mockSessionEndpoint.logSession(
            any(
              that: isA<SessionLog>()
                  .having((s) => s.racquetId, 'racquetId', 1)
                  .having((s) => s.startTime, 'startTime', now)
                  .having((s) => s.durationMinutes, 'durationMinutes', 90)
                  .having((s) => s.courtSurface, 'courtSurface', 'Clay')
                  .having((s) => s.notes, 'notes', 'Great match')
                  .having((s) => s.source, 'source', 'simulated')
                  .having(
                    (s) => s.externalWorkoutId,
                    'externalWorkoutId',
                    'sim-123',
                  ),
            ),
          ),
        ).called(1);
        verify(() => mockBagEndpoint.getVirtualBag()).called(1);
        expect(
          states,
          equals([
            BagLoaded([sampleRacquet]),
          ]),
        );
        expect(loggedCalls, 1);

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'retains loaded racquets with transient errorMessage when the server rejects the session while BagLoaded',
      () async {
        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [sampleRacquet]);
        when(
          () => mockSessionEndpoint.logSession(any()),
        ).thenThrow(rejection);

        final bloc = BagBloc(client: mockClient);
        bloc.add(const LoadBag());
        await pumpEventQueue();

        final states = <BagState>[];
        final subscription = bloc.stream.listen(states.add);
        var loggedCalls = 0;

        bloc.add(
          LogSession(
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 18, 0),
            durationMinutes: 60,
            source: 'manual',
            onLogged: () => loggedCalls++,
          ),
        );
        await pumpEventQueue();

        expect(
          states,
          equals([
            BagLoaded(
              [sampleRacquet],
              errorMessage: goneMessage,
            ),
          ]),
        );
        expect(loggedCalls, 0);

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'emits BagError when the server rejects the session without BagLoaded',
      () async {
        when(
          () => mockSessionEndpoint.logSession(any()),
        ).thenThrow(rejection);

        final bloc = BagBloc(client: mockClient);
        final states = <BagState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(
          LogSession(
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 18, 0),
            durationMinutes: 60,
            source: 'manual',
          ),
        );
        await pumpEventQueue();

        expect(
          states,
          equals([
            BagError(goneMessage),
          ]),
        );

        await subscription.cancel();
        await bloc.close();
      },
    );
    test(
      'emits the error again when the same LogSession failure repeats',
      () async {
        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [sampleRacquet]);
        when(
          () => mockSessionEndpoint.logSession(any()),
        ).thenThrow(rejection);

        final bloc = BagBloc(client: mockClient);
        bloc.add(const LoadBag());
        await pumpEventQueue();

        final states = <BagState>[];
        final subscription = bloc.stream.listen(states.add);
        final event = LogSession(
          racquetId: 1,
          startTime: DateTime.utc(2026, 10, 4, 18, 0),
          durationMinutes: 60,
          source: 'manual',
        );

        bloc.add(event);
        await pumpEventQueue();
        bloc.add(event);
        await pumpEventQueue();

        final errorState = BagLoaded(
          [sampleRacquet],
          errorMessage: goneMessage,
        );
        expect(
          states,
          equals([
            errorState,
            BagLoaded([sampleRacquet]),
            errorState,
          ]),
        );

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'treats a bag refresh failure after a successful logSession as logged',
      () async {
        when(
          () => mockSessionEndpoint.logSession(any()),
        ).thenAnswer(
          (invocation) async => invocation.positionalArguments.first,
        );
        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [sampleRacquet]);

        final bloc = BagBloc(client: mockClient);
        bloc.add(const LoadBag());
        await pumpEventQueue();

        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenThrow(Exception('refresh failed'));

        final states = <BagState>[];
        final subscription = bloc.stream.listen(states.add);
        var loggedCalls = 0;

        bloc.add(
          LogSession(
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 18, 0),
            durationMinutes: 60,
            source: 'manual',
            onLogged: () => loggedCalls++,
          ),
        );
        await pumpEventQueue();

        expect(loggedCalls, 1);
        expect(states, isEmpty);
        expect(bloc.state, BagLoaded([sampleRacquet]));

        await subscription.cancel();
        await bloc.close();
      },
    );
  });

  group('Friendly error messages', () {
    const connection = ' Check your connection and try again.';
    final stringingDate = DateTime.utc(2026, 10, 1);
    final strung = Racquet(
      id: 1,
      userId: 1,
      name: 'Wilson Blade 98',
      isPrimary: true,
      activeStringJob: StringJob(
        id: 10,
        userId: 1,
        racquetId: 1,
        materialCategory: StringMaterialCategory.coPoly,
        stringingDate: stringingDate,
        maxRatedHours: 20.0,
        totalCourtHours: 5.0,
        currentHealthScore: 76,
        isActive: true,
      ),
      createdAt: stringingDate,
      updatedAt: stringingDate,
    );
    final unstrung = Racquet(
      id: 2,
      userId: 1,
      name: 'Head Radical MP',
      isPrimary: false,
      createdAt: stringingDate,
      updatedAt: stringingDate,
    );
    const rawText = 'internal server detail';
    BagException rejection(int statusCode) =>
        BagException(message: rawText, statusCode: statusCode);

    late List<String> printed;

    setUp(() {
      printed = [];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) printed.add(message);
      };
      addTearDown(() => debugPrint = original);
    });

    Future<(BagBloc, List<BagState>)> loadedBloc({
      OfflineSessionQueue? queue,
    }) async {
      when(
        () => mockBagEndpoint.getVirtualBag(),
      ).thenAnswer((_) async => [strung, unstrung]);
      final bloc = BagBloc(client: mockClient, offlineQueue: queue);
      bloc.add(const LoadBag());
      await pumpEventQueue();
      final states = <BagState>[];
      final subscription = bloc.stream.listen(states.add);
      addTearDown(subscription.cancel);
      return (bloc, states);
    }

    LogSession logFor(int racquetId) => LogSession(
      racquetId: racquetId,
      startTime: DateTime.utc(2026, 10, 4, 18, 0),
      durationMinutes: 60,
      source: 'manual',
    );

    /// Asserts [message] carries none of the raw error.
    void expectClean(String? message) {
      expect(message, isNotNull);
      expect(message, isNot(contains(rawText)));
      expect(message, isNot(contains('BagException')));
      expect(message, isNot(contains('statusCode')));
      expect(message, isNot(contains('Exception')));
    }

    test(
      'log session on an unstrung racquet (400) names it and reverts the gauge',
      () async {
        when(
          () => mockSessionEndpoint.logSession(any()),
        ).thenThrow(rejection(400));
        final (bloc, states) = await loadedBloc();

        bloc.add(logFor(2));
        await pumpEventQueue();

        final last = states.last as BagLoaded;
        expect(last.racquets, [strung, unstrung]);
        expect(
          last.errorMessage,
          '"Head Radical MP" has no strings mounted. '
          'Restring it before logging a session.',
        );
        expectClean(last.errorMessage);
        expect(
          printed,
          contains(
            'BagBloc: logSession failed: ${rejection(400)}',
          ),
        );
        await bloc.close();
      },
    );

    test(
      'log session duplicate workout (409) keeps the clear-then-emit pattern',
      () async {
        when(
          () => mockSessionEndpoint.logSession(any()),
        ).thenThrow(rejection(409));
        final (bloc, states) = await loadedBloc();

        bloc.add(logFor(1));
        await pumpEventQueue();

        expect(states.length, 3, reason: 'optimistic, cleared, error');
        expect(
          states[1],
          BagLoaded([strung, unstrung]),
        );
        final last = states.last as BagLoaded;
        expect(last.racquets, [strung, unstrung]);
        expect(
          last.errorMessage,
          'This workout is already logged on another account.',
        );
        expectClean(last.errorMessage);
        await bloc.close();
      },
    );

    test('offline enqueue failure surfaces a save error', () async {
      final queue = OfflineSessionQueue(storage: _FailingWriteStorage());
      when(() => mockSessionEndpoint.logSession(any())).thenThrow(
        const ServerpodClientNetworkException('offline'),
      );
      final (bloc, states) = await loadedBloc(queue: queue);

      bloc.add(logFor(1));
      await pumpEventQueue();

      final last = states.last as BagLoaded;
      expect(last.racquets, [strung, unstrung]);
      expect(
        last.errorMessage,
        "Couldn't save this session. Please try again.",
      );
      expect(last.errorMessage, isNot(contains('disk full')));
      expect(
        printed.where(
          (line) =>
              line.startsWith('BagBloc: saveSessionOffline failed:') &&
              line.contains('disk full'),
        ),
        isNotEmpty,
      );
      await bloc.close();
    });

    test('delete of a vanished racquet (404)', () async {
      when(
        () => mockBagEndpoint.deleteRacquet(racquetId: 1),
      ).thenThrow(rejection(404));
      final (bloc, states) = await loadedBloc();

      bloc.add(const DeleteRacquet(1));
      await pumpEventQueue();

      expect(states, [
        const BagError('That racquet is no longer in your bag.'),
      ]);
      expect(
        printed,
        contains('BagBloc: deleteRacquet failed: ${rejection(404)}'),
      );
      await bloc.close();
    });

    test('add racquet rejected (400) names the racquet', () async {
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
      ).thenThrow(rejection(400));
      final (bloc, states) = await loadedBloc();

      bloc.add(
        AddRacquet(
          name: 'Yonex Ezone',
          stringBrand: 'Yonex',
          stringModel: 'Poly Tour Pro',
          tension: 50.0,
          maxRatedHours: 20.0,
          stringingDate: DateTime.utc(2026, 10, 1),
        ),
      );
      await pumpEventQueue();

      expect(states, [
        const BagError(
          "Couldn't add \"Yonex Ezone\". "
          'Check the racquet details and try again.',
        ),
      ]);
      await bloc.close();
    });

    test('set primary network failure', () async {
      when(
        () => mockBagEndpoint.setPrimary(racquetId: 2),
      ).thenThrow(Exception(rawText));
      final (bloc, states) = await loadedBloc();

      bloc.add(const SetPrimaryRacquet(2));
      await pumpEventQueue();

      expect(states, [
        const BagError("Couldn't set your primary racquet.$connection"),
      ]);
      expect(
        printed,
        contains('BagBloc: setPrimaryRacquet failed: Exception: $rawText'),
      );
      await bloc.close();
    });

    test('expired session (401) on load', () async {
      when(
        () => mockBagEndpoint.getVirtualBag(),
      ).thenThrow(ServerpodClientUnauthorized());
      final bloc = BagBloc(client: mockClient);
      final states = <BagState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const LoadBag());
      await pumpEventQueue();

      expect(states, [
        const BagLoading(),
        const BagError(
          'Your session expired. Restart the app to sign in again.',
        ),
      ]);
      expect(
        printed.where((line) => line.startsWith('BagBloc: loadBag failed:')),
        isNotEmpty,
      );
      await subscription.cancel();
      await bloc.close();
    });

    test('restring of a vanished racquet (404) reverts the gauge', () async {
      when(
        () => mockBagEndpoint.restringRacquet(
          racquetId: any(named: 'racquetId'),
          keepSame: any(named: 'keepSame'),
          newSpecs: any(named: 'newSpecs'),
          materialCategory: any(named: 'materialCategory'),
          stringBrand: any(named: 'stringBrand'),
          stringModel: any(named: 'stringModel'),
          tension: any(named: 'tension'),
          maxRatedHours: any(named: 'maxRatedHours'),
          restringDate: any(named: 'restringDate'),
          simulateFailure: any(named: 'simulateFailure'),
        ),
      ).thenThrow(rejection(404));
      final (bloc, states) = await loadedBloc();

      bloc.add(const RestringRacquet(1));
      await pumpEventQueue();

      final last = states.last as BagLoaded;
      expect(last.racquets, [strung, unstrung]);
      expect(last.errorMessage, 'That racquet is no longer in your bag.');
      await bloc.close();
    });
  });

  group('Story 3.5: Offline session queue & auto-reconnection sync', () {
    final stringingDate = DateTime.now().toUtc().subtract(
      const Duration(days: 10),
    );
    Racquet racquetWithJob({double hours = 5.0, int health = 76}) => Racquet(
      id: 1,
      userId: 1,
      name: 'Wilson Blade 98',
      isPrimary: true,
      activeStringJob: StringJob(
        id: 10,
        userId: 1,
        racquetId: 1,
        materialCategory: StringMaterialCategory.coPoly,
        brand: 'Luxilon',
        model: 'ALU Power',
        stringingDate: stringingDate,
        installedTension: 52.0,
        maxRatedHours: 20.0,
        totalCourtHours: hours,
        currentHealthScore: health,
        isActive: true,
        createdAt: stringingDate,
      ),
      createdAt: stringingDate,
      updatedAt: stringingDate,
    );

    int expectedHealth(double hours) => DecayEngine.calculateHealth(
      hoursPlayed: hours,
      maxRatedHours: 20.0,
      stringingDate: stringingDate,
      materialCategory: StringMaterialCategory.coPoly,
    );

    late OfflineSessionQueue queue;

    setUp(() {
      queue = OfflineSessionQueue(storage: InMemorySessionQueueStorage());
    });

    Future<BagBloc> loadedBloc(List<Racquet> racquets) async {
      when(
        () => mockBagEndpoint.getVirtualBag(),
      ).thenAnswer((_) async => racquets);
      final bloc = BagBloc(client: mockClient, offlineQueue: queue);
      bloc.add(const LoadBag());
      await pumpEventQueue();
      return bloc;
    }

    test('applyOptimisticSession recalculates health with DecayEngine', () {
      final other = sampleRacquet.copyWith(id: 2);
      final updated = BagBloc.applyOptimisticSession(
        [racquetWithJob(), other],
        racquetId: 1,
        durationMinutes: 90,
      );

      final job = updated.first.activeStringJob!;
      expect(job.totalCourtHours, 6.5);
      expect(job.currentHealthScore, expectedHealth(6.5));
      expect(updated.last, same(other));
    });

    test(
      'queues the session with optimistic decay when the RPC fails with a network error',
      () async {
        final bloc = await loadedBloc([racquetWithJob()]);
        when(() => mockSessionEndpoint.logSession(any())).thenThrow(
          const ServerpodClientNetworkException('Failed host lookup'),
        );
        var loggedCalls = 0;

        bloc.add(
          LogSession(
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 17, 0),
            durationMinutes: 60,
            source: 'manual',
            onLogged: () => loggedCalls++,
          ),
        );
        await pumpEventQueue();

        final state = bloc.state as BagLoaded;
        final job = state.racquets.single.activeStringJob!;
        expect(job.totalCourtHours, 6.0);
        expect(job.currentHealthScore, expectedHealth(6.0));
        expect(state.pendingSyncCount, 1);
        expect(state.infoMessage, BagBloc.offlineSavedMessage);
        expect(state.errorMessage, isNull);
        expect(loggedCalls, 1);
        expect(
          queue.pending.single.externalWorkoutId,
          startsWith('client_offline_'),
        );

        await bloc.close();
      },
    );

    test('emits the optimistic gauge before the RPC completes', () async {
      final bloc = await loadedBloc([racquetWithJob()]);
      final gate = Completer<SessionLog>();
      when(
        () => mockSessionEndpoint.logSession(any()),
      ).thenAnswer((_) => gate.future);

      bloc.add(
        LogSession(
          racquetId: 1,
          startTime: DateTime.utc(2026, 10, 4, 17, 0),
          durationMinutes: 120,
          source: 'manual',
        ),
      );
      await pumpEventQueue();

      final job = (bloc.state as BagLoaded).racquets.single.activeStringJob!;
      expect(job.totalCourtHours, 7.0);
      expect(job.currentHealthScore, expectedHealth(7.0));

      gate.complete(FakeSessionLog());
      await pumpEventQueue();
      await bloc.close();
    });

    test(
      'preserves the externalWorkoutId of a detected workout when queued',
      () async {
        final bloc = await loadedBloc([racquetWithJob()]);
        when(
          () => mockSessionEndpoint.logSession(any()),
        ).thenThrow(TimeoutException('no response'));

        bloc.add(
          LogSession(
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 17, 0),
            durationMinutes: 90,
            source: 'healthkit',
            externalWorkoutId: 'hk-abc',
          ),
        );
        await pumpEventQueue();

        expect(queue.pending.single.externalWorkoutId, 'hk-abc');
        expect(queue.pending.single.source, 'healthkit');
        await bloc.close();
      },
    );

    test(
      'reverts the optimistic gauge when the server rejects the session',
      () async {
        final original = racquetWithJob();
        final bloc = await loadedBloc([original]);
        final rejection = BagException(
          message: 'Racquet has no active string job',
          statusCode: 400,
        );
        when(() => mockSessionEndpoint.logSession(any())).thenThrow(rejection);

        bloc.add(
          LogSession(
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 17, 0),
            durationMinutes: 60,
            source: 'manual',
          ),
        );
        await pumpEventQueue();

        expect(
          bloc.state,
          BagLoaded(
            [original],
            errorMessage: "Couldn't log this session. Please try again.",
          ),
        );
        expect(queue.pendingCount, 0);
        await bloc.close();
      },
    );

    test(
      'queues without calling the server while the monitor reports offline',
      () async {
        final monitor = TestConnectivityMonitor();
        when(() => mockClient.connectivityMonitor).thenReturn(monitor);
        final bloc = await loadedBloc([racquetWithJob()]);
        monitor.setConnected(false);

        bloc.add(
          LogSession(
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 17, 0),
            durationMinutes: 60,
            source: 'manual',
          ),
        );
        await pumpEventQueue();

        verifyNever(() => mockSessionEndpoint.logSession(any()));
        expect((bloc.state as BagLoaded).pendingSyncCount, 1);
        await bloc.close();
      },
    );

    test(
      'SyncOfflineSessions drains the queue, reconciles with getVirtualBag and reports the count',
      () async {
        await queue.enqueue(
          SessionLog(
            userId: 0,
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 15, 0),
            durationMinutes: 60,
            source: 'manual',
          ),
        );
        await queue.enqueue(
          SessionLog(
            userId: 0,
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 17, 0),
            durationMinutes: 60,
            source: 'healthkit',
            externalWorkoutId: 'hk-2',
          ),
        );
        when(() => mockSessionEndpoint.logSession(any())).thenThrow(
          const ServerpodClientNetworkException('offline'),
        );
        final bloc = await loadedBloc([racquetWithJob()]);
        expect((bloc.state as BagLoaded).pendingSyncCount, 2);

        final authoritative = racquetWithJob(hours: 7.0, health: 60);
        when(() => mockSessionEndpoint.logSession(any())).thenAnswer(
          (invocation) async =>
              invocation.positionalArguments.first as SessionLog,
        );
        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [authoritative]);

        bloc.add(const SyncOfflineSessions());
        await pumpEventQueue();

        expect(queue.pendingCount, 0);
        expect(
          bloc.state,
          BagLoaded(
            [authoritative],
            infoMessage: 'Synced 2 offline sessions',
          ),
        );
        await bloc.close();
      },
    );

    test(
      'LoadBag drains a pending queue in the background on launch',
      () async {
        await queue.enqueue(
          SessionLog(
            userId: 0,
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 17, 0),
            durationMinutes: 60,
            source: 'manual',
          ),
        );
        when(() => mockSessionEndpoint.logSession(any())).thenAnswer(
          (invocation) async =>
              invocation.positionalArguments.first as SessionLog,
        );

        final bloc = await loadedBloc([racquetWithJob()]);

        verify(() => mockSessionEndpoint.logSession(any())).called(1);
        expect(queue.pendingCount, 0);
        final state = bloc.state as BagLoaded;
        expect(state.pendingSyncCount, 0);
        expect(state.infoMessage, 'Synced 1 offline session');
        await bloc.close();
      },
    );

    test(
      'keeps unsynced sessions and their optimistic decay when connectivity drops mid-sync',
      () async {
        when(() => mockSessionEndpoint.logSession(any())).thenThrow(
          const ServerpodClientNetworkException('offline'),
        );
        final bloc = await loadedBloc([racquetWithJob()]);
        for (final id in ['hk-1', 'hk-2']) {
          bloc.add(
            LogSession(
              racquetId: 1,
              startTime: DateTime.utc(2026, 10, 4, 17, 0),
              durationMinutes: 60,
              source: 'healthkit',
              externalWorkoutId: id,
            ),
          );
          await pumpEventQueue();
        }
        expect(queue.pendingCount, 2);

        var calls = 0;
        when(() => mockSessionEndpoint.logSession(any())).thenAnswer((
          invocation,
        ) async {
          calls++;
          if (calls == 2) {
            throw const ServerpodClientNetworkException('dropped');
          }
          return invocation.positionalArguments.first as SessionLog;
        });
        // Server has counted the first session only.
        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [racquetWithJob(hours: 6.0, health: 70)]);

        bloc.add(const SyncOfflineSessions());
        await pumpEventQueue();

        expect(queue.pending.single.externalWorkoutId, 'hk-2');
        final state = bloc.state as BagLoaded;
        expect(state.pendingSyncCount, 1);
        // The still-queued hour stays applied on top of the server state.
        final job = state.racquets.single.activeStringJob!;
        expect(job.totalCourtHours, 7.0);
        expect(job.currentHealthScore, expectedHealth(7.0));
        await bloc.close();
      },
    );

    test('reconnection triggers an automatic sync of the queue', () async {
      final monitor = TestConnectivityMonitor();
      when(() => mockClient.connectivityMonitor).thenReturn(monitor);
      when(() => mockSessionEndpoint.logSession(any())).thenThrow(
        const ServerpodClientNetworkException('offline'),
      );
      final bloc = await loadedBloc([racquetWithJob()]);
      monitor.setConnected(false);
      bloc.add(
        LogSession(
          racquetId: 1,
          startTime: DateTime.utc(2026, 10, 4, 17, 0),
          durationMinutes: 60,
          source: 'manual',
        ),
      );
      await pumpEventQueue();
      expect(queue.pendingCount, 1);

      when(() => mockSessionEndpoint.logSession(any())).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.first as SessionLog,
      );
      monitor.setConnected(true);
      await pumpEventQueue();

      verify(() => mockSessionEndpoint.logSession(any())).called(1);
      expect(queue.pendingCount, 0);
      expect(
        (bloc.state as BagLoaded).infoMessage,
        'Synced 1 offline session',
      );
      await bloc.close();
    });

    test(
      're-sending a session the server already stored drains it once',
      () async {
        when(() => mockSessionEndpoint.logSession(any())).thenThrow(
          const ServerpodClientNetworkException('offline'),
        );
        final bloc = await loadedBloc([racquetWithJob()]);
        bloc.add(
          LogSession(
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 17, 0),
            durationMinutes: 60,
            source: 'healthkit',
            externalWorkoutId: 'hk-dup',
          ),
        );
        await pumpEventQueue();

        final sentKeys = <String?>[];
        final stored = <String>{};
        when(() => mockSessionEndpoint.logSession(any())).thenAnswer((
          invocation,
        ) async {
          final log = invocation.positionalArguments.first as SessionLog;
          sentKeys.add(log.externalWorkoutId);
          stored.add(log.externalWorkoutId!);
          return log.copyWith(id: 1);
        });

        bloc.add(const SyncOfflineSessions());
        bloc.add(const SyncOfflineSessions());
        await pumpEventQueue();

        expect(sentKeys, ['hk-dup']);
        expect(stored, {'hk-dup'});
        expect(queue.pendingCount, 0);
        await bloc.close();
      },
    );

    test(
      'SyncOfflineSessions discards permanently rejected sessions, reconciles bag, and leaves infoMessage null',
      () async {
        await queue.enqueue(
          SessionLog(
            userId: 0,
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 17, 0),
            durationMinutes: 60,
            source: 'manual',
            externalWorkoutId: 'hk-bad',
          ),
        );
        when(() => mockSessionEndpoint.logSession(any())).thenThrow(
          const ServerpodClientNetworkException('offline'),
        );
        final initial = racquetWithJob();
        final bloc = await loadedBloc([initial]);
        expect((bloc.state as BagLoaded).pendingSyncCount, 1);

        // Server permanently rejects the session on sync
        when(() => mockSessionEndpoint.logSession(any())).thenThrow(
          BagException(
            message: 'Racquet not found or unauthorized',
            statusCode: 404,
          ),
        );
        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [initial]);

        bloc.add(const SyncOfflineSessions());
        await pumpEventQueue();

        expect(queue.pendingCount, 0);
        final state = bloc.state as BagLoaded;
        expect(state.pendingSyncCount, 0);
        expect(state.infoMessage, isNull);
        expect(
          state.racquets.single.activeStringJob!.totalCourtHours,
          initial.activeStringJob!.totalCourtHours,
        );
        await bloc.close();
      },
    );

    test('removes the connectivity listener on close', () async {
      final monitor = TestConnectivityMonitor();
      when(() => mockClient.connectivityMonitor).thenReturn(monitor);
      final bloc = BagBloc(client: mockClient, offlineQueue: queue);
      await bloc.close();

      // Would throw "Cannot add new events after calling close" if still
      // registered.
      monitor.setConnected(true);
    });
  });

  group('Story 4.2: RestringRacquet', () {
    StringJob jobFor({
      required int id,
      int health = 30,
      double hours = 18.0,
      String brand = 'Luxilon',
      String model = 'ALU Power',
      StringMaterialCategory category = StringMaterialCategory.coPoly,
      double tension = 52.0,
      double maxHours = 20.0,
      DateTime? stringingDate,
    }) {
      return StringJob(
        id: id,
        userId: 1,
        racquetId: 1,
        materialCategory: category,
        brand: brand,
        model: model,
        stringingDate: stringingDate ?? DateTime.utc(2026, 8, 1),
        installedTension: tension,
        maxRatedHours: maxHours,
        totalCourtHours: hours,
        currentHealthScore: health,
        isActive: true,
        createdAt: DateTime.utc(2026, 8, 1),
      );
    }

    final deadRacquet = sampleRacquet.copyWith(
      activeStringJob: jobFor(id: 10),
    );
    final freshRacquet = sampleRacquet.copyWith(
      activeStringJob: jobFor(
        id: 11,
        health: 100,
        hours: 0.0,
        stringingDate: DateTime.utc(2026, 10, 5),
      ),
    );

    void stubRestring(Future<Racquet> Function() answer) {
      when(
        () => mockBagEndpoint.restringRacquet(
          racquetId: any(named: 'racquetId'),
          keepSame: any(named: 'keepSame'),
          newSpecs: any(named: 'newSpecs'),
          materialCategory: any(named: 'materialCategory'),
          stringBrand: any(named: 'stringBrand'),
          stringModel: any(named: 'stringModel'),
          tension: any(named: 'tension'),
          maxRatedHours: any(named: 'maxRatedHours'),
          restringDate: any(named: 'restringDate'),
          simulateFailure: any(named: 'simulateFailure'),
        ),
      ).thenAnswer((_) => answer());
    }

    Future<(BagBloc, List<BagState>)> loadedBloc() async {
      when(
        () => mockBagEndpoint.getVirtualBag(),
      ).thenAnswer((_) async => [deadRacquet]);
      final bloc = BagBloc(client: mockClient);
      bloc.add(const LoadBag());
      await pumpEventQueue();
      final states = <BagState>[];
      bloc.stream.listen(states.add);
      return (bloc, states);
    }

    test('RestringRacquet defaults to keepSame and has value equality', () {
      expect(const RestringRacquet(1).keepSame, isTrue);
      expect(
        const RestringRacquet(1, stringBrand: 'Head'),
        const RestringRacquet(1, stringBrand: 'Head'),
      );
      expect(
        const RestringRacquet(1),
        isNot(const RestringRacquet(2)),
      );
    });

    test('BagLoaded includes successMessage in equality', () {
      expect(
        const BagLoaded([], successMessage: 'a'),
        isNot(const BagLoaded([], successMessage: 'b')),
      );
    });

    test(
      'keep same: resets the gauge optimistically, then adopts the server racquet and announces success',
      () async {
        final completer = Completer<Racquet>();
        stubRestring(() => completer.future);
        final (bloc, states) = await loadedBloc();

        bloc.add(const RestringRacquet(1));
        await pumpEventQueue();

        final optimistic = (states.single as BagLoaded).racquets.single;
        expect(optimistic.activeStringJob!.currentHealthScore, 100);
        expect(optimistic.activeStringJob!.totalCourtHours, 0.0);
        expect(optimistic.activeStringJob!.brand, 'Luxilon');
        expect((states.single as BagLoaded).successMessage, isNull);

        completer.complete(freshRacquet);
        await pumpEventQueue();

        expect(
          states.last,
          BagLoaded([
            freshRacquet,
          ], successMessage: BagBloc.restringSuccessMessage),
        );
        verify(
          () => mockBagEndpoint.restringRacquet(
            racquetId: 1,
            keepSame: true,
            newSpecs: null,
            materialCategory: null,
            stringBrand: null,
            stringModel: null,
            tension: null,
            maxRatedHours: null,
            restringDate: null,
            simulateFailure: null,
          ),
        ).called(1);
        await bloc.close();
      },
    );

    test('success message is the exact celebratory copy', () {
      expect(
        BagBloc.restringSuccessMessage,
        'Fresh stringbed mounted! Restrung to 100% health.',
      );
    });

    test(
      'change specs: forwards the new specs and shows them optimistically',
      () async {
        final completer = Completer<Racquet>();
        stubRestring(() => completer.future);
        final (bloc, states) = await loadedBloc();

        bloc.add(
          const RestringRacquet(
            1,
            keepSame: false,
            materialCategory: StringMaterialCategory.multifilament,
            stringBrand: 'Head',
            stringModel: 'Velocity MLT',
            tension: 55.5,
            maxRatedHours: 35.0,
          ),
        );
        await pumpEventQueue();

        final job =
            (states.single as BagLoaded).racquets.single.activeStringJob!;
        expect(job.brand, 'Head');
        expect(job.model, 'Velocity MLT');
        expect(job.installedTension, 55.5);
        expect(job.materialCategory, StringMaterialCategory.multifilament);
        expect(job.maxRatedHours, 35.0);
        expect(job.currentHealthScore, 100);
        verify(
          () => mockBagEndpoint.restringRacquet(
            racquetId: 1,
            keepSame: false,
            newSpecs: null,
            materialCategory: StringMaterialCategory.multifilament,
            stringBrand: 'Head',
            stringModel: 'Velocity MLT',
            tension: 55.5,
            maxRatedHours: 35.0,
            restringDate: null,
            simulateFailure: null,
          ),
        ).called(1);

        completer.complete(freshRacquet);
        await pumpEventQueue();
        await bloc.close();
      },
    );

    test(
      'failure: reverts the gauge, reports a plain-words error and no success message',
      () async {
        stubRestring(() async => throw Exception('socket closed'));
        final (bloc, states) = await loadedBloc();

        bloc.add(const RestringRacquet(1));
        await pumpEventQueue();

        final last = states.last as BagLoaded;
        expect(last.racquets, [deadRacquet]);
        expect(last.successMessage, isNull);
        expect(
          last.errorMessage,
          'Could not restring "${deadRacquet.name}". '
          'Check your connection and try again.',
        );
        expect(last.errorMessage, isNot(contains('socket closed')));
        await bloc.close();
      },
    );

    test('ignores a second restring while one is in flight', () async {
      final completer = Completer<Racquet>();
      stubRestring(() => completer.future);
      final (bloc, _) = await loadedBloc();

      bloc.add(const RestringRacquet(1));
      bloc.add(const RestringRacquet(1));
      await pumpEventQueue();
      completer.complete(freshRacquet);
      await pumpEventQueue();

      verify(
        () => mockBagEndpoint.restringRacquet(
          racquetId: any(named: 'racquetId'),
          keepSame: any(named: 'keepSame'),
          newSpecs: any(named: 'newSpecs'),
          materialCategory: any(named: 'materialCategory'),
          stringBrand: any(named: 'stringBrand'),
          stringModel: any(named: 'stringModel'),
          tension: any(named: 'tension'),
          maxRatedHours: any(named: 'maxRatedHours'),
          restringDate: any(named: 'restringDate'),
          simulateFailure: any(named: 'simulateFailure'),
        ),
      ).called(1);

      // The guard is released afterwards: a later restring goes through.
      clearInteractions(mockBagEndpoint);
      stubRestring(() async => freshRacquet);
      bloc.add(const RestringRacquet(1));
      await pumpEventQueue();
      verify(
        () => mockBagEndpoint.restringRacquet(
          racquetId: any(named: 'racquetId'),
          keepSame: any(named: 'keepSame'),
          newSpecs: any(named: 'newSpecs'),
          materialCategory: any(named: 'materialCategory'),
          stringBrand: any(named: 'stringBrand'),
          stringModel: any(named: 'stringModel'),
          tension: any(named: 'tension'),
          maxRatedHours: any(named: 'maxRatedHours'),
          restringDate: any(named: 'restringDate'),
          simulateFailure: any(named: 'simulateFailure'),
        ),
      ).called(1);
      await bloc.close();
    });

    test(
      'applyOptimisticRestring falls back to old specs for unset fields',
      () {
        final result = BagBloc.applyOptimisticRestring(
          [deadRacquet],
          const RestringRacquet(1, keepSame: false, stringBrand: 'Head'),
          now: DateTime.utc(2026, 10, 5),
        );

        final job = result.single.activeStringJob!;
        expect(job.brand, 'Head');
        expect(job.model, 'ALU Power');
        expect(job.installedTension, 52.0);
        expect(job.materialCategory, StringMaterialCategory.coPoly);
        expect(job.maxRatedHours, 20.0);
        expect(job.currentHealthScore, 100);
        expect(job.totalCourtHours, 0.0);
        expect(job.stringingDate, DateTime.utc(2026, 10, 5));
      },
    );

    test(
      'applyOptimisticRestring leaves other and unstrung racquets alone',
      () {
        final bare = sampleRacquet.copyWith(id: 2);
        final other = deadRacquet.copyWith(id: 3);
        final result = BagBloc.applyOptimisticRestring(
          [bare, other],
          const RestringRacquet(2),
        );
        expect(result, [bare, other]);
        expect(
          BagBloc.applyOptimisticRestring([other], const RestringRacquet(99)),
          [other],
        );
      },
    );

    test(
      'ignores a restring for a racquet that is not in the loaded bag',
      () async {
        final (bloc, states) = await loadedBloc();

        bloc.add(const RestringRacquet(99));
        await pumpEventQueue();

        expect(states, isEmpty);
        verifyNever(
          () => mockBagEndpoint.restringRacquet(
            racquetId: any(named: 'racquetId'),
            keepSame: any(named: 'keepSame'),
          ),
        );
        await bloc.close();
      },
    );

    group('with another racquet updated mid-flight', () {
      final otherRacquet = deadRacquet.copyWith(
        id: 2,
        name: 'Head Radical MP',
        activeStringJob: jobFor(id: 20, health: 60, hours: 8.0).copyWith(
          racquetId: 2,
        ),
      );

      Future<(BagBloc, List<BagState>)> twoRacquetBloc() async {
        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [deadRacquet, otherRacquet]);
        final bloc = BagBloc(client: mockClient);
        bloc.add(const LoadBag());
        await pumpEventQueue();
        final states = <BagState>[];
        bloc.stream.listen(states.add);
        return (bloc, states);
      }

      final otherUpdate = BagStreamMessage(
        eventType: 'sessionLogged',
        racquetId: 2,
        healthScore: 55,
        totalCourtHours: 9.0,
        timestamp: DateTime.utc(2026, 10, 5),
      );

      test('success keeps the other racquet\'s update', () async {
        final completer = Completer<Racquet>();
        stubRestring(() => completer.future);
        final (bloc, states) = await twoRacquetBloc();

        bloc.add(const RestringRacquet(1));
        await pumpEventQueue();
        bloc.add(BagStreamReceived(otherUpdate));
        await pumpEventQueue();
        completer.complete(freshRacquet);
        await pumpEventQueue();

        final racquets = (states.last as BagLoaded).racquets;
        expect(racquets.first, freshRacquet);
        expect(racquets.last.activeStringJob!.currentHealthScore, 55);
        expect(racquets.last.activeStringJob!.totalCourtHours, 9.0);
        await bloc.close();
      });

      test('failure reverts only the target and keeps the update', () async {
        final completer = Completer<Racquet>();
        stubRestring(() => completer.future);
        final (bloc, states) = await twoRacquetBloc();

        bloc.add(const RestringRacquet(1));
        await pumpEventQueue();
        bloc.add(BagStreamReceived(otherUpdate));
        await pumpEventQueue();
        completer.completeError(Exception('offline'));
        await pumpEventQueue();

        final last = states.last as BagLoaded;
        expect(last.racquets.first, deadRacquet);
        expect(last.racquets.last.activeStringJob!.currentHealthScore, 55);
        expect(last.errorMessage, isNotNull);
        await bloc.close();
      });
    });

    test(
      'success still reflects sessions queued offline on the fresh stringbed',
      () async {
        final queue = OfflineSessionQueue(
          storage: InMemorySessionQueueStorage(),
        );
        await queue.enqueue(
          SessionLog(
            userId: 0,
            racquetId: 1,
            startTime: DateTime.utc(2026, 10, 4, 18),
            durationMinutes: 90,
            source: 'manual',
            externalWorkoutId: 'queued-1',
          ),
        );
        stubRestring(() async => freshRacquet);
        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [deadRacquet]);
        final bloc = BagBloc(client: mockClient, offlineQueue: queue);
        bloc.add(const LoadBag());
        await pumpEventQueue();

        bloc.add(const RestringRacquet(1));
        await pumpEventQueue();

        final state = bloc.state as BagLoaded;
        expect(state.pendingSyncCount, 1);
        expect(state.successMessage, BagBloc.restringSuccessMessage);
        expect(
          state.racquets.single.activeStringJob!.totalCourtHours,
          closeTo(1.5, 1e-9),
        );
        await bloc.close();
      },
    );

    test('a restring after a failure is allowed again', () async {
      stubRestring(() async => throw Exception('offline'));
      final (bloc, states) = await loadedBloc();
      bloc.add(const RestringRacquet(1));
      await pumpEventQueue();

      stubRestring(() async => freshRacquet);
      bloc.add(const RestringRacquet(1));
      await pumpEventQueue();

      expect(
        (states.last as BagLoaded).successMessage,
        BagBloc.restringSuccessMessage,
      );
      await bloc.close();
    });
  });
}

/// Storage whose writes always fail, as when the device is out of space.
class _FailingWriteStorage implements SessionQueueStorage {
  @override
  Future<List<String>> read() async => [];

  @override
  Future<void> write(List<String> entries) async =>
      throw Exception('disk full');
}
