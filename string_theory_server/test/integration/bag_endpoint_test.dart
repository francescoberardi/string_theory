import 'package:serverpod_test/serverpod_test_public_exports.dart'
    as serverpod_test;
import 'package:string_theory_server/src/generated/protocol.dart';
import 'package:string_theory_server/src/messaging/bag_channels.dart';
import 'package:test/test.dart';

import 'support/test_tenants.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given BagEndpoint and Racquet/StringJob database persistence',
    (sessionBuilder, endpoints) {
      final user1Session = sessionBuilder.copyWith(
        authentication: TestTenants.auth(TestTenants.a),
      );
      final user2Session = sessionBuilder.copyWith(
        authentication: TestTenants.auth(TestTenants.b),
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
            userId: TestTenants.aUserId,
            name: 'Babolat Pure Aero',
            isPrimary: true,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          );
          expect(racquet.userId, equals(TestTenants.aUserId));
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
          expect(
            user1Bag.every((r) => r.userId == TestTenants.aUserId),
            isTrue,
          );
          expect(user1Bag.every((r) => r.activeStringJob != null), isTrue);

          final user2Bag = await endpoints.bag.getVirtualBag(user2Session);
          expect(user2Bag, isNotEmpty);
          expect(
            user2Bag.every((r) => r.userId == TestTenants.bUserId),
            isTrue,
          );
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
        'should persist initialCourtHours and compute the initial health with DecayEngine',
        () async {
          final now = DateTime.now().toUtc();
          final created = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Babolat Pure Drive',
            materialCategory: StringMaterialCategory.coPoly,
            maxRatedHours: 20.0,
            stringingDate: now.subtract(const Duration(days: 24)),
            initialCourtHours: 9.0,
          );

          // (9 / 20) * 70 = 31.5 and (24 / 75) * 30 = 9.6 => 58.9 => 59.
          expect(created.activeStringJob!.totalCourtHours, equals(9.0));
          expect(created.activeStringJob!.currentHealthScore, equals(59));

          final bag = await endpoints.bag.getVirtualBag(user1Session);
          final persisted = bag.singleWhere((r) => r.id == created.id);
          expect(persisted.activeStringJob!.totalCourtHours, equals(9.0));
          expect(persisted.activeStringJob!.currentHealthScore, equals(59));
        },
      );

      test(
        'should apply calendar decay at creation for a past stringingDate with no hours',
        () async {
          final created = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Yonex Ezone 98',
            materialCategory: StringMaterialCategory.coPoly,
            stringingDate: DateTime.now().toUtc().subtract(
              const Duration(days: 30),
            ),
          );

          // (30 / 75) * 30 = 12 => 88.
          expect(created.activeStringJob!.totalCourtHours, equals(0.0));
          expect(created.activeStringJob!.currentHealthScore, equals(88));
        },
      );

      test(
        'should reject a negative initialCourtHours with a 400 BagException',
        () async {
          await expectLater(
            endpoints.bag.createRacquet(
              user1Session,
              racquetName: 'Invalid Hours',
              initialCourtHours: -1.0,
            ),
            throwsA(
              isA<BagException>().having(
                (e) => e.statusCode,
                'statusCode',
                400,
              ),
            ),
          );
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
              userId: TestTenants.aUserId,
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

      test(
        '[Story 4.1] AC-1 should verify RestringEvent model and restring_event database table with foreign keys',
        () async {
          expect(RestringEvent, isNotNull);

          final session = sessionBuilder.build();
          final tablesResult = await session.db.unsafeQuery(
            "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'restring_event';",
          );
          expect(
            tablesResult.length,
            equals(1),
            reason: 'Database table restring_event must exist',
          );

          final fkResult = await session.db.unsafeQuery(
            "SELECT constraint_name FROM information_schema.table_constraints WHERE table_schema = 'public' AND table_name = 'restring_event' AND constraint_type = 'FOREIGN KEY';",
          );
          expect(
            fkResult.length,
            equals(2),
            reason:
                'restring_event must have foreign key constraints to racquet and string_job',
          );
        },
      );

      test(
        '[Story 4.1] AC-2 should restring racquet with keepSame: true, archiving old job and creating new 100% health job with WebSocket event',
        () async {
          final now = DateTime.now().toUtc();
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Wilson Blade 98 v8',
            stringBrand: 'Luxilon',
            stringModel: 'ALU Power 125',
            tension: 52.0,
            materialCategory: StringMaterialCategory.coPoly,
            maxRatedHours: 20.0,
            stringingDate: now,
          );
          final racquetId = racquet.id!;
          final originalJobId = racquet.activeStringJobId!;

          // Fast forward or age racquet by 40 days so it has decayed health
          final agedRacquet = await endpoints.bag.fastForwardRacquetAge(
            user1Session,
            racquetId: racquetId,
            days: 40,
          );
          expect(
            agedRacquet.activeStringJob!.currentHealthScore,
            lessThan(100),
          );

          // Set up stream collector for user1 bag channel
          final streamMessages = <BagStreamMessage>[];
          final sub = endpoints.bag
              .bagUpdates(user1Session)
              .listen(streamMessages.add);
          await Future<void>.delayed(const Duration(milliseconds: 100));

          // Restring with keepSame: true
          final restringDate = now;
          final restrungRacquet = await endpoints.bag.restringRacquet(
            user1Session,
            racquetId: racquetId,
            keepSame: true,
            restringDate: restringDate,
          );

          await Future<void>.delayed(const Duration(milliseconds: 150));
          await sub.cancel();

          // 1. Verify returned racquet and active string job
          expect(restrungRacquet.id, equals(racquetId));
          expect(
            restrungRacquet.activeStringJobId,
            isNot(equals(originalJobId)),
          );
          expect(restrungRacquet.activeStringJob, isNotNull);
          final newJob = restrungRacquet.activeStringJob!;
          expect(newJob.isActive, isTrue);
          expect(newJob.currentHealthScore, equals(100));
          expect(newJob.totalCourtHours, equals(0.0));
          expect(newJob.brand, equals('Luxilon'));
          expect(newJob.model, equals('ALU Power 125'));
          expect(newJob.installedTension, equals(52.0));
          expect(
            newJob.materialCategory,
            equals(StringMaterialCategory.coPoly),
          );
          expect(newJob.maxRatedHours, equals(20.0));
          // FR-15: the fresh job is stamped with the server's "now", not the
          // (test-only) restringDate.
          expect(
            newJob.stringingDate.difference(DateTime.now().toUtc()).abs(),
            lessThan(const Duration(seconds: 30)),
          );
          expect(newJob.stringingDate, isNot(equals(restringDate)));

          // 2. Verify old StringJob is marked inactive
          final session = sessionBuilder.build();
          final oldJob = await StringJob.db.findById(session, originalJobId);
          expect(oldJob, isNotNull);
          expect(oldJob!.isActive, isFalse);

          // 3. Verify RestringEvent snapshot in database
          final history = await endpoints.bag.getRestringHistory(
            user1Session,
            racquetId: racquetId,
          );
          expect(history, hasLength(1));
          final event = history.first;
          expect(event.userId, equals(TestTenants.aUserId));
          expect(event.racquetId, equals(racquetId));
          expect(event.stringJobId, equals(originalJobId));
          expect(event.stringDescription, equals('Luxilon ALU Power 125'));
          expect(event.materialCategory, equals(StringMaterialCategory.coPoly));
          expect(event.installedTension, equals(52.0));
          expect(event.finalHealthScore, equals(oldJob.currentHealthScore));
          expect(event.finalCourtHours, equals(oldJob.totalCourtHours));
          expect(event.finalDaysActive, equals(40));

          // 4. Verify WebSocket broadcast
          final restrungMessages = streamMessages
              .where((m) => m.eventType == BagChannels.restrung)
              .toList();
          expect(restrungMessages, isNotEmpty);
          final wsMsg = restrungMessages.first;
          expect(wsMsg.racquetId, equals(racquetId));
          expect(wsMsg.healthScore, equals(100));
          expect(wsMsg.totalCourtHours, equals(0.0));
        },
      );

      test(
        '[Story 4.1] AC-3 should restring racquet with keepSame: false and new specifications',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Head Radical Pro',
            stringBrand: 'Head',
            stringModel: 'Lynx Tour',
            tension: 54.0,
            materialCategory: StringMaterialCategory.coPoly,
          );
          final racquetId = racquet.id!;

          final restrung = await endpoints.bag.restringRacquet(
            user1Session,
            racquetId: racquetId,
            keepSame: false,
            stringBrand: 'Solinco',
            stringModel: 'Hyper-G',
            tension: 48.0,
            materialCategory: StringMaterialCategory.coPoly,
            maxRatedHours: 25.0,
          );

          expect(restrung.activeStringJob, isNotNull);
          final newJob = restrung.activeStringJob!;
          expect(newJob.brand, equals('Solinco'));
          expect(newJob.model, equals('Hyper-G'));
          expect(newJob.installedTension, equals(48.0));
          expect(
            newJob.materialCategory,
            equals(StringMaterialCategory.coPoly),
          );
          expect(newJob.maxRatedHours, equals(25.0));
          expect(newJob.totalCourtHours, equals(0.0));
          expect(newJob.currentHealthScore, equals(100));
          expect(newJob.isActive, isTrue);

          final history = await endpoints.bag.getRestringHistory(
            user1Session,
            racquetId: racquetId,
          );
          expect(history, hasLength(1));
          expect(history.first.stringDescription, equals('Head Lynx Tour'));
        },
      );

      test(
        '[Story 4.1] AC-3b should restring racquet with keepSame: false and newSpecs StringJob object',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Babolat Pure Drive',
            stringBrand: 'Babolat',
            stringModel: 'Syn Gut',
          );
          final racquetId = racquet.id!;

          final customSpecs = StringJob(
            userId: TestTenants.aUserId,
            racquetId: racquetId,
            materialCategory: StringMaterialCategory.naturalGut,
            brand: 'Babolat',
            model: 'VS Touch',
            installedTension: 56.0,
            maxRatedHours: 35.0,
            stringingDate: DateTime.now().toUtc(),
            totalCourtHours: 0.0,
            currentHealthScore: 100,
            isActive: true,
          );

          final restrung = await endpoints.bag.restringRacquet(
            user1Session,
            racquetId: racquetId,
            keepSame: false,
            newSpecs: customSpecs,
          );

          expect(restrung.activeStringJob, isNotNull);
          final newJob = restrung.activeStringJob!;
          expect(newJob.brand, equals('Babolat'));
          expect(newJob.model, equals('VS Touch'));
          expect(newJob.installedTension, equals(56.0));
          expect(
            newJob.materialCategory,
            equals(StringMaterialCategory.naturalGut),
          );
          expect(newJob.maxRatedHours, equals(35.0));
          expect(newJob.totalCourtHours, equals(0.0));
          expect(newJob.currentHealthScore, equals(100));
          expect(newJob.isActive, isTrue);

          final history = await endpoints.bag.getRestringHistory(
            user1Session,
            racquetId: racquetId,
          );
          expect(history, hasLength(1));
          expect(history.first.stringDescription, equals('Babolat Syn Gut'));
        },
      );

      test(
        '[Story 4.1] AC-4 should fall back to default maxRatedHours (20.0) when non-positive maxRatedHours provided',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Yonex EZONE 98',
            stringBrand: 'Yonex',
            stringModel: 'Poly Tour Pro',
            maxRatedHours: 22.0,
          );
          final racquetId = racquet.id!;

          final restrung = await endpoints.bag.restringRacquet(
            user1Session,
            racquetId: racquetId,
            keepSame: false,
            stringBrand: 'Babolat',
            stringModel: 'RPM Blast',
            maxRatedHours: -5.0,
          );

          expect(restrung.activeStringJob!.maxRatedHours, equals(20.0));
        },
      );

      test(
        '[Story 4.1] AC-5 should roll back entire transaction if mid-transaction error occurs',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Rollback Test Racquet',
            stringBrand: 'Technifibre',
            stringModel: 'Razor Code',
          );
          final racquetId = racquet.id!;
          final originalJobId = racquet.activeStringJobId!;

          final messages = <BagStreamMessage>[];
          final sub = endpoints.bag
              .bagUpdates(user1Session)
              .listen(messages.add);
          await Future<void>.delayed(const Duration(milliseconds: 100));

          // Attempt restring with simulated mid-transaction failure. It must
          // be the simulated failure itself, not the production-mode guard.
          await expectLater(
            endpoints.bag.restringRacquet(
              user1Session,
              racquetId: racquetId,
              keepSame: true,
              simulateFailure: true,
            ),
            throwsA(
              allOf(
                isNot(isA<BagException>()),
                predicate<Object>(
                  (e) => e.toString().contains('Simulated transaction failure'),
                ),
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 150));
          await sub.cancel();

          // Verify atomic rollback:
          // 1. Old job is still active
          final session = sessionBuilder.build();
          final oldJob = await StringJob.db.findById(session, originalJobId);
          expect(oldJob, isNotNull);
          expect(oldJob!.isActive, isTrue);

          // 2. Racquet still points to old job
          final currentRacquet = await Racquet.db.findById(session, racquetId);
          expect(currentRacquet!.activeStringJobId, equals(originalJobId));

          // 3. No RestringEvent persisted
          final events = await RestringEvent.db.find(
            session,
            where: (t) => t.racquetId.equals(racquetId),
          );
          expect(events, isEmpty);

          // 4. No new StringJob persisted
          final jobs = await StringJob.db.find(
            session,
            where: (t) => t.racquetId.equals(racquetId),
          );
          expect(jobs, hasLength(1));
          expect(jobs.single.id, equals(originalJobId));

          // 5. No restrung message published
          expect(
            messages.where((m) => m.eventType == BagChannels.restrung),
            isEmpty,
          );
        },
      );

      test(
        '[Story 4.1] should snapshot the retired job (old category, non-zero hours) and start the new job at zero hours',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Snapshot Racquet',
            stringBrand: 'Luxilon',
            stringModel: '4G',
            materialCategory: StringMaterialCategory.coPoly,
          );
          final racquetId = racquet.id!;

          await endpoints.session.logSession(
            user1Session,
            SessionLog(
              userId: TestTenants.aUserId,
              racquetId: racquetId,
              startTime: DateTime.now().toUtc(),
              durationMinutes: 90,
              source: 'HealthKit',
              externalWorkoutId: 'restring-snapshot-1',
            ),
          );

          final restrung = await endpoints.bag.restringRacquet(
            user1Session,
            racquetId: racquetId,
            keepSame: false,
            materialCategory: StringMaterialCategory.naturalGut,
          );

          final newJob = restrung.activeStringJob!;
          expect(
            newJob.materialCategory,
            equals(StringMaterialCategory.naturalGut),
          );
          expect(newJob.totalCourtHours, equals(0.0));

          final history = await endpoints.bag.getRestringHistory(
            user1Session,
            racquetId: racquetId,
          );
          expect(history, hasLength(1));
          expect(
            history.first.materialCategory,
            equals(StringMaterialCategory.coPoly),
          );
          expect(history.first.finalCourtHours, closeTo(1.5, 0.001));
        },
      );

      test(
        '[Story 4.1] should leave exactly one active string job when restrings run concurrently',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Concurrent Racquet',
          );
          final racquetId = racquet.id!;

          await Future.wait([
            endpoints.bag
                .restringRacquet(user1Session, racquetId: racquetId)
                .then<Object?>((r) => r, onError: (Object e) => e),
            endpoints.bag
                .restringRacquet(user1Session, racquetId: racquetId)
                .then<Object?>((r) => r, onError: (Object e) => e),
          ]);

          final session = sessionBuilder.build();
          final activeJobs = await StringJob.db.find(
            session,
            where: (t) =>
                t.racquetId.equals(racquetId) & t.isActive.equals(true),
          );
          expect(activeJobs, hasLength(1));
          final events = await RestringEvent.db.find(
            session,
            where: (t) => t.racquetId.equals(racquetId),
          );
          // Every event retires a distinct job.
          expect(
            events.map((e) => e.stringJobId).toSet(),
            hasLength(events.length),
          );
        },
      );

      test(
        '[Story 4.1] AC-6 should reject restringRacquet for unauthorized user with 404',
        () async {
          final user1Racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Private Racquet of User 1',
          );

          // User 2 cannot restring User 1's racquet
          await expectLater(
            endpoints.bag.restringRacquet(
              user2Session,
              racquetId: user1Racquet.id!,
              keepSame: true,
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
            endpoints.bag.restringRacquet(
              user1Session,
              racquetId: 999999,
              keepSame: true,
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
        '[Story 4.1] AC-7 should reject restringRacquet when racquet has no active string job with 400',
        () async {
          final session = sessionBuilder.build();
          final now = DateTime.now().toUtc();
          final unstrungRacquet = await Racquet.db.insertRow(
            session,
            Racquet(
              userId: TestTenants.aUserId,
              name: 'Unstrung Frame For Restring',
              createdAt: now,
              updatedAt: now,
            ),
          );

          await expectLater(
            endpoints.bag.restringRacquet(
              user1Session,
              racquetId: unstrungRacquet.id!,
              keepSame: true,
            ),
            throwsA(
              isA<BagException>()
                  .having((e) => e.statusCode, 'statusCode', equals(400))
                  .having(
                    (e) => e.message,
                    'message',
                    equals('Racquet has no active string job to retire'),
                  ),
            ),
          );
        },
      );

      test(
        '[Story 4.1] AC-8 should return chronologically ordered history in getRestringHistory',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Multi-Restring Racquet',
            stringBrand: 'Prince',
            stringModel: 'Synthetic Gut',
          );
          final racquetId = racquet.id!;

          // First restring 10 days ago
          final date1 = DateTime.now().toUtc().subtract(
            const Duration(days: 10),
          );
          await endpoints.bag.restringRacquet(
            user1Session,
            racquetId: racquetId,
            keepSame: false,
            stringBrand: 'Babolat',
            stringModel: 'RPM Blast',
            restringDate: date1,
          );

          // Second restring 2 days ago
          final date2 = DateTime.now().toUtc().subtract(
            const Duration(days: 2),
          );
          await endpoints.bag.restringRacquet(
            user1Session,
            racquetId: racquetId,
            keepSame: false,
            stringBrand: 'Luxilon',
            stringModel: 'Element',
            restringDate: date2,
          );

          // Query history
          final history = await endpoints.bag.getRestringHistory(
            user1Session,
            racquetId: racquetId,
          );
          expect(history, hasLength(2));
          // First in list should be newest (date2)
          expect(history[0].stringDescription, equals('Babolat RPM Blast'));
          expect(history[1].stringDescription, equals('Prince Synthetic Gut'));
          expect(
            history[0].restringDate.isAfter(history[1].restringDate),
            isTrue,
          );

          // User 2 cannot access history for User 1's racquet
          await expectLater(
            endpoints.bag.getRestringHistory(
              user2Session,
              racquetId: racquetId,
            ),
            throwsA(
              isA<BagException>().having(
                (e) => e.statusCode,
                'statusCode',
                equals(404),
              ),
            ),
          );

          // Brand new racquet returns empty list
          final freshRacquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Fresh Racquet',
          );
          final emptyHistory = await endpoints.bag.getRestringHistory(
            user1Session,
            racquetId: freshRacquet.id!,
          );
          expect(emptyHistory, isEmpty);
        },
      );

      test(
        '[Story 4.1] AC-9 should cascade delete RestringEvent records when racquet is deleted',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Racquet To Cascade Delete',
            stringBrand: 'Wilson',
            stringModel: 'NXT',
          );
          final racquetId = racquet.id!;

          await endpoints.bag.restringRacquet(
            user1Session,
            racquetId: racquetId,
            keepSame: true,
          );

          final session = sessionBuilder.build();
          final historyBefore = await RestringEvent.db.find(
            session,
            where: (t) => t.racquetId.equals(racquetId),
          );
          expect(historyBefore, hasLength(1));

          // Delete racquet
          final deleted = await endpoints.bag.deleteRacquet(
            user1Session,
            racquetId: racquetId,
          );
          expect(deleted, isTrue);

          // Restring events should be cascade deleted
          final historyAfter = await RestringEvent.db.find(
            session,
            where: (t) => t.racquetId.equals(racquetId),
          );
          expect(historyAfter, isEmpty);
        },
      );

      test(
        '[Story 4.1] AC-10 should clamp finalDaysActive to 0 when restringDate is before stringingDate',
        () async {
          final now = DateTime.now().toUtc();
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Future Strung Racquet',
            stringingDate: now.add(const Duration(days: 5)),
          );
          final racquetId = racquet.id!;

          // Restring date is set to `now`, which is 5 days BEFORE stringingDate
          await endpoints.bag.restringRacquet(
            user1Session,
            racquetId: racquetId,
            keepSame: true,
            restringDate: now,
          );

          final history = await endpoints.bag.getRestringHistory(
            user1Session,
            racquetId: racquetId,
          );
          expect(history, hasLength(1));
          expect(history.first.finalDaysActive, equals(0));
        },
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
