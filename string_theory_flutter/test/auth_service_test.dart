import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_flutter/services/auth_service.dart';

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
  int loginCalls = 0;

  @override
  Future<AuthSuccess> login({String? token}) async {
    loginCalls++;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return successToReturn!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthService', () {
    final testUserId = UuidValue.fromString(
      '11111111-2222-3333-4444-555555555555',
    );
    final sampleAuthSuccess = AuthSuccess(
      authStrategy: 'session',
      token: 'test-token',
      authUserId: testUserId,
      scopeNames: {},
    );

    test(
      'given fresh install (no session), when initialize() is called, then logs in anonymously',
      () async {
        final storage = InMemoryAuthSuccessStorage();
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final fakeEndpoint = FakeEndpointAnonymousIdp()
          ..successToReturn = sampleAuthSuccess;

        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
        );

        expect(authService.isAuthenticated, isFalse);

        final result = await authService.initialize();

        expect(result, isTrue);
        expect(fakeEndpoint.loginCalls, equals(1));
        expect(authService.isAuthenticated, isTrue);
        expect(authService.currentUserId, equals(testUserId.toString()));
        expect(await storage.get(), equals(sampleAuthSuccess));
      },
    );

    test(
      'given existing valid session, when initialize() is called, then rehydrates without calling login',
      () async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final fakeEndpoint = FakeEndpointAnonymousIdp();

        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
        );

        final result = await authService.initialize();

        expect(result, isTrue);
        expect(fakeEndpoint.loginCalls, equals(0));
        expect(authService.isAuthenticated, isTrue);
        expect(authService.currentUserId, equals(testUserId.toString()));
      },
    );

    test(
      'given fresh install and network failure, when initialize() is called, then error is propagated',
      () async {
        final storage = InMemoryAuthSuccessStorage();
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final fakeEndpoint = FakeEndpointAnonymousIdp()
          ..exceptionToThrow = Exception(
            'Network error connecting to Serverpod',
          );

        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
        );

        expect(authService.initialize(), throwsA(isA<Exception>()));
      },
    );

    test(
      'given authenticated user, when signOut() is called, then session is cleared',
      () async {
        final storage = InMemoryAuthSuccessStorage(sampleAuthSuccess);
        final client = Client('http://localhost:8080/')
          ..authSessionManager = FlutterAuthSessionManager(storage: storage);
        final fakeEndpoint = FakeEndpointAnonymousIdp();

        final authService = AuthService(
          client: client,
          anonymousEndpoint: fakeEndpoint,
        );
        await authService.initialize();
        expect(authService.isAuthenticated, isTrue);

        await authService.signOut();

        expect(authService.isAuthenticated, isFalse);
        expect(authService.currentUserId, isNull);
        expect(await storage.get(), isNull);
      },
    );
  });
}
