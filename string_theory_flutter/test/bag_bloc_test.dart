import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';

class MockClient extends Mock implements Client {}

class MockEndpointBag extends Mock implements EndpointBag {}

class MockEndpointSession extends Mock implements EndpointSession {}

class FakeSessionLog extends Fake implements SessionLog {}

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
              'Failed to load virtual bag: Exception: Server unreachable',
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
              'Failed to seed sample bag: Exception: Network timeout',
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
              'Failed to fast-forward racquet age: Exception: RPC failed',
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

        bloc.add(
          LogSession(
            racquetId: 1,
            startTime: now,
            durationMinutes: 90,
            courtSurface: 'Clay',
            notes: 'Great match',
            source: 'simulated',
            externalWorkoutId: 'sim-123',
          ),
        );
        await pumpEventQueue();

        verify(
          () => mockSessionEndpoint.logSession(
            any(
              that: isA<SessionLog>()
                  .having((s) => s.racquetId, 'racquetId', 1)
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

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'retains loaded racquets with transient errorMessage when client.session.logSession fails while BagLoaded',
      () async {
        when(
          () => mockBagEndpoint.getVirtualBag(),
        ).thenAnswer((_) async => [sampleRacquet]);
        when(
          () => mockSessionEndpoint.logSession(any()),
        ).thenThrow(Exception('RPC timeout'));

        final bloc = BagBloc(client: mockClient);
        bloc.add(const LoadBag());
        await pumpEventQueue();

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
            BagLoaded(
              [sampleRacquet],
              errorMessage: 'Failed to log session: Exception: RPC timeout',
            ),
          ]),
        );

        await subscription.cancel();
        await bloc.close();
      },
    );

    test(
      'emits BagError when client.session.logSession fails without BagLoaded',
      () async {
        when(
          () => mockSessionEndpoint.logSession(any()),
        ).thenThrow(Exception('RPC timeout'));

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
            const BagError('Failed to log session: Exception: RPC timeout'),
          ]),
        );

        await subscription.cancel();
        await bloc.close();
      },
    );
  });
}
