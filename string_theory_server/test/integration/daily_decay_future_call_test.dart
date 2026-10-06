import 'package:serverpod/serverpod.dart';
import 'package:serverpod_test/serverpod_test_public_exports.dart'
    as serverpod_test;
import 'package:string_theory_server/src/domain/decay_engine.dart';
import 'package:string_theory_server/src/future_calls/daily_decay_future_call.dart';
import 'package:string_theory_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given DailyDecayFutureCall and BagEndpoint.triggerDailyDecayNow',
    (sessionBuilder, endpoints) {
      final userSession = sessionBuilder.copyWith(
        authentication:
            serverpod_test.AuthenticationOverride.authenticationInfo(
              '101',
              {},
            ),
      );
      final unauthenticatedSession = sessionBuilder.copyWith(
        authentication: serverpod_test.AuthenticationOverride.unauthenticated(),
      );

      test(
        '[P0] AC-1 should scan active StringJob records, recalculate health via DecayEngine, and update database',
        () async {
          final session = sessionBuilder.build();
          final now = DateTime.now().toUtc();
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));

          // Create racquet
          final racquet = await Racquet.db.insertRow(
            session,
            Racquet(
              userId: 101,
              name: 'Wilson Pro Staff',
              isPrimary: true,
              createdAt: thirtyDaysAgo,
              updatedAt: thirtyDaysAgo,
            ),
          );

          // Active string job (co-poly, 30 days old, 0 court hours)
          // co-poly shelf life = 75 days, calendar penalty = (30/75)*30 = 12% drop -> health 88%
          final expectedHealth = DecayEngine.calculateHealth(
            hoursPlayed: 0.0,
            maxRatedHours: 20.0,
            stringingDate: thirtyDaysAgo,
            materialCategory: StringMaterialCategory.coPoly,
            now: now,
          );
          expect(expectedHealth, equals(88));

          final activeJob = await StringJob.db.insertRow(
            session,
            StringJob(
              userId: 101,
              racquetId: racquet.id!,
              materialCategory: StringMaterialCategory.coPoly,
              stringingDate: thirtyDaysAgo,
              maxRatedHours: 20.0,
              totalCourtHours: 0.0,
              currentHealthScore: 100, // initialized at 100, needs decay
              isActive: true,
              createdAt: thirtyDaysAgo,
            ),
          );

          // Inactive string job should NOT be updated
          final inactiveJob = await StringJob.db.insertRow(
            session,
            StringJob(
              userId: 101,
              racquetId: racquet.id!,
              materialCategory: StringMaterialCategory.coPoly,
              stringingDate: thirtyDaysAgo,
              maxRatedHours: 20.0,
              totalCourtHours: 0.0,
              currentHealthScore: 100,
              isActive: false,
              createdAt: thirtyDaysAgo,
            ),
          );

          // Execute daily decay calculation
          final updatedCount = await DailyDecayService.performDecayCalculation(
            session,
            now: now,
          );

          expect(updatedCount, greaterThanOrEqualTo(1));

          // Reload active job
          final reloadedActive = await StringJob.db.findById(
            session,
            activeJob.id!,
          );
          expect(reloadedActive, isNotNull);
          expect(reloadedActive!.currentHealthScore, equals(expectedHealth));

          // Reload inactive job - should remain 100
          final reloadedInactive = await StringJob.db.findById(
            session,
            inactiveJob.id!,
          );
          expect(reloadedInactive, isNotNull);
          expect(reloadedInactive!.currentHealthScore, equals(100));
        },
      );

      test(
        '[P0] AC-2 should execute decay calculation via BagEndpoint.triggerDailyDecayNow RPC and persist updated scores',
        () async {
          final session = sessionBuilder.build();
          final now = DateTime.now().toUtc();
          final fortyDaysAgo = now.subtract(const Duration(days: 40));

          final racquet = await Racquet.db.insertRow(
            session,
            Racquet(
              userId: 101,
              name: 'Yonex EZONE 98',
              isPrimary: false,
              createdAt: fortyDaysAgo,
              updatedAt: fortyDaysAgo,
            ),
          );

          final job = await StringJob.db.insertRow(
            session,
            StringJob(
              userId: 101,
              racquetId: racquet.id!,
              materialCategory: StringMaterialCategory.coPoly,
              stringingDate: fortyDaysAgo,
              maxRatedHours: 20.0,
              totalCourtHours: 0.0,
              currentHealthScore: 100,
              isActive: true,
              createdAt: fortyDaysAgo,
            ),
          );

          final updatedCount = await endpoints.bag.triggerDailyDecayNow(
            userSession,
          );
          expect(updatedCount, greaterThanOrEqualTo(1));

          final reloaded = await StringJob.db.findById(session, job.id!);
          expect(reloaded, isNotNull);
          // 40 days on co-poly (75 days shelf life) -> 100 - (40/75)*30 = 84%
          expect(reloaded!.currentHealthScore, lessThan(100));
        },
      );

      test(
        '[P1] AC-3 should throw ServerpodUnauthenticatedException when unauthenticated caller calls triggerDailyDecayNow',
        () async {
          expect(
            () => endpoints.bag.triggerDailyDecayNow(unauthenticatedSession),
            throwsA(isA<serverpod_test.ServerpodUnauthenticatedException>()),
          );
        },
      );

      test(
        '[P0] AC-4 should verify DailyDecayFutureCall.execute entrypoint and calculation idempotency',
        () async {
          final session = sessionBuilder.build();
          final futureCall = DailyDecayFutureCall();

          // Calling execute should complete without error
          await futureCall.execute(session);

          // Subsequent calculation immediately after should find 0 jobs requiring update (idempotent)
          final immediateSecondRun =
              await DailyDecayService.performDecayCalculation(session);
          expect(immediateSecondRun, equals(0));
        },
      );

      group('batch pagination', () {
        final now = DateTime.now().toUtc();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        final expectedHealth = DecayEngine.calculateHealth(
          hoursPlayed: 0.0,
          maxRatedHours: 20.0,
          stringingDate: thirtyDaysAgo,
          materialCategory: StringMaterialCategory.coPoly,
          now: now,
        );

        Future<List<StringJob>> seedJobs(
          Session session, {
          required int active,
          int inactive = 0,
        }) async {
          final racquet = await Racquet.db.insertRow(
            session,
            Racquet(
              userId: 101,
              name: 'Babolat Pure Aero',
              isPrimary: true,
              createdAt: thirtyDaysAgo,
              updatedAt: thirtyDaysAgo,
            ),
          );
          // Interleave inactive rows so pages straddle filtered-out ids.
          final activeFlags = [
            for (var i = 0; i < active || i < inactive; i++) ...[
              if (i < active) true,
              if (i < inactive) false,
            ],
          ];
          return StringJob.db.insert(session, [
            for (final isActive in activeFlags)
              StringJob(
                userId: 101,
                racquetId: racquet.id!,
                materialCategory: StringMaterialCategory.coPoly,
                stringingDate: thirtyDaysAgo,
                maxRatedHours: 20.0,
                totalCourtHours: 0.0,
                currentHealthScore: 100,
                isActive: isActive,
                createdAt: thirtyDaysAgo,
              ),
          ]);
        }

        test(
          '[P1] should update every active job exactly once across several pages and skip inactive ones',
          () async {
            final session = sessionBuilder.build();
            final jobs = await seedJobs(session, active: 5, inactive: 2);

            final updatedCount =
                await DailyDecayService.performDecayCalculation(
                  session,
                  now: now,
                  batchSize: 2,
                );

            expect(updatedCount, equals(5));
            for (final job in jobs) {
              final reloaded = await StringJob.db.findById(session, job.id!);
              expect(
                reloaded!.currentHealthScore,
                equals(job.isActive ? expectedHealth : 100),
              );
            }
          },
        );

        test(
          '[P1] should handle a batch size that divides the active row count exactly',
          () async {
            final session = sessionBuilder.build();
            final jobs = await seedJobs(session, active: 4);

            final updatedCount =
                await DailyDecayService.performDecayCalculation(
                  session,
                  now: now,
                  batchSize: 2,
                );

            expect(updatedCount, equals(4));
            for (final job in jobs) {
              final reloaded = await StringJob.db.findById(session, job.id!);
              expect(reloaded!.currentHealthScore, equals(expectedHealth));
            }
          },
        );

        test(
          '[P2] should reject a non-positive batch size',
          () async {
            final session = sessionBuilder.build();

            expect(
              () => DailyDecayService.performDecayCalculation(
                session,
                batchSize: 0,
              ),
              throwsArgumentError,
            );
          },
        );
      });
    },
  );
}
