import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_client/string_theory_client.dart';

/// Auth storage kept in memory instead of the platform secure storage.
class InMemoryAuthSuccessStorage implements ClientAuthSuccessStorage {
  AuthSuccess? _stored;

  InMemoryAuthSuccessStorage([this._stored]);

  @override
  Future<AuthSuccess?> get() async => _stored;

  @override
  Future<void> set(AuthSuccess? data) async => _stored = data;
}

/// Anonymous login endpoint returning [authSuccess], or throwing [error].
class FakeEndpointAnonymousIdp implements EndpointAnonymousIdp {
  AuthSuccess authSuccess;
  Object? error;
  int loginCalls = 0;

  FakeEndpointAnonymousIdp({AuthSuccess? authSuccess})
    : authSuccess = authSuccess ?? testAuthSuccess(guestUserId);

  @override
  Future<AuthSuccess> login({String? token}) async {
    loginCalls++;
    final failure = error;
    if (failure != null) throw failure;
    return authSuccess;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final guestUserId = UuidValue.fromString(
  '99999999-9999-9999-9999-999999999999',
);

final emailUserId = UuidValue.fromString(
  'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
);

AuthSuccess testAuthSuccess(UuidValue userId) => AuthSuccess(
  authStrategy: 'session',
  token: 'test-token-$userId',
  authUserId: userId,
  scopeNames: {},
);

/// A client on a closed local port, so every call fails fast with a
/// connection error instead of reaching a dev server on :8080.
Client buildOfflineTestClient(ClientAuthSuccessStorage storage) {
  final client = Client('http://127.0.0.1:1/')
    ..authSessionManager = FlutterAuthSessionManager(storage: storage);
  addTearDown(client.close);
  return client;
}
