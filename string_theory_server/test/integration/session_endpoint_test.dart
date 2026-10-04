import 'package:serverpod_test/serverpod_test_public_exports.dart'
    as serverpod_test;
import 'package:string_theory_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given SessionEndpoint and SessionLog database persistence',
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
        '[P0] AC-1 should verify SessionLog model and session_log table exist with unique externalWorkoutId index',
        () async {
          expect(SessionLog, isNotNull);

          final session = sessionBuilder.build();
          final tablesResult = await session.db.unsafeQuery(
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'session_log';",
          );
          expect(
            tablesResult.length,
            equals(1),
            reason: 'Database table session_log must exist',
          );

          // Verify unique index on externalWorkoutId
          final indexResult = await session.db.unsafeQuery(
            "SELECT indexname FROM pg_indexes WHERE tablename = 'session_log' AND indexname = 'session_log_external_id_idx';",
          );
          expect(
            indexResult.length,
            equals(1),
            reason: 'Unique index session_log_external_id_idx must exist',
          );
        },
      );

      test(
        '[P0] AC-2 should log first-time session, increment court hours, and recalculate health score',
        () async {
          // Setup: create racquet for user 1
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Wilson Blade 98 v8',
            materialCategory: StringMaterialCategory.coPoly,
            maxRatedHours: 20.0,
          );
          final racquetId = racquet.id!;

          final logInput = SessionLog(
            userId: 1,
            racquetId: racquetId,
            startTime: DateTime.now().toUtc().subtract(
              const Duration(hours: 2),
            ),
            durationMinutes: 90,
            courtSurface: 'Hard',
            notes: 'Great practice session',
            source: 'HealthKit',
            externalWorkoutId: 'hk-1',
          );

          final logged = await endpoints.session.logSession(
            user1Session,
            logInput,
          );

          expect(logged.id, isNotNull);
          expect(logged.userId, equals(1));
          expect(logged.racquetId, equals(racquetId));
          expect(logged.durationMinutes, equals(90));
          expect(logged.externalWorkoutId, equals('hk-1'));

          // Verify string job totalCourtHours incremented by 1.5 hours
          final updatedBag = await endpoints.bag.getVirtualBag(user1Session);
          final updatedRacquet = updatedBag.firstWhere(
            (r) => r.id == racquetId,
          );
          final stringJob = updatedRacquet.activeStringJob!;

          expect(stringJob.totalCourtHours, closeTo(1.5, 0.001));
          // Health score recalculated from 100
          // (1.5 / 20.0) * 70 = 5.25 penalty -> 100 - 5.25 = 95 or 94 depending on calendar days
          expect(stringJob.currentHealthScore, lessThan(100));
        },
      );

      test(
        '[P0] AC-3 should handle duplicate external workout idempotently without double-counting hours',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Head Speed MP',
            materialCategory: StringMaterialCategory.coPoly,
            maxRatedHours: 20.0,
          );
          final racquetId = racquet.id!;

          final logInput = SessionLog(
            userId: 1,
            racquetId: racquetId,
            startTime: DateTime.now().toUtc(),
            durationMinutes: 90,
            source: 'HealthKit',
            externalWorkoutId: 'hk-duplicate-test',
          );

          // First call: creates session
          final firstResult = await endpoints.session.logSession(
            user1Session,
            logInput,
          );
          expect(firstResult.id, isNotNull);

          // Second call: duplicate externalWorkoutId
          final secondResult = await endpoints.session.logSession(
            user1Session,
            logInput,
          );

          // Should return existing record with identical id
          expect(secondResult.id, equals(firstResult.id));
          expect(secondResult.externalWorkoutId, equals('hk-duplicate-test'));

          // String job totalCourtHours must still be 1.5, not 3.0
          final bag = await endpoints.bag.getVirtualBag(user1Session);
          final updatedRacquet = bag.firstWhere((r) => r.id == racquetId);
          expect(
            updatedRacquet.activeStringJob!.totalCourtHours,
            closeTo(1.5, 0.001),
          );

          // Only 1 session log row should exist with this externalWorkoutId
          final session = sessionBuilder.build();
          final countResult = await session.db.unsafeQuery(
            "SELECT COUNT(*) FROM session_log WHERE \"externalWorkoutId\" = 'hk-duplicate-test';",
          );
          final count = int.parse(countResult.first.first.toString());
          expect(count, equals(1));
        },
      );

      test(
        '[P0] AC-4 should normalize whitespace and empty externalWorkoutId to null and allow multiple sessions',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Yonex EZONE 98',
            materialCategory: StringMaterialCategory.coPoly,
            maxRatedHours: 20.0,
          );
          final racquetId = racquet.id!;

          final manual1 = SessionLog(
            userId: 1,
            racquetId: racquetId,
            startTime: DateTime.now().toUtc().subtract(const Duration(days: 1)),
            durationMinutes: 60,
            source: 'Manual',
            externalWorkoutId: '',
          );
          final manual2 = SessionLog(
            userId: 1,
            racquetId: racquetId,
            startTime: DateTime.now().toUtc(),
            durationMinutes: 60,
            source: 'Manual',
            externalWorkoutId: '   ',
          );

          final result1 = await endpoints.session.logSession(
            user1Session,
            manual1,
          );
          final result2 = await endpoints.session.logSession(
            user1Session,
            manual2,
          );

          expect(result1.id, isNotNull);
          expect(result2.id, isNotNull);
          expect(result1.id, isNot(equals(result2.id)));
          expect(result1.externalWorkoutId, isNull);
          expect(result2.externalWorkoutId, isNull);

          final bag = await endpoints.bag.getVirtualBag(user1Session);
          final updatedRacquet = bag.firstWhere((r) => r.id == racquetId);
          // 60m + 60m = 2.0 hours
          expect(
            updatedRacquet.activeStringJob!.totalCourtHours,
            closeTo(2.0, 0.001),
          );
        },
      );

      test(
        '[P1] AC-5 should reject session logging when durationMinutes is <= 0',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Babolat Pure Drive',
          );

          final invalidZero = SessionLog(
            userId: 1,
            racquetId: racquet.id!,
            startTime: DateTime.now().toUtc(),
            durationMinutes: 0,
            source: 'Manual',
          );

          await expectLater(
            endpoints.session.logSession(user1Session, invalidZero),
            throwsA(
              isA<BagException>().having(
                (e) => e.statusCode,
                'statusCode',
                equals(400),
              ),
            ),
          );

          final invalidNegative = SessionLog(
            userId: 1,
            racquetId: racquet.id!,
            startTime: DateTime.now().toUtc(),
            durationMinutes: -30,
            source: 'Manual',
          );

          await expectLater(
            endpoints.session.logSession(user1Session, invalidNegative),
            throwsA(
              isA<BagException>().having(
                (e) => e.statusCode,
                'statusCode',
                equals(400),
              ),
            ),
          );
        },
      );

      test(
        '[P1] AC-6 should reject session logging for foreign or non-existent racquet',
        () async {
          // Racquet created by user 2
          final user2Racquet = await endpoints.bag.createRacquet(
            user2Session,
            racquetName: "User 2's Frame",
          );

          // User 1 attempts to log against user 2's racquet
          final unauthorizedLog = SessionLog(
            userId: 1,
            racquetId: user2Racquet.id!,
            startTime: DateTime.now().toUtc(),
            durationMinutes: 60,
            source: 'Manual',
          );

          await expectLater(
            endpoints.session.logSession(user1Session, unauthorizedLog),
            throwsA(
              isA<BagException>().having(
                (e) => e.statusCode,
                'statusCode',
                equals(404),
              ),
            ),
          );

          // Non-existent racquet ID
          final nonExistentLog = SessionLog(
            userId: 1,
            racquetId: 999999,
            startTime: DateTime.now().toUtc(),
            durationMinutes: 60,
            source: 'Manual',
          );

          await expectLater(
            endpoints.session.logSession(user1Session, nonExistentLog),
            throwsA(
              isA<BagException>().having(
                (e) => e.statusCode,
                'statusCode',
                equals(404),
              ),
            ),
          );
        },
      );

      test(
        '[P1] AC-6b should reject session logging when racquet has no active string job',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Unstrung Frame',
          );
          final session = sessionBuilder.build();
          // Unset active string job on racquet
          await session.db.unsafeExecute(
            'UPDATE racquet SET "activeStringJobId" = NULL WHERE id = ${racquet.id};',
          );

          final log = SessionLog(
            userId: 1,
            racquetId: racquet.id!,
            startTime: DateTime.now().toUtc(),
            durationMinutes: 60,
            source: 'Manual',
          );

          await expectLater(
            endpoints.session.logSession(user1Session, log),
            throwsA(
              isA<BagException>().having(
                (e) => e.statusCode,
                'statusCode',
                equals(400),
              ),
            ),
          );
        },
      );

      test(
        '[P1] AC-7 should reject unauthenticated session logging with 401',
        () async {
          final logInput = SessionLog(
            userId: 1,
            racquetId: 1,
            startTime: DateTime.now().toUtc(),
            durationMinutes: 60,
            source: 'Manual',
          );

          await expectLater(
            endpoints.session.logSession(
              unauthenticatedSession,
              logInput,
            ),
            throwsA(
              anyOf(
                isA<BagException>().having(
                  (e) => e.statusCode,
                  'statusCode',
                  equals(401),
                ),
                isA<serverpod_test.ServerpodUnauthenticatedException>(),
              ),
            ),
          );
        },
      );

      test(
        '[P0] AC-8 should return multi-tenant scoped session logs via getSessionLogs',
        () async {
          final r1 = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Racquet 1',
          );
          final r2 = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Racquet 2',
          );
          final rUser2 = await endpoints.bag.createRacquet(
            user2Session,
            racquetName: "User 2's Racquet",
          );

          // Log sessions for user 1
          await endpoints.session.logSession(
            user1Session,
            SessionLog(
              userId: 1,
              racquetId: r1.id!,
              startTime: DateTime.now().toUtc().subtract(
                const Duration(hours: 3),
              ),
              durationMinutes: 60,
              source: 'Manual',
            ),
          );
          await endpoints.session.logSession(
            user1Session,
            SessionLog(
              userId: 1,
              racquetId: r2.id!,
              startTime: DateTime.now().toUtc().subtract(
                const Duration(hours: 1),
              ),
              durationMinutes: 45,
              source: 'Manual',
            ),
          );

          // Log session for user 2
          await endpoints.session.logSession(
            user2Session,
            SessionLog(
              userId: 2,
              racquetId: rUser2.id!,
              startTime: DateTime.now().toUtc(),
              durationMinutes: 120,
              source: 'Manual',
            ),
          );

          // User 1 gets all user 1 sessions
          final user1Logs = await endpoints.session.getSessionLogs(
            user1Session,
          );
          expect(user1Logs.length, equals(2));
          expect(user1Logs.every((l) => l.userId == 1), isTrue);

          // Filter by racquetId
          final r1Logs = await endpoints.session.getSessionLogs(
            user1Session,
            racquetId: r1.id!,
          );
          expect(r1Logs.length, equals(1));
          expect(r1Logs.first.racquetId, equals(r1.id!));

          // Pagination
          final paginatedLogs = await endpoints.session.getSessionLogs(
            user1Session,
            limit: 1,
            offset: 0,
          );
          expect(paginatedLogs.length, equals(1));

          // User 2 gets only user 2 sessions
          final user2Logs = await endpoints.session.getSessionLogs(
            user2Session,
          );
          expect(user2Logs.length, equals(1));
          expect(user2Logs.first.userId, equals(2));
        },
      );

      test(
        '[P0] should return existing SessionLog when re-syncing duplicate external workout on racquet with inactive string job',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Wilson Clash 100',
            materialCategory: StringMaterialCategory.coPoly,
          );
          final racquetId = racquet.id!;

          final logInput = SessionLog(
            userId: 1,
            racquetId: racquetId,
            startTime: DateTime.now().toUtc(),
            durationMinutes: 60,
            source: 'HealthKit',
            externalWorkoutId: 'hk-inactive-resync',
          );

          // Initial log
          final first = await endpoints.session.logSession(
            user1Session,
            logInput,
          );
          expect(first.id, isNotNull);

          // Mark string job as inactive
          final session = sessionBuilder.build();
          await session.db.unsafeExecute(
            'UPDATE string_job SET "isActive" = false WHERE "racquetId" = $racquetId;',
          );

          // Re-sync duplicate external workout
          final resynced = await endpoints.session.logSession(
            user1Session,
            logInput,
          );
          expect(resynced.id, equals(first.id));
        },
      );

      test(
        '[P1] should throw 409 when externalWorkoutId is already registered by another user',
        () async {
          final rUser1 = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: "User 1's Racquet",
          );
          final rUser2 = await endpoints.bag.createRacquet(
            user2Session,
            racquetName: "User 2's Racquet",
          );

          // User 1 logs workout
          await endpoints.session.logSession(
            user1Session,
            SessionLog(
              userId: 1,
              racquetId: rUser1.id!,
              startTime: DateTime.now().toUtc(),
              durationMinutes: 60,
              source: 'HealthKit',
              externalWorkoutId: 'shared-device-workout-id',
            ),
          );

          // User 2 tries to log same external workout ID
          await expectLater(
            endpoints.session.logSession(
              user2Session,
              SessionLog(
                userId: 2,
                racquetId: rUser2.id!,
                startTime: DateTime.now().toUtc(),
                durationMinutes: 60,
                source: 'HealthKit',
                externalWorkoutId: 'shared-device-workout-id',
              ),
            ),
            throwsA(
              isA<BagException>().having(
                (e) => e.statusCode,
                'statusCode',
                equals(409),
              ),
            ),
          );
        },
      );

      test(
        '[P1] getSessionLogs should throw 404 for foreign or non-existent racquetId',
        () async {
          final user2Racquet = await endpoints.bag.createRacquet(
            user2Session,
            racquetName: "User 2's Frame",
          );

          // Foreign racquet
          await expectLater(
            endpoints.session.getSessionLogs(
              user1Session,
              racquetId: user2Racquet.id!,
            ),
            throwsA(
              isA<BagException>().having(
                (e) => e.statusCode,
                'statusCode',
                equals(404),
              ),
            ),
          );

          // Non-existent racquet
          await expectLater(
            endpoints.session.getSessionLogs(
              user1Session,
              racquetId: 999999,
            ),
            throwsA(
              isA<BagException>().having(
                (e) => e.statusCode,
                'statusCode',
                equals(404),
              ),
            ),
          );
        },
      );

      test(
        '[P1] getSessionLogs should throw 400 for negative limit or offset',
        () async {
          await expectLater(
            endpoints.session.getSessionLogs(
              user1Session,
              limit: -1,
            ),
            throwsA(
              isA<BagException>().having(
                (e) => e.statusCode,
                'statusCode',
                equals(400),
              ),
            ),
          );

          await expectLater(
            endpoints.session.getSessionLogs(
              user1Session,
              offset: -5,
            ),
            throwsA(
              isA<BagException>().having(
                (e) => e.statusCode,
                'statusCode',
                equals(400),
              ),
            ),
          );
        },
      );

      test(
        '[P0] getSessionLogs should return sessions ordered newest first by startTime',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Order Test Racquet',
          );
          final now = DateTime.now().toUtc();

          final oldest = SessionLog(
            userId: 1,
            racquetId: racquet.id!,
            startTime: now.subtract(const Duration(hours: 3)),
            durationMinutes: 30,
            source: 'Manual',
          );
          final middle = SessionLog(
            userId: 1,
            racquetId: racquet.id!,
            startTime: now.subtract(const Duration(hours: 1)),
            durationMinutes: 45,
            source: 'Manual',
          );
          final newest = SessionLog(
            userId: 1,
            racquetId: racquet.id!,
            startTime: now,
            durationMinutes: 60,
            source: 'Manual',
          );

          // Insert in arbitrary order
          await endpoints.session.logSession(user1Session, middle);
          await endpoints.session.logSession(user1Session, oldest);
          await endpoints.session.logSession(user1Session, newest);

          final logs = await endpoints.session.getSessionLogs(
            user1Session,
            racquetId: racquet.id!,
          );

          expect(logs.length, equals(3));
          expect(logs[0].startTime.isAfter(logs[1].startTime), isTrue);
          expect(logs[1].startTime.isAfter(logs[2].startTime), isTrue);
        },
      );

      test(
        '[P0] should cascade delete SessionLog records when racquet is deleted',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Cascade Test Racquet',
          );
          final racquetId = racquet.id!;

          final log = await endpoints.session.logSession(
            user1Session,
            SessionLog(
              userId: 1,
              racquetId: racquetId,
              startTime: DateTime.now().toUtc(),
              durationMinutes: 60,
              source: 'Manual',
            ),
          );
          final logId = log.id!;

          final session = sessionBuilder.build();
          final beforeDelete = await SessionLog.db.findById(session, logId);
          expect(beforeDelete, isNotNull);

          // Delete racquet via BagEndpoint
          final deleted = await endpoints.bag.deleteRacquet(
            user1Session,
            racquetId: racquetId,
          );
          expect(deleted, isTrue);

          // SessionLog must be cascade deleted
          final afterDelete = await SessionLog.db.findById(session, logId);
          expect(afterDelete, isNull);
        },
      );
    },
  );

  // Concurrent transactions require real commits, so rollbacks are disabled.
  withServerpod(
    'Given concurrent SessionEndpoint calls for the same external workout',
    (sessionBuilder, endpoints) {
      final userSession = sessionBuilder.copyWith(
        authentication:
            serverpod_test.AuthenticationOverride.authenticationInfo(
              '3101',
              {},
            ),
      );

      test(
        '[P0] should return the same SessionLog for concurrent duplicate syncs without double-counting hours',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            userSession,
            racquetName: 'Yonex Ezone 98',
            materialCategory: StringMaterialCategory.coPoly,
            maxRatedHours: 20.0,
          );
          final racquetId = racquet.id!;
          final externalId = 'hk-race-${DateTime.now().microsecondsSinceEpoch}';

          try {
            final logInput = SessionLog(
              userId: 3101,
              racquetId: racquetId,
              startTime: DateTime.now().toUtc(),
              durationMinutes: 90,
              source: 'HealthKit',
              externalWorkoutId: externalId,
            );

            final results = await Future.wait([
              endpoints.session.logSession(userSession, logInput),
              endpoints.session.logSession(userSession, logInput),
            ]);

            expect(results[0].id, isNotNull);
            expect(results[1].id, equals(results[0].id));

            final bag = await endpoints.bag.getVirtualBag(userSession);
            final updatedRacquet = bag.firstWhere((r) => r.id == racquetId);
            expect(
              updatedRacquet.activeStringJob!.totalCourtHours,
              closeTo(1.5, 0.001),
            );
          } finally {
            await endpoints.bag.deleteRacquet(
              userSession,
              racquetId: racquetId,
            );
          }
        },
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
