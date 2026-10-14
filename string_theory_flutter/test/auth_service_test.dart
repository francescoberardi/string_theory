import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/services/auth_service.dart';
import 'package:string_theory_flutter/services/offline_session_queue.dart';

import 'helpers/fake_auth.dart' hide FakeEndpointAnonymousIdp;

class FakeEndpointAnonymousIdp implements EndpointAnonymousIdp {
  AuthSuccess? successToReturn;
  Exception? exceptionToThrow;
  Completer<void>? gate;
  int loginCalls = 0;
  String? lastTokenReceived;

  @override
  Future<AuthSuccess> login({String? token}) async {
    loginCalls++;
    lastTokenReceived = token;
    await gate?.future;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    final success = successToReturn;
    if (success == null) {
      throw StateError(
        'FakeEndpointAnonymousIdp.login called without successToReturn or '
        'exceptionToThrow configured',
      );
    }
    return success;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

SessionLog _queuedLog() => SessionLog(
  userId: Namespace.nil.uuidValue,
  racquetId: 1,
  startTime: DateTime.utc(2026, 10, 4, 17),
  durationMinutes: 60,
  source: 'manual',
  externalWorkoutId: 'hk-queued',
);

void main() {
  group('AuthService', () {
    final testUserId = UuidValue.fromString(
      '11111111-2222-3333-4444-555555555555',
    );
    final otherUserId = UuidValue.fromString(
      '66666666-7777-8888-9999-000000000000',
    );
    final sampleAuthSuccess = AuthSuccess(
      authStrategy: 'session',
      token: 'test-token',
      authUserId: testUserId,
      scopeNames: {},
    );
    final otherAuthSuccess = AuthSuccess(
      authStrategy: 'session',
      token: 'other-token',
      authUserId: otherUserId,
      scopeNames: {},
    );

    test(
      'given fresh install (no session), when initialize() is called, then stays signed out without creating a guest',
      () async {
        final storage = InMemoryAuthSuccessStorage();
        final client = buildOfflineTestClient(storage);
        final fakeEndpoint = FakeEndpointAnonymousIdp()
          ..successToReturn = sampleAuthSuccess;

        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
        );

        final result = await authService.initialize();

        expect(result, isFalse);
        expect(fakeEndpoint.loginCalls, 0);
        expect(authService.isAuthenticated, isFalse);
        expect(authService.account.value, AccountInfo.signedOut);
        expect(await storage.get(), isNull);
      },
    );

    group('initialize with a stored session', () {
      late InMemoryAuthSuccessStorage storage;
      late FakeAuthStatus status;
      late FakeEndpointAnonymousIdp fakeEndpoint;
      late InMemorySessionQueueStorage queueStorage;
      late OfflineSessionQueue queue;

      Future<AuthService> storedSession(FakeAuthStatus authStatus) async {
        storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        status = authStatus;
        fakeEndpoint = FakeEndpointAnonymousIdp();
        queueStorage = InMemorySessionQueueStorage();
        queue = OfflineSessionQueue(storage: queueStorage);
        await queue.enqueue(_queuedLog());
        return AuthService(
          client: buildOfflineTestClient(storage, status: status),
          anonymousEndpoint: fakeEndpoint,
          fetchAccountEmail: () async => 'judge@example.com',
          offlineQueue: queue,
        );
      }

      test(
        'given the server confirms the session, keeps the user and the account without a guest login',
        () async {
          final authService = await storedSession(FakeAuthStatus());

          final result = await authService.initialize();
          await pumpEventQueue();

          expect(result, isTrue);
          expect(status.isSignedInCalls, 1);
          expect(status.signOutDeviceCalls, 0);
          expect(authService.currentUserId, testUserId.uuid);
          expect(
            authService.account.value,
            const AccountInfo.email('judge@example.com'),
          );
          expect(queue.pendingCount, 1);
          expect(fakeEndpoint.loginCalls, 0);
        },
      );

      test(
        'given the session was revoked, signs out once, clears the queue, and a later guest sign-in works',
        () async {
          final authService = await storedSession(
            FakeAuthStatus(signedIn: false),
          );

          final result = await authService.initialize();
          await pumpEventQueue();

          expect(result, isFalse);
          expect(status.isSignedInCalls, 1);
          expect(status.signOutDeviceCalls, 1);
          expect(authService.isAuthenticated, isFalse);
          expect(await storage.get(), isNull);
          expect(authService.account.value, AccountInfo.signedOut);
          expect(queue.pendingCount, 0);
          expect(await queueStorage.read(), isEmpty);

          fakeEndpoint.successToReturn = otherAuthSuccess;
          expect(await authService.continueAsGuest(), isTrue);

          expect(authService.currentUserId, otherUserId.uuid);
          expect(authService.account.value, AccountInfo.guest);
          expect(fakeEndpoint.loginCalls, 1);
        },
      );

      test(
        'given the server check fails, keeps the session without calling login',
        () async {
          final authService = await storedSession(
            FakeAuthStatus(
              isSignedInError: ServerpodClientInternalServerError(),
            ),
          );

          final result = await authService.initialize();
          await pumpEventQueue();

          expect(result, isTrue);
          expect(status.isSignedInCalls, 1);
          expect(status.signOutDeviceCalls, 0);
          expect(authService.currentUserId, testUserId.uuid);
          expect(await storage.get(), sampleAuthSuccess);
          expect(queue.pendingCount, 1);
          expect(fakeEndpoint.loginCalls, 0);
        },
      );

      test(
        'given the server never answers, keeps the session once the 2 s check times out',
        () async {
          final authService = await storedSession(
            FakeAuthStatus(isSignedInHangs: true),
          );

          fakeAsync((async) {
            bool? result;
            unawaited(authService.initialize().then((r) => result = r));

            async.elapse(const Duration(milliseconds: 1999));
            expect(result, isNull, reason: 'still waiting for the server');

            async.elapse(const Duration(milliseconds: 1));
            expect(result, isTrue);
            expect(status.isSignedInCalls, 1);
            expect(status.signOutDeviceCalls, 0);
            expect(authService.currentUserId, testUserId.uuid);
            expect(queue.pendingCount, 1);
          });
          expect(await storage.get(), sampleAuthSuccess);
        },
      );

      test(
        'given the sign-out call fails, clears the local session anyway',
        () async {
          final authService = await storedSession(
            FakeAuthStatus(
              signOutError: const ServerpodClientNetworkException('offline'),
            ),
          );
          await authService.initialize();
          expect(authService.isAuthenticated, isTrue);

          await authService.signOut();

          expect(status.signOutDeviceCalls, 1);
          expect(authService.isAuthenticated, isFalse);
          expect(await storage.get(), isNull);
          expect(authService.account.value, AccountInfo.signedOut);
          expect(queue.pendingCount, 0);
        },
      );
    });

    test(
      'given continueAsGuest, when the anonymous login succeeds, then signs in as a guest',
      () async {
        final storage = InMemoryAuthSuccessStorage();
        final client = buildOfflineTestClient(storage);
        var emailFetches = 0;
        final fakeEndpoint = FakeEndpointAnonymousIdp()
          ..successToReturn = sampleAuthSuccess;
        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
          fetchAccountEmail: () async {
            emailFetches++;
            return null;
          },
        );
        await authService.initialize();

        final result = await authService.continueAsGuest();

        expect(result, isTrue);
        expect(authService.isAuthenticated, isTrue);
        expect(await storage.get(), equals(sampleAuthSuccess));
        expect(authService.account.value, AccountInfo.guest);
        expect(emailFetches, 0, reason: 'a new guest has no email to load');
      },
    );

    test(
      'given continueAsGuest and network failure, then the error is propagated and the user stays signed out',
      () async {
        final storage = InMemoryAuthSuccessStorage();
        final client = buildOfflineTestClient(storage);
        final fakeEndpoint = FakeEndpointAnonymousIdp()
          ..exceptionToThrow = Exception(
            'Network error connecting to Serverpod',
          );

        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
        );
        await authService.initialize();

        await expectLater(
          authService.continueAsGuest(),
          throwsA(isA<Exception>()),
        );
        expect(authService.isAuthenticated, isFalse);
      },
    );

    test(
      'given concurrent continueAsGuest calls, then deduplicates in-flight calls to single endpoint invocation',
      () async {
        final storage = InMemoryAuthSuccessStorage();
        final client = buildOfflineTestClient(storage);
        final fakeEndpoint = FakeEndpointAnonymousIdp()
          ..successToReturn = sampleAuthSuccess
          ..gate = Completer<void>();

        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
        );

        final both = Future.wait([
          authService.continueAsGuest(),
          authService.continueAsGuest(),
        ]);
        fakeEndpoint.gate!.complete();
        final results = await both;

        expect(results, equals([true, true]));
        expect(fakeEndpoint.loginCalls, equals(1));
        expect(authService.isAuthenticated, isTrue);
      },
    );

    test(
      'given continueAsGuest with token, then forwards token to anonymous endpoint',
      () async {
        final storage = InMemoryAuthSuccessStorage();
        final client = buildOfflineTestClient(storage);
        final fakeEndpoint = FakeEndpointAnonymousIdp()
          ..successToReturn = sampleAuthSuccess;

        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
        );

        await authService.continueAsGuest(token: 'attestation-token-xyz');
        expect(fakeEndpoint.lastTokenReceived, equals('attestation-token-xyz'));
      },
    );

    test(
      'given authenticated user, when signOut() is called, then the session and the offline queue are cleared',
      () async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = buildOfflineTestClient(storage);
        final queueStorage = InMemorySessionQueueStorage();
        final queue = OfflineSessionQueue(storage: queueStorage);
        await queue.enqueue(_queuedLog());

        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          fetchAccountEmail: () async => null,
          offlineQueue: queue,
        );
        await authService.initialize();
        expect(authService.isAuthenticated, isTrue);

        await authService.signOut();

        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUserId, isNull);
        expect(await storage.get(), isNull);
        expect(authService.account.value, AccountInfo.signedOut);
        expect(queue.pendingCount, 0);
        expect(await queueStorage.read(), isEmpty);
      },
    );

    test(
      'a token refresh for the same user keeps the account and the offline queue',
      () async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = buildOfflineTestClient(storage);
        final queue = OfflineSessionQueue(
          storage: InMemorySessionQueueStorage(),
        );
        await queue.enqueue(_queuedLog());
        var fetches = 0;
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          fetchAccountEmail: () async {
            fetches++;
            return 'judge@example.com';
          },
          offlineQueue: queue,
        );
        await authService.initialize();
        await pumpEventQueue();
        final accountBefore = authService.account.value;
        final fetchesBefore = fetches;

        await client.auth.updateSignedInUser(
          AuthSuccess(
            authStrategy: 'session',
            token: 'rotated-token',
            authUserId: testUserId,
            scopeNames: {},
          ),
        );
        await pumpEventQueue();

        expect(queue.pendingCount, 1);
        expect(authService.account.value, accountBefore);
        expect(
          authService.account.value,
          const AccountInfo.email('judge@example.com'),
        );
        expect(fetches, fetchesBefore);
      },
    );

    group('account', () {
      test('given a stored email session, loads the account email', () async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = buildOfflineTestClient(storage);
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          fetchAccountEmail: () async => 'judge@example.com',
        );

        await authService.initialize();
        await pumpEventQueue();

        expect(
          authService.account.value,
          const AccountInfo.email('judge@example.com'),
        );
        expect(authService.account.value.isGuest, isFalse);
      });

      test('given a stored guest session, reports a guest', () async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = buildOfflineTestClient(storage);
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          fetchAccountEmail: () async => null,
        );

        await authService.initialize();
        await pumpEventQueue();

        expect(authService.account.value, AccountInfo.guest);
        expect(authService.account.value.isGuest, isTrue);
      });

      test(
        'given the email lookup fails, reports an unknown account',
        () async {
          final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
          final client = buildOfflineTestClient(storage);
          final authService = AuthService(
            client: client,
            anonymousEndpoint: FakeEndpointAnonymousIdp(),
            fetchAccountEmail: () async => throw Exception('offline'),
          );

          await authService.initialize();
          await pumpEventQueue();

          expect(authService.account.value, AccountInfo.unknown);
          expect(authService.account.value.isGuest, isFalse);
        },
      );

      test('refreshAccount retries a failed lookup', () async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = buildOfflineTestClient(storage);
        var fail = true;
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          fetchAccountEmail: () async {
            if (fail) throw Exception('offline');
            return 'judge@example.com';
          },
        );
        await authService.initialize();
        await pumpEventQueue();
        expect(authService.account.value, AccountInfo.unknown);

        fail = false;
        await authService.refreshAccount();

        expect(
          authService.account.value,
          const AccountInfo.email('judge@example.com'),
        );
      });

      test('a lookup for a previous identity is ignored', () async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = buildOfflineTestClient(storage);
        final firstLookup = Completer<String?>();
        var calls = 0;
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          fetchAccountEmail: () {
            calls++;
            return calls == 1 ? firstLookup.future : Future.value('b@x.com');
          },
        );
        await authService.initialize();

        await client.auth.updateSignedInUser(otherAuthSuccess);
        await pumpEventQueue();
        firstLookup.complete('a@x.com');
        await pumpEventQueue();

        expect(authService.account.value, const AccountInfo.email('b@x.com'));
      });
    });

    group('validateSession', () {
      test(
        'given the session was revoked elsewhere, signs out and clears the offline queue',
        () async {
          final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
          final client = buildOfflineTestClient(storage);
          final queueStorage = InMemorySessionQueueStorage();
          final queue = OfflineSessionQueue(storage: queueStorage);
          await queue.enqueue(_queuedLog());
          final authService = AuthService(
            client: client,
            anonymousEndpoint: FakeEndpointAnonymousIdp(),
            fetchAccountEmail: () async => null,
            offlineQueue: queue,
            // Mirrors validateAuthentication on a revoked session.
            validateAuthentication: () async {
              await client.auth.updateSignedInUser(null);
              return true;
            },
          );
          await authService.initialize();

          await authService.validateSession();
          await pumpEventQueue();

          expect(authService.isAuthenticated, isFalse);
          expect(authService.account.value, AccountInfo.signedOut);
          expect(queue.pendingCount, 0);
          expect(await queueStorage.read(), isEmpty);
        },
      );

      test(
        'given the server check fails, keeps the session (real validation path)',
        () async {
          final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
          final status = FakeAuthStatus.unreachable();
          final client = buildOfflineTestClient(storage, status: status);
          final authService = AuthService(
            client: client,
            anonymousEndpoint: FakeEndpointAnonymousIdp(),
            fetchAccountEmail: () async => null,
          );
          await authService.initialize();

          await authService.validateSession();

          expect(status.isSignedInCalls, 2);
          expect(authService.isAuthenticated, isTrue);
          expect(await storage.get(), isNotNull);
        },
      );

      test(
        'given the session is revoked after start-up, signs out and clears the offline queue (real validation path)',
        () async {
          final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
          final status = FakeAuthStatus(signedIn: true);
          final client = buildOfflineTestClient(storage, status: status);
          final queueStorage = InMemorySessionQueueStorage();
          final queue = OfflineSessionQueue(storage: queueStorage);
          await queue.enqueue(_queuedLog());
          final authService = AuthService(
            client: client,
            anonymousEndpoint: FakeEndpointAnonymousIdp(),
            fetchAccountEmail: () async => null,
            offlineQueue: queue,
          );
          await authService.initialize();
          expect(authService.isAuthenticated, isTrue);

          status.signedIn = false;
          await authService.validateSession();
          await pumpEventQueue();

          expect(status.isSignedInCalls, 2);
          expect(status.signOutDeviceCalls, 1);
          expect(authService.isAuthenticated, isFalse);
          expect(await storage.get(), isNull);
          expect(authService.account.value, AccountInfo.signedOut);
          expect(queue.pendingCount, 0);
          expect(await queueStorage.read(), isEmpty);
        },
      );

      test('given no session, does not validate', () async {
        final client = buildOfflineTestClient(InMemoryAuthSuccessStorage());
        var calls = 0;
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          validateAuthentication: () async {
            calls++;
            return true;
          },
        );
        await authService.initialize();

        await authService.validateSession();

        expect(calls, 0);
      });

      test('concurrent and back-to-back checks share one validation', () async {
        final client = buildOfflineTestClient(
          InMemoryAuthSuccessStorage(sampleAuthSuccess),
        );
        final gate = Completer<bool>();
        var calls = 0;
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          fetchAccountEmail: () async => null,
          validateAuthentication: () {
            calls++;
            return gate.future;
          },
        );
        await authService.initialize();

        final first = authService.validateSession();
        final second = authService.validateSession();
        gate.complete(true);
        await Future.wait<void>([first, second]);
        await authService.validateSession();

        expect(calls, 1);
      });

      test('a failed validation does not throw', () async {
        final client = buildOfflineTestClient(
          InMemoryAuthSuccessStorage(sampleAuthSuccess),
        );
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          fetchAccountEmail: () async => null,
          validateAuthentication: () async => throw TimeoutException('slow'),
        );
        await authService.initialize();

        await expectLater(authService.validateSession(), completes);
        expect(authService.isAuthenticated, isTrue);
      });

      test('a check runs again once the cooldown has passed', () async {
        final client = buildOfflineTestClient(
          InMemoryAuthSuccessStorage(sampleAuthSuccess),
        );
        var calls = 0;
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          fetchAccountEmail: () async => null,
          validateAuthentication: () async {
            calls++;
            return true;
          },
        );
        await authService.initialize();
        final start = DateTime.utc(2026, 10, 14, 9);

        await withClock(Clock.fixed(start), authService.validateSession);
        await withClock(
          Clock.fixed(start.add(const Duration(seconds: 5))),
          authService.validateSession,
        );
        await withClock(
          Clock.fixed(start.add(AuthService.validationCooldown)),
          authService.validateSession,
        );

        expect(calls, 2);
      });

      test('a new identity does not inherit the previous cooldown', () async {
        final client = buildOfflineTestClient(
          InMemoryAuthSuccessStorage(sampleAuthSuccess),
        );
        var calls = 0;
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          fetchAccountEmail: () async => null,
          validateAuthentication: () async {
            calls++;
            return true;
          },
        );
        await authService.initialize();
        final start = DateTime.utc(2026, 10, 14, 9);

        await withClock(Clock.fixed(start), authService.validateSession);
        await client.auth.updateSignedInUser(otherAuthSuccess);
        await withClock(
          Clock.fixed(start.add(const Duration(seconds: 1))),
          authService.validateSession,
        );

        expect(calls, 2);
      });

      test('handleFailedCall validates only after a 401', () async {
        final client = buildOfflineTestClient(
          InMemoryAuthSuccessStorage(sampleAuthSuccess),
        );
        var calls = 0;
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          fetchAccountEmail: () async => null,
          validateAuthentication: () async {
            calls++;
            return true;
          },
        );
        await authService.initialize();

        authService.handleFailedCall(ServerpodClientForbidden());
        await pumpEventQueue();
        expect(calls, 0);

        authService.handleFailedCall(ServerpodClientUnauthorized());
        await pumpEventQueue();
        expect(calls, 1);
      });
    });

    group('onAppResumed', () {
      late InMemoryAuthSuccessStorage storage;
      late Client client;
      late InMemorySessionQueueStorage queueStorage;
      late OfflineSessionQueue queue;
      late int validations;

      Future<AuthService> signedInService({
        Future<String?> Function()? fetchAccountEmail,
      }) async {
        storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        client = buildOfflineTestClient(storage);
        queueStorage = InMemorySessionQueueStorage();
        queue = OfflineSessionQueue(storage: queueStorage);
        await queue.enqueue(_queuedLog());
        validations = 0;
        final authService = AuthService(
          client: client,
          anonymousEndpoint: FakeEndpointAnonymousIdp(),
          fetchAccountEmail: fetchAccountEmail ?? () async => null,
          offlineQueue: queue,
          validateAuthentication: () async {
            validations++;
            return true;
          },
        );
        await authService.initialize();
        return authService;
      }

      test(
        'given another tab signed the shared session out, signs out at once without a server check',
        () async {
          final authService = await signedInService();

          await storage.set(null); // the other tab signed out
          await authService.onAppResumed();
          await pumpEventQueue();

          expect(authService.isAuthenticated, isFalse);
          expect(authService.account.value, AccountInfo.signedOut);
          expect(await queueStorage.read(), isEmpty);
          expect(validations, 0);
        },
      );

      test(
        'given another tab switched to another user, follows it and drops the old queue',
        () async {
          final authService = await signedInService();

          await storage.set(otherAuthSuccess);
          await authService.onAppResumed();
          await pumpEventQueue();

          expect(authService.currentUserId, otherUserId.uuid);
          expect(queue.pendingCount, 0);
          expect(await queueStorage.read(), isEmpty);
          expect(validations, 0);
        },
      );

      test('given an unchanged session, keeps it and the queue', () async {
        final authService = await signedInService();

        await authService.onAppResumed();
        await pumpEventQueue();

        expect(authService.currentUserId, testUserId.uuid);
        expect(queue.pendingCount, 1);
        expect(validations, 0);
      });

      test('retries a failed account lookup', () async {
        var fail = true;
        final authService = await signedInService(
          fetchAccountEmail: () async {
            if (fail) throw Exception('offline');
            return 'judge@example.com';
          },
        );
        await pumpEventQueue();
        expect(authService.account.value, AccountInfo.unknown);

        fail = false;
        await authService.onAppResumed();
        await pumpEventQueue();

        expect(
          authService.account.value,
          const AccountInfo.email('judge@example.com'),
        );
      });
    });
  });
}
