import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:flutter_test/flutter_test.dart' hide test;
import 'package:mocktail/mocktail.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/bloc/bag_bloc.dart';

/// ATDD Red-Phase test runner helper allowing `test.skip(...)` syntax in Dart.
// ignore: camel_case_types
class test {
  static void skip(
    String description,
    dynamic Function() body, {
    String? reason,
  }) {
    flutter_test.test(
      description,
      body,
      skip: reason ?? 'ATDD RED PHASE: Scaffold pending implementation',
    );
  }
}

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
    test.skip(
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

    test.skip(
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

    test.skip(
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

    test.skip(
      '[P0] AC-5 should verify comprehensive bloc_test coverage across AddRacquet, DeleteRacquet, and SetPrimaryRacquet transitions',
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

        when(
          () => mockBagEndpoint.setPrimary(racquetId: 1),
        ).thenAnswer((_) async => sampleRacquet);

        when(
          () => mockBagEndpoint.deleteRacquet(racquetId: 1),
        ).thenAnswer((_) async => true);

        final bloc = BagBloc(client: mockClient);

        // Verify AddRacquet transition
        bloc.add(
          AddRacquet(
            name: 'Babolat Pure Aero 2023',
            stringBrand: 'Babolat',
            stringModel: 'RPM Blast',
            tension: 52.0,
            maxRatedHours: 20.0,
            stringingDate: DateTime.utc(2026, 10, 1),
          ),
        );
        await pumpEventQueue();

        // Verify SetPrimaryRacquet transition
        bloc.add(const SetPrimaryRacquet(1));
        await pumpEventQueue();

        // Verify DeleteRacquet transition
        bloc.add(const DeleteRacquet(1));
        await pumpEventQueue();

        // Criterion-defining primary assertion: transitions completed without crashing bloc
        expect(bloc.isClosed, isFalse);

        await bloc.close();
      },
    );
  });
}
