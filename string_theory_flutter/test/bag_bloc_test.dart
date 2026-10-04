import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';

class MockClient extends Mock implements Client {}

class MockEndpointBag extends Mock implements EndpointBag {}

void main() {
  late MockClient mockClient;
  late MockEndpointBag mockBagEndpoint;

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

  setUp(() {
    mockClient = MockClient();
    mockBagEndpoint = MockEndpointBag();
    when(() => mockClient.bag).thenReturn(mockBagEndpoint);
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
  });
}
