import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/services/auth_service.dart';
import 'package:string_theory_flutter/services/offline_session_queue.dart';

class InMemoryAuthSuccessStorage implements ClientAuthSuccessStorage {
  AuthSuccess? _stored;

  InMemoryAuthSuccessStorage([this._stored]);

  @override
  Future<AuthSuccess?> get() async => _stored;

  @override
  Future<void> set(AuthSuccess? data) async => _stored = data;
}

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

/// Builds a client against a closed local port so session validation in
/// `client.auth.initialize()` fails fast with a connection error (which keeps
/// the restored session) instead of reaching a dev server on :8080.
Client buildTestClient(ClientAuthSuccessStorage storage) {
  final client = Client('http://127.0.0.1:1/')
    ..authSessionManager = FlutterAuthSessionManager(storage: storage);
  addTearDown(client.close);
  return client;
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
        final client = buildTestClient(storage);
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

    test(
      'given stored session and unreachable server, when initialize() is called, then rehydrates without calling login',
      () async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = buildTestClient(storage);
        final fakeEndpoint = FakeEndpointAnonymousIdp();

        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
          fetchAccountEmail: () async => null,
        );

        final result = await authService.initialize();

        expect(result, isTrue);
        expect(fakeEndpoint.loginCalls, equals(0));
        expect(authService.isAuthenticated, isTrue);
        expect(authService.currentUserId, equals(testUserId.toString()));
      },
    );

    test(
      'given continueAsGuest, when the anonymous login succeeds, then signs in as a guest',
      () async {
        final storage = InMemoryAuthSuccessStorage();
        final client = buildTestClient(storage);
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
        final client = buildTestClient(storage);
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
        final client = buildTestClient(storage);
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
        final client = buildTestClient(storage);
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
        final client = buildTestClient(storage);
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

    group('account', () {
      test('given a stored email session, loads the account email', () async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = buildTestClient(storage);
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
        final client = buildTestClient(storage);
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
          final client = buildTestClient(storage);
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
        final client = buildTestClient(storage);
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
        final client = buildTestClient(storage);
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
          final client = buildTestClient(storage);
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
        'given the server is unreachable, keeps the session (real validation path)',
        () async {
          final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
          final client = buildTestClient(storage);
          final authService = AuthService(
            client: client,
            anonymousEndpoint: FakeEndpointAnonymousIdp(),
            fetchAccountEmail: () async => null,
          );
          await authService.initialize();

          await authService.validateSession();

          expect(authService.isAuthenticated, isTrue);
          expect(await storage.get(), isNotNull);
        },
      );

      test('given no session, does not validate', () async {
        final client = buildTestClient(InMemoryAuthSuccessStorage());
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
        final client = buildTestClient(
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
        final client = buildTestClient(
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

      test('handleFailedCall validates only after a 401', () async {
        final client = buildTestClient(
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
  });
}
