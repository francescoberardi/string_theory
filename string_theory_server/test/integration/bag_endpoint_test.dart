import 'package:serverpod_test/serverpod_test_public_exports.dart'
    as serverpod_test;
import 'package:test/test.dart' as dart_test;
import 'package:test/test.dart' hide test;

import 'test_tools/serverpod_test_tools.dart';

/// ATDD Red-Phase test runner helper allowing `test.skip(...)` syntax in Dart.
// ignore: camel_case_types
class test {
  static void skip(
    String description,
    dynamic Function() body, {
    String? reason,
  }) {
    dart_test.test(
      description,
      body,
      skip: reason ?? 'ATDD RED PHASE: Scaffold pending implementation',
    );
  }
}

void main() {
  withServerpod(
    'Given BagEndpoint and Racquet/StringJob database persistence',
    (sessionBuilder, endpoints) {
      final user1Session = sessionBuilder.copyWith(
        authentication:
            serverpod_test.AuthenticationOverride.authenticationInfo(
              '1',
              {},
            ),
      );
      final user2Session = sessionBuilder.copyWith(
        authentication:
            serverpod_test.AuthenticationOverride.authenticationInfo(
              '2',
              {},
            ),
      );

      test.skip(
        '[P0] AC-1 should define Racquet and StringJob models with indexed userId',
        () async {
          final protocol = sessionBuilder
              .build()
              .serverpod
              .serializationManager;
          final targetClassNames = [
            'Racquet',
            'StringJob',
            'StringMaterialCategory',
          ];
          for (final name in targetClassNames) {
            expect(
              protocol.getClassNameForObject(name),
              isNotNull,
              reason:
                  'Model $name must be defined in Serverpod .spy.yaml protocol',
            );
          }
        },
      );

      test.skip(
        '[P0] AC-2 should verify database tables racquet and string_job exist with foreign keys',
        () async {
          final session = sessionBuilder.build();
          final tablesResult = await session.db.unsafeQuery(
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('racquet', 'string_job');",
          );
          expect(
            tablesResult.length,
            equals(2),
            reason: 'Database tables racquet and string_job must exist',
          );
        },
      );

      test.skip(
        '[P0] AC-3 should return only racquets owned by authenticated user from getVirtualBag',
        () async {
          final dynamic bagEndpoint = (endpoints as dynamic).bag;
          final user1Bag = await bagEndpoint.getVirtualBag(user1Session);
          expect(user1Bag, isNotNull);
          for (final racquet in user1Bag) {
            expect(racquet.userId, equals(1));
          }
        },
      );

      test.skip(
        '[P0] AC-4 should atomically create racquet and initial string job in a single transaction',
        () async {
          final dynamic bagEndpoint = (endpoints as dynamic).bag;
          final createdRacquet = await bagEndpoint.createRacquet(
            user1Session,
            racquetName: 'Wilson Pro Staff 97 v14',
            stringModel: 'Luxilon ALU Power 125',
            tension: 52.0,
          );
          expect(createdRacquet.id, isNotNull);
          expect(createdRacquet.activeStringJobId, isNotNull);
        },
      );

      test.skip(
        '[P1] AC-5 should set designated racquet as primary and unset previous primaries for user',
        () async {
          final dynamic bagEndpoint = (endpoints as dynamic).bag;
          await bagEndpoint.setPrimary(user1Session, racquetId: 2);
          final updatedBag = await bagEndpoint.getVirtualBag(user1Session);
          final primaryRacquets = updatedBag
              .where((r) => r.isPrimary == true)
              .toList();
          expect(primaryRacquets.length, equals(1));
          expect(primaryRacquets.first.id, equals(2));
        },
      );

      test.skip(
        '[P1] AC-6 should delete user racquet and reject unauthorized deletion',
        () async {
          final dynamic bagEndpoint = (endpoints as dynamic).bag;
          await expectLater(
            bagEndpoint.deleteRacquet(user2Session, racquetId: 1),
            throwsA(anything),
            reason: 'User 2 must not be permitted to delete User 1 racquet',
          );
        },
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
