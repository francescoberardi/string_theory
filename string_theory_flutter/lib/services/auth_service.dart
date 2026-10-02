import 'package:flutter/foundation.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../client.dart' as app_client;

/// Service managing guest authentication, session rehydration, and auth state.
class AuthService {
  final Client? _clientOverride;
  final EndpointAnonymousIdp? _anonymousEndpointOverride;

  AuthService({
    Client? client,
    EndpointAnonymousIdp? anonymousEndpoint,
  }) : _clientOverride = client,
       _anonymousEndpointOverride = anonymousEndpoint;

  Client get _client => _clientOverride ?? app_client.client;
  EndpointAnonymousIdp get _anonymousEndpoint =>
      _anonymousEndpointOverride ?? _client.anonymousIdp;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => _client.auth.isAuthenticated;

  /// Current authentication details, or null if unauthenticated.
  AuthSuccess? get authInfo => _client.auth.authInfo;

  /// The current authenticated user's ID as a UUID string, or null.
  String? get currentUserId => _client.auth.authInfo?.authUserId.toString();

  /// Listenable for reactive UI updates when auth info changes.
  ValueListenable<AuthSuccess?> get authInfoListenable =>
      _client.auth.authInfoListenable;

  /// Initializes auth session on app startup:
  /// - Restores existing token silently from secure storage without network blocking.
  /// - If no token exists or if the session is invalid, automatically signs in as a guest.
  /// Returns whether the user is successfully authenticated.
  Future<bool> initialize() async {
    await _client.auth.initialize();
    if (!isAuthenticated) {
      await loginAsGuest();
    }
    return isAuthenticated;
  }

  /// Explicitly requests a new anonymous guest account and persists it to secure storage.
  Future<bool> loginAsGuest() async {
    try {
      final authSuccess = await _anonymousEndpoint.login();
      await _client.auth.updateSignedInUser(authSuccess);
      return isAuthenticated;
    } catch (e) {
      rethrow;
    }
  }

  /// Signs out the current device session.
  Future<void> signOut() async {
    await _client.auth.signOutDevice();
  }
}
