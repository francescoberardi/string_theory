import 'dart:async';

import 'package:serverpod_test/serverpod_test_public_exports.dart'
    as serverpod_test;
import 'package:string_theory_server/src/generated/protocol.dart';
import 'package:string_theory_server/src/messaging/bag_channels.dart';
import 'package:test/test.dart';

import 'support/test_tenants.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given BagEndpoint.bagUpdates real-time stream',
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

      /// Subscribes to [stream] and collects every message it delivers.
      ({List<BagStreamMessage> messages, StreamSubscription sub}) collect(
        Stream<BagStreamMessage> stream,
      ) {
        final messages = <BagStreamMessage>[];
        final sub = stream.listen(messages.add);
        return (messages: messages, sub: sub);
      }

      Future<void> settle() =>
          Future<void>.delayed(const Duration(milliseconds: 200));

      test(
        '[P0] should deliver a sessionLogged message with new health and hours within 300 ms',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Wilson Blade 98',
            materialCategory: StringMaterialCategory.coPoly,
            maxRatedHours: 20.0,
          );
          final racquetId = racquet.id!;

          final stream = endpoints.bag.bagUpdates(user1Session);
          final first = stream.first.timeout(const Duration(seconds: 5));
          // Allow the stream subscription to register on the channel.
          await settle();

          final stopwatch = Stopwatch()..start();
          await endpoints.session.logSession(
            user1Session,
            sessionLogFor(racquetId, externalWorkoutId: 'hk-stream-1'),
          );
          final message = await first;
          stopwatch.stop();

          final bag = await endpoints.bag.getVirtualBag(user1Session);
          final job = bag.firstWhere((r) => r.id == racquetId).activeStringJob!;

          expect(message.eventType, equals('sessionLogged'));
          expect(message.racquetId, equals(racquetId));
          expect(message.healthScore, equals(job.currentHealthScore));
          expect(message.totalCourtHours, closeTo(1.5, 0.001));
          expect(
            stopwatch.elapsedMilliseconds,
            lessThan(300),
            reason: 'NFR-2: update must arrive in under 300 ms',
          );
        },
      );

      test(
        '[P0] should not deliver user 1 sessionLogged events to a user 2 subscriber',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Head Speed MP',
          );

          final user2 = collect(endpoints.bag.bagUpdates(user2Session));
          final user1 = collect(endpoints.bag.bagUpdates(user1Session));
          await settle();

          await endpoints.session.logSession(
            user1Session,
            sessionLogFor(racquet.id!),
          );
          await settle();

          expect(user1.messages, hasLength(1));
          expect(user2.messages, isEmpty);

          await user1.sub.cancel();
          await user2.sub.cancel();
        },
      );

      test(
        '[P0] should not deliver user 1 restring events to a user 2 subscriber',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Prince Phantom 100X',
          );
          final user2Racquet = await endpoints.bag.createRacquet(
            user2Session,
            racquetName: "User 2's Frame",
          );

          final user2 = collect(endpoints.bag.bagUpdates(user2Session));
          final user1 = collect(endpoints.bag.bagUpdates(user1Session));
          await settle();

          try {
            await endpoints.bag.restringRacquet(
              user1Session,
              racquetId: racquet.id!,
            );
            await settle();

            expect(user1.messages, hasLength(1));
            expect(
              user1.messages.single.eventType,
              equals(BagChannels.restrung),
            );
            expect(user1.messages.single.racquetId, equals(racquet.id));
            expect(user2.messages, isEmpty);

            // Positive control: user 2's stream is live and receives its own
            // restring, which in turn never reaches user 1.
            await endpoints.bag.restringRacquet(
              user2Session,
              racquetId: user2Racquet.id!,
            );
            await settle();

            expect(user2.messages, hasLength(1));
            expect(
              user2.messages.single.eventType,
              equals(BagChannels.restrung),
            );
            expect(user2.messages.single.racquetId, equals(user2Racquet.id));
            expect(user1.messages, hasLength(1));
          } finally {
            await user1.sub.cancel();
            await user2.sub.cancel();
          }
        },
      );

      test(
        '[P0] should deliver nothing to either user when user 2 restrings user 1 racquet',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Tecnifibre TF40',
          );

          final user2 = collect(endpoints.bag.bagUpdates(user2Session));
          final user1 = collect(endpoints.bag.bagUpdates(user1Session));
          await settle();

          try {
            await expectLater(
              endpoints.bag.restringRacquet(
                user2Session,
                racquetId: racquet.id!,
              ),
              throwsA(
                isA<BagException>().having((e) => e.statusCode, 'status', 404),
              ),
            );
            await settle();

            expect(user1.messages, isEmpty);
            expect(user2.messages, isEmpty);

            // Positive control: user 1's stream is live, so the empty check
            // above means the rejected restring published nothing.
            await endpoints.bag.restringRacquet(
              user1Session,
              racquetId: racquet.id!,
            );
            await settle();

            expect(user1.messages, hasLength(1));
            expect(user1.messages.single.racquetId, equals(racquet.id));
            expect(user2.messages, isEmpty);
          } finally {
            await user1.sub.cancel();
            await user2.sub.cancel();
          }
        },
      );

      test(
        '[P0] should deliver exactly one message for an idempotent replay',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Babolat Pure Aero',
          );

          final user1 = collect(endpoints.bag.bagUpdates(user1Session));
          await settle();

          final log = sessionLogFor(
            racquet.id!,
            externalWorkoutId: 'hk-stream-replay',
          );
          await endpoints.session.logSession(user1Session, log);
          await endpoints.session.logSession(user1Session, log);
          await settle();

          expect(user1.messages, hasLength(1));

          await user1.sub.cancel();
        },
      );

      test(
        '[P1] should deliver nothing when logSession fails with 400, 404 or 409',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            user1Session,
            racquetName: 'Yonex VCORE 98',
          );
          final user2Racquet = await endpoints.bag.createRacquet(
            user2Session,
            racquetName: "User 2's Frame",
          );
          // Register a workout to user 2 so user 1 hits 409 on the same id.
          await endpoints.session.logSession(
            user2Session,
            sessionLogFor(
              user2Racquet.id!,
              externalWorkoutId: 'hk-stream-foreign',
            ),
          );

          final user1 = collect(endpoints.bag.bagUpdates(user1Session));
          await settle();

          await expectLater(
            endpoints.session.logSession(
              user1Session,
              sessionLogFor(racquet.id!, durationMinutes: 0),
            ),
            throwsA(
              isA<BagException>().having((e) => e.statusCode, 'status', 400),
            ),
          );
          await expectLater(
            endpoints.session.logSession(
              user1Session,
              sessionLogFor(user2Racquet.id!),
            ),
            throwsA(
              isA<BagException>().having((e) => e.statusCode, 'status', 404),
            ),
          );
          await expectLater(
            endpoints.session.logSession(
              user1Session,
              sessionLogFor(
                racquet.id!,
                externalWorkoutId: 'hk-stream-foreign',
              ),
            ),
            throwsA(
              isA<BagException>().having((e) => e.statusCode, 'status', 409),
            ),
          );
          await settle();

          expect(user1.messages, isEmpty);

          await user1.sub.cancel();
        },
      );

      test(
        '[P1] should reject an unauthenticated subscription',
        () async {
          await expectLater(
            endpoints.bag.bagUpdates(unauthenticatedSession).first,
            throwsA(isA<serverpod_test.ServerpodUnauthenticatedException>()),
          );
        },
      );
    },
  );

  // Concurrent transactions require real commits, so rollbacks are disabled.
  withServerpod(
    'Given concurrent logSession calls racing on the same external workout',
    (sessionBuilder, endpoints) {
      final userSession = sessionBuilder.copyWith(
        authentication: TestTenants.auth(TestTenants.e),
      );

      test(
        '[P0] should publish exactly one message when the unique-violation race branch returns the winner',
        () async {
          final racquet = await endpoints.bag.createRacquet(
            userSession,
            racquetName: 'Wilson Clash 100',
          );
          final racquetId = racquet.id!;
          final externalId =
              'hk-stream-race-${DateTime.now().microsecondsSinceEpoch}';

          final messages = <BagStreamMessage>[];
          final sub = endpoints.bag
              .bagUpdates(userSession)
              .listen(messages.add);
          try {
            await Future<void>.delayed(const Duration(milliseconds: 200));

            final logInput = SessionLog(
              userId: TestTenants.eUserId,
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
            expect(results[1].id, equals(results[0].id));

            await Future<void>.delayed(const Duration(milliseconds: 200));
            expect(messages, hasLength(1));
          } finally {
            await sub.cancel();
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
