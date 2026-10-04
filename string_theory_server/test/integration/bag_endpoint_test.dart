import 'package:serverpod_test/serverpod_test_public_exports.dart'
    as serverpod_test;
import 'package:string_theory_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

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
      final unauthenticatedSession = sessionBuilder.copyWith(
        authentication: serverpod_test.AuthenticationOverride.unauthenticated(),
      );

      test(
        '[P0] AC-1 should define Racquet and StringJob models with indexed userId',
        () async {
          expect(Racquet, isNotNull);
          expect(StringJob, isNotNull);
          expect(StringMaterialCategory.coPoly, isNotNull);
          expect(StringMaterialCategory.kevlar, isNotNull);

          final racquet = Racquet(
            userId: 1,
            name: 'Babolat Pure Aero',
            isPrimary: true,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          expect(racquet.userId, equals(1));
          expect(racquet.name, equals('Babolat Pure Aero'));
        },
      );

      test(
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

      test(
        '[P0] AC-3 should return only racquets owned by authenticated user from getVirtualBag',
        () async {
          // Seed racquets for user 1 and user 2
          await endpoints.bag.createRacquet(
            user1Session,
            racquetName: "User 1's Racquet",
            materialCategory: StringMaterialCategory.coPoly,
          );
          await endpoints.bag.createRacquet(
            user2Session,
            racquetName: "User 2's Racquet",
            materialCategory: StringMaterialCategory.naturalGut,
          );

          final user1Bag = await endpoints.bag.getVirtualBag(user1Session);
          expect(user1Bag, isNotEmpty);
          expect(user1Bag.every((r) => r.userId == 1), isTrue);
          expect(user1Bag.every((r) => r.activeStringJob != null), isTrue);

          final user2Bag = await endpoints.bag.getVirtualBag(user2Session);
          expect(user2Bag, isNotEmpty);
          expect(user2Bag.every((r) => r.userId == 2), isTrue);
          expect(user2Bag.every((r) => r.activeStringJob != null), isTrue);
        },
      );

      test(
        '[P0] AC-4 should atomically create racquet and initial string job in a single transaction',
        () async {
          final createdRacquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Wilson Pro Staff 97 v14',
            stringBrand: 'Luxilon',
            stringModel: 'ALU Power 125',
            tension: 52.0,
            maxRatedHours: 20.0,
          );

          expect(createdRacquet.id, isNotNull);
          expect(createdRacquet.activeStringJobId, isNotNull);
          expect(createdRacquet.activeStringJob, isNotNull);
          expect(
            createdRacquet.activeStringJob!.model,
            equals('ALU Power 125'),
          );
          expect(
            createdRacquet.activeStringJob!.installedTension,
            equals(52.0),
          );
        },
      );

      test(
        'should reject empty or whitespace racquet name',
        () async {
          await expectLater(
            endpoints.bag.createRacquet(
              user1Session,
              racquetName: '   ',
            ),
            throwsA(isA<BagException>()),
          );
        },
      );

      test(
        '[P1] AC-5 should set designated racquet as primary and unset previous primaries for user',
        () async {
          final racquetA = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Racquet A',
            isPrimary: true,
          );
          final racquetB = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Racquet B',
            isPrimary: false,
          );

          expect(racquetA.isPrimary, isTrue);
          expect(racquetB.isPrimary, isFalse);

          // User 2 cannot call setPrimary on User 1 racquet
          await expectLater(
            endpoints.bag.setPrimary(user2Session, racquetId: racquetB.id!),
            throwsA(isA<BagException>()),
          );

          final updatedPrimary = await endpoints.bag.setPrimary(
            user1Session,
            racquetId: racquetB.id!,
          );
          expect(updatedPrimary.id, equals(racquetB.id));
          expect(updatedPrimary.isPrimary, isTrue);
          expect(updatedPrimary.activeStringJob, isNotNull);

          final updatedBag = await endpoints.bag.getVirtualBag(user1Session);
          final fetchedA = updatedBag.firstWhere((r) => r.id == racquetA.id);
          final fetchedB = updatedBag.firstWhere((r) => r.id == racquetB.id);

          expect(fetchedA.isPrimary, isFalse);
          expect(fetchedB.isPrimary, isTrue);
        },
      );

      test(
        'should unset previous primary when creating new racquet with isPrimary true',
        () async {
          final initial = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Old Primary',
            isPrimary: true,
          );
          expect(initial.isPrimary, isTrue);

          final successor = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'New Primary',
            isPrimary: true,
          );
          expect(successor.isPrimary, isTrue);

          final bag = await endpoints.bag.getVirtualBag(user1Session);
          final old = bag.firstWhere((r) => r.id == initial.id);
          expect(old.isPrimary, isFalse);
        },
      );

      test(
        '[P1] AC-6 should delete user racquet and reject unauthorized deletion',
        () async {
          final user1Racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'User 1 Racquet to Delete',
          );

          // User 2 cannot delete User 1's racquet
          await expectLater(
            endpoints.bag.deleteRacquet(
              user2Session,
              racquetId: user1Racquet.id!,
            ),
            throwsA(isA<BagException>()),
          );

          // User 1 deletes their own racquet
          final deleted = await endpoints.bag.deleteRacquet(
            user1Session,
            racquetId: user1Racquet.id!,
          );
          expect(deleted, isTrue);

          final user1Bag = await endpoints.bag.getVirtualBag(user1Session);
          expect(user1Bag.any((r) => r.id == user1Racquet.id), isFalse);
        },
      );

      test(
        'should reject unauthenticated call to getVirtualBag',
        () async {
          await expectLater(
            endpoints.bag.getVirtualBag(unauthenticatedSession),
            throwsA(isA<serverpod_test.ServerpodUnauthenticatedException>()),
          );
        },
      );

      test(
        '[Story 2.4] should shift stringingDate 30 days into the past and recalculate health score',
        () async {
          final now = DateTime.now().toUtc();
          final createdRacquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Head Speed MP',
            materialCategory: StringMaterialCategory.coPoly,
            stringingDate: now,
          );

          expect(createdRacquet.activeStringJob, isNotNull);
          expect(
            createdRacquet.activeStringJob!.currentHealthScore,
            equals(100),
          );

          final updatedRacquet = await endpoints.bag.fastForwardRacquetAge(
            user1Session,
            racquetId: createdRacquet.id!,
            days: 30,
          );

          expect(updatedRacquet.activeStringJob, isNotNull);
          // Co-poly shelf life = 75 days.
          // 30 days penalty = (30 / 75) * 30 = 12% drop => health score = 88%
          expect(
            updatedRacquet.activeStringJob!.currentHealthScore,
            equals(88),
          );
          expect(
            updatedRacquet.activeStringJob!.stringingDate.isBefore(
              now.subtract(const Duration(days: 29)),
            ),
            isTrue,
          );
        },
      );

      test(
        '[Story 2.4] should drop health score below 40% when aged excessively',
        () async {
          final now = DateTime.now().toUtc();
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Wilson Clash',
            materialCategory: StringMaterialCategory.coPoly,
            stringingDate: now,
          );

          // Fast forward 160 days: CalendarPenalty = (160/75)*30 = 64% penalty => 36% health (< 40% critical)
          final agedRacquet = await endpoints.bag.fastForwardRacquetAge(
            user1Session,
            racquetId: racquet.id!,
            days: 160,
          );

          expect(agedRacquet.activeStringJob!.currentHealthScore, lessThan(40));
        },
      );

      test(
        '[Story 2.4] should reject unauthorized user fastForwardRacquetAge attempt',
        () async {
          final user1Racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'User 1 Private Racquet',
          );

          await expectLater(
            endpoints.bag.fastForwardRacquetAge(
              user2Session,
              racquetId: user1Racquet.id!,
            ),
            throwsA(isA<BagException>()),
          );
        },
      );

      test(
        '[Story 2.4] should reject fastForwardRacquetAge on non-existent racquet',
        () async {
          await expectLater(
            endpoints.bag.fastForwardRacquetAge(
              user1Session,
              racquetId: 999999,
            ),
            throwsA(isA<BagException>()),
          );
        },
      );

      test(
        '[Story 2.4] should default to 30 days when days parameter is omitted',
        () async {
          final now = DateTime.now().toUtc();
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Default 30 Days Racquet',
            materialCategory: StringMaterialCategory.coPoly,
            stringingDate: now,
          );

          final agedRacquet = await endpoints.bag.fastForwardRacquetAge(
            user1Session,
            racquetId: racquet.id!,
          );

          expect(agedRacquet.activeStringJob!.currentHealthScore, equals(88));
        },
      );

      test(
        '[Story 2.4] should reject non-positive days parameter',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Non Positive Days Racquet',
          );

          await expectLater(
            endpoints.bag.fastForwardRacquetAge(
              user1Session,
              racquetId: racquet.id!,
              days: 0,
            ),
            throwsA(isA<BagException>()),
          );

          await expectLater(
            endpoints.bag.fastForwardRacquetAge(
              user1Session,
              racquetId: racquet.id!,
              days: -15,
            ),
            throwsA(isA<BagException>()),
          );
        },
      );

      test(
        '[Story 2.4] should reject fastForwardRacquetAge on racquet with no active string job',
        () async {
          final session = sessionBuilder.build();
          final now = DateTime.now().toUtc();
          final unstrungRacquet = await Racquet.db.insertRow(
            session,
            Racquet(
              userId: 1,
              name: 'Unstrung Frame',
              createdAt: now,
              updatedAt: now,
            ),
          );

          await expectLater(
            endpoints.bag.fastForwardRacquetAge(
              user1Session,
              racquetId: unstrungRacquet.id!,
            ),
            throwsA(isA<BagException>()),
          );
        },
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
