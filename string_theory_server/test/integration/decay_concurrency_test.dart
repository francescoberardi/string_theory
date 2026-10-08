import 'package:string_theory_server/src/domain/decay_engine.dart';
import 'package:string_theory_server/src/future_calls/daily_decay_future_call.dart';
import 'package:string_theory_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'support/test_tenants.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Advisory lock key held by [DailyDecayService] while a decay run is active.
const _decayLockKey = 7421893;

void main() {
  withServerpod(
    'Given DailyDecayService guarded by an advisory lock (Story 6.3)',
    (sessionBuilder, endpoints) {
      final tenantA = sessionBuilder.copyWith(
        authentication: TestTenants.auth(TestTenants.a),
      );

      test(
        '[P0] AC-4 should reject the dev trigger with 409 while another run holds the decay lock',
        () async {
          final session = sessionBuilder.build();

          // The open transaction pins its connection, so the trigger below
          // must use a different one and contend for the lock.
          await session.db.transaction((tx) async {
            await session.db.unsafeQuery(
              'SELECT pg_advisory_xact_lock($_decayLockKey);',
              transaction: tx,
            );

            await expectLater(
              endpoints.bag.triggerDailyDecayNow(tenantA),
              throwsA(
                isA<BagException>().having(
                  (e) => e.statusCode,
                  'statusCode',
                  409,
                ),
              ),
            );
          });
        },
      );

      test(
        '[P0] AC-4 should let the cron run return quietly without updates while the decay lock is held',
        () async {
          final now = DateTime.now().toUtc();
          final racquet = await endpoints.bag.createRacquet(
            tenantA,
            racquetName: 'Wilson Ultra 100',
            materialCategory: StringMaterialCategory.coPoly,
            maxRatedHours: 20.0,
            stringingDate: now.subtract(const Duration(days: 30)),
          );
          final racquetId = racquet.id!;

          try {
            final session = sessionBuilder.build();
            await session.db.transaction((tx) async {
              await session.db.unsafeQuery(
                'SELECT pg_advisory_xact_lock($_decayLockKey);',
                transaction: tx,
              );

              await DailyDecayFutureCall().execute(sessionBuilder.build());
            });

            final bag = await endpoints.bag.getVirtualBag(tenantA);
            final job = bag
                .firstWhere((r) => r.id == racquetId)
                .activeStringJob!;
            expect(job.currentHealthScore, equals(100));
          } finally {
            await endpoints.bag.deleteRacquet(tenantA, racquetId: racquetId);
          }
        },
      );

      test(
        '[P0] AC-4 should take the decay lock again after a successful run',
        () async {
          await endpoints.bag.triggerDailyDecayNow(tenantA);

          await expectLater(
            endpoints.bag.triggerDailyDecayNow(tenantA),
            completion(isA<int>()),
          );
        },
      );

      test(
        '[P0] AC-4 should take the decay lock again after a run that threw',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            tenantA,
            racquetName: 'Tecnifibre TF40',
          );
          final racquetId = racquet.id!;

          try {
            await expectLater(
              DailyDecayService.performDecayCalculation(
                sessionBuilder.build(),
                afterPageRead: (_) async => throw StateError('page failed'),
              ),
              throwsStateError,
            );

            await expectLater(
              endpoints.bag.triggerDailyDecayNow(tenantA),
              completion(isA<int>()),
            );
          } finally {
            await endpoints.bag.deleteRacquet(tenantA, racquetId: racquetId);
          }
        },
      );

      test(
        '[P1] AC-6 should publish the new health score to the owner channel when decay changes it',
        () async {
          final now = DateTime.now().toUtc();
          final stringingDate = now.subtract(const Duration(days: 30));
          final decayNow = now.add(const Duration(days: 30));
          final racquet = await endpoints.bag.createRacquet(
            tenantA,
            racquetName: 'Head Speed MP',
            materialCategory: StringMaterialCategory.coPoly,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
          );
          final racquetId = racquet.id!;
          final expectedScore = DecayEngine.calculateHealth(
            hoursPlayed: 0.0,
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
            materialCategory: StringMaterialCategory.coPoly,
            now: decayNow,
          );

          try {
            final update = endpoints.bag
                .bagUpdates(tenantA)
                .firstWhere((m) => m.racquetId == racquetId)
                .timeout(const Duration(seconds: 5));
            // Allow the stream subscription to register on the channel.
            await Future<void>.delayed(const Duration(milliseconds: 200));

            await DailyDecayService.performDecayCalculation(
              sessionBuilder.build(),
              now: decayNow,
            );

            await expectLater(
              update,
              completion(
                isA<BagStreamMessage>().having(
                  (m) => m.healthScore,
                  'healthScore',
                  expectedScore,
                ),
              ),
            );
          } finally {
            await endpoints.bag.deleteRacquet(tenantA, racquetId: racquetId);
          }
        },
        skip: tddRedPhaseReason,
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );

  withServerpod(
    'Given DailyDecayService optimistic score writes (Story 6.3)',
    (sessionBuilder, endpoints) {
      final tenantA = sessionBuilder.copyWith(
        authentication: TestTenants.auth(TestTenants.a),
      );

      test(
        '[P0] AC-5 should keep the score written by a session logged between decay read and write',
        () async {
          final now = DateTime.now().toUtc();
          final racquet = await endpoints.bag.createRacquet(
            tenantA,
            racquetName: 'Yonex Ezone 98',
            materialCategory: StringMaterialCategory.coPoly,
            maxRatedHours: 20.0,
            stringingDate: now.subtract(const Duration(days: 30)),
          );
          final racquetId = racquet.id!;
          int? scoreWrittenBySession;

          await DailyDecayService.performDecayCalculation(
            sessionBuilder.build(),
            now: now.add(const Duration(days: 30)),
            afterPageRead: (_) async {
              await endpoints.session.logSession(
                tenantA,
                sessionLogFor(racquetId, durationMinutes: 90),
              );
              final bag = await endpoints.bag.getVirtualBag(tenantA);
              scoreWrittenBySession = bag
                  .firstWhere((r) => r.id == racquetId)
                  .activeStringJob!
                  .currentHealthScore;
            },
          );

          final bag = await endpoints.bag.getVirtualBag(tenantA);
          final job = bag.firstWhere((r) => r.id == racquetId).activeStringJob!;
          expect(job.currentHealthScore, equals(scoreWrittenBySession));
          expect(job.totalCourtHours, closeTo(1.5, 0.001));
        },
      );

      test(
        '[P0] AC-5 should still update untouched jobs in the page and count only written jobs',
        () async {
          final now = DateTime.now().toUtc();
          final stringingDate = now.subtract(const Duration(days: 30));
          final decayNow = now.add(const Duration(days: 30));
          final touched = await endpoints.bag.createRacquet(
            tenantA,
            racquetName: 'Yonex Ezone 98',
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
          );
          final untouched = await endpoints.bag.createRacquet(
            tenantA,
            racquetName: 'Yonex Percept 97',
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
          );

          final updatedCount = await DailyDecayService.performDecayCalculation(
            sessionBuilder.build(),
            now: decayNow,
            afterPageRead: (_) => endpoints.session.logSession(
              tenantA,
              sessionLogFor(touched.id!, durationMinutes: 90),
            ),
          );

          expect(updatedCount, equals(1));
          final bag = await endpoints.bag.getVirtualBag(tenantA);
          final untouchedJob = bag
              .firstWhere((r) => r.id == untouched.id)
              .activeStringJob!;
          expect(
            untouchedJob.currentHealthScore,
            equals(
              DecayEngine.calculateHealth(
                hoursPlayed: 0.0,
                maxRatedHours: 20.0,
                stringingDate: stringingDate,
                materialCategory: StringMaterialCategory.coPoly,
                now: decayNow,
              ),
            ),
          );
        },
      );

      test(
        '[P0] AC-5 should decay a skipped job on the next run',
        () async {
          final now = DateTime.now().toUtc();
          final stringingDate = now.subtract(const Duration(days: 30));
          final decayNow = now.add(const Duration(days: 30));
          final racquet = await endpoints.bag.createRacquet(
            tenantA,
            racquetName: 'Head Gravity MP',
            maxRatedHours: 20.0,
            stringingDate: stringingDate,
          );
          final racquetId = racquet.id!;

          final firstRun = await DailyDecayService.performDecayCalculation(
            sessionBuilder.build(),
            now: decayNow,
            afterPageRead: (_) => endpoints.session.logSession(
              tenantA,
              sessionLogFor(racquetId, durationMinutes: 90),
            ),
          );
          expect(firstRun, equals(0));

          final secondRun = await DailyDecayService.performDecayCalculation(
            sessionBuilder.build(),
            now: decayNow,
          );

          expect(secondRun, equals(1));
          final bag = await endpoints.bag.getVirtualBag(tenantA);
          final job = bag.firstWhere((r) => r.id == racquetId).activeStringJob!;
          expect(
            job.currentHealthScore,
            equals(
              DecayEngine.calculateHealth(
                hoursPlayed: 1.5,
                maxRatedHours: 20.0,
                stringingDate: stringingDate,
                materialCategory: StringMaterialCategory.coPoly,
                now: decayNow,
              ),
            ),
          );
        },
      );
    },
  );
}
