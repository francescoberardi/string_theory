import 'dart:async';

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

/// In-memory `serverpod_auth_core.status` endpoint, which the session
/// manager calls to validate a session (`initialize`,
/// `validateAuthentication`) and to sign out.
///
/// By default `isSignedIn` answers [signedIn]; it throws [isSignedInError]
/// when set, or never completes when [isSignedInHangs]. `signOutDevice`
/// throws [signOutError] when set.
class FakeAuthStatus implements EndpointStatus {
  bool signedIn;
  Object? isSignedInError;
  bool isSignedInHangs;
  Object? signOutError;
  int isSignedInCalls = 0;
  int signOutDeviceCalls = 0;

  FakeAuthStatus({
    this.signedIn = true,
    this.isSignedInError,
    this.isSignedInHangs = false,
    this.signOutError,
  });

  /// Every session check fails with a server error, so a stored session is
  /// kept, like a server that can't be reached.
  FakeAuthStatus.serverError()
    : this(isSignedInError: ServerpodClientInternalServerError());

  @override
  Future<bool> isSignedIn() async {
    isSignedInCalls++;
    if (isSignedInHangs) return Completer<bool>().future;
    final error = isSignedInError;
    if (error != null) throw error;
    return signedIn;
  }

  @override
  Future<void> signOutDevice() async {
    signOutDeviceCalls++;
    final error = signOutError;
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Auth core module caller whose `status` endpoint is a [FakeAuthStatus].
class FakeAuthCoreCaller extends Caller {
  final FakeAuthStatus _status;

  FakeAuthCoreCaller(super.client, this._status);

  @override
  EndpointStatus get status => _status;
}

/// A client whose auth session checks and sign-outs go to [status] (by
/// default [FakeAuthStatus.serverError]) instead of the network.
///
/// The URL is a closed local port, so a call that misses a fake fails fast
/// with a connection error instead of reaching a dev server on :8080.
Client buildOfflineTestClient(
  ClientAuthSuccessStorage storage, {
  FakeAuthStatus? status,
}) {
  final client = Client('http://127.0.0.1:1/')
    ..authSessionManager = FlutterAuthSessionManager(storage: storage);
  // The authSessionManager setter installs the real caller, so the fake
  // goes in afterwards.
  client.auth.setCaller(
    FakeAuthCoreCaller(client, status ?? FakeAuthStatus.serverError()),
  );
  addTearDown(client.close);
  return client;
}
