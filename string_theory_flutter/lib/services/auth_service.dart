import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:string_theory_client/string_theory_client.dart';

import 'offline_session_queue.dart';

/// What the app knows about the signed-in account.
enum AccountKind {
  /// Nobody is signed in.
  signedOut,

  /// Signed in, but the account type is not known (yet): the email lookup is
  /// pending or failed.
  unknown,

  /// An anonymous guest account.
  guest,

  /// An email account; see [AccountInfo.email].
  email,
}

/// The signed-in account, as shown in the AppBar badge and in Settings.
@immutable
class AccountInfo {
  final AccountKind kind;

  /// The account email, for [AccountKind.email] only.
  final String? email;

  const AccountInfo._(this.kind) : email = null;

  /// An email account signed in as [email].
  const AccountInfo.email(String this.email) : kind = AccountKind.email;

  static const signedOut = AccountInfo._(AccountKind.signedOut);
  static const unknown = AccountInfo._(AccountKind.unknown);
  static const guest = AccountInfo._(AccountKind.guest);

  bool get isGuest => kind == AccountKind.guest;

  @override
  bool operator ==(Object other) =>
      other is AccountInfo && other.kind == kind && other.email == email;

  @override
  int get hashCode => Object.hash(kind, email);

  @override
  String toString() => 'AccountInfo($kind${email == null ? '' : ', $email'})';
}

/// Signs users in and out and tracks the signed-in account.
///
/// Nothing signs in automatically: with no stored session the app shows the
/// sign-in screen, where the user picks email or [continueAsGuest].
class AuthService {
  final Client _client;
  final EndpointAnonymousIdp? _anonymousEndpointOverride;
  final Future<String?> Function()? _fetchAccountEmailOverride;
  final OfflineSessionQueue? _offlineQueue;

  final _account = ValueNotifier<AccountInfo>(AccountInfo.signedOut);
  Future<bool>? _inFlightLogin;

  /// Auth user the [account] value belongs to.
  UuidValue? _accountUserId;

  /// Auth user just created by [continueAsGuest], known to be a guest.
  UuidValue? _newGuestUserId;

  /// [offlineQueue] is cleared on [signOut]. [fetchAccountEmail] overrides
  /// `client.account.getAccountEmail` (for tests).
  AuthService({
    required this._client,
    EndpointAnonymousIdp? anonymousEndpoint,
    Future<String?> Function()? fetchAccountEmail,
    this._offlineQueue,
  }) : _anonymousEndpointOverride = anonymousEndpoint,
       _fetchAccountEmailOverride = fetchAccountEmail {
    _client.auth.authInfoListenable.addListener(_onAuthInfoChanged);
    _onAuthInfoChanged();
  }

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

  /// The signed-in account; reloaded whenever the signed-in identity changes.
  ValueListenable<AccountInfo> get account => _account;

  /// Restores a stored session, if any, without creating one.
  ///
  /// Returns whether a user is signed in afterwards.
  Future<bool> initialize() async {
    await _client.auth.initialize();
    return isAuthenticated;
  }

  /// Signs in as a new anonymous guest and persists the session.
  ///
  /// Concurrent calls share the request in flight, so a double tap creates
  /// one guest. Errors (e.g. offline) are propagated.
  Future<bool> continueAsGuest({String? token}) {
    return _inFlightLogin ??= _performContinueAsGuest(
      token: token,
    ).whenComplete(() => _inFlightLogin = null);
  }

  Future<bool> _performContinueAsGuest({String? token}) async {
    final authSuccess = await _anonymousEndpoint.login(token: token);
    _newGuestUserId = authSuccess.authUserId;
    await _client.auth.updateSignedInUser(authSuccess);
    return isAuthenticated;
  }

  /// Signs out this device and clears the offline session queue.
  ///
  /// The local session is cleared even when the server can't be reached.
  Future<void> signOut() async {
    try {
      await _client.auth.signOutDevice();
    } finally {
      await _offlineQueue?.clear();
    }
  }

  /// Reloads the account email if the account type is [AccountKind.unknown].
  Future<void> refreshAccount() async {
    final userId = _client.auth.authInfo?.authUserId;
    if (userId == null || _account.value.kind != AccountKind.unknown) return;
    await _loadAccount(userId);
  }

  /// Stops tracking auth changes.
  void dispose() {
    _client.auth.authInfoListenable.removeListener(_onAuthInfoChanged);
    _account.dispose();
  }

  void _onAuthInfoChanged() {
    final userId = _client.auth.authInfo?.authUserId;
    // A token refresh keeps the identity, and so the account.
    if (userId == _accountUserId) return;
    _accountUserId = userId;
    if (userId == null) {
      _account.value = AccountInfo.signedOut;
    } else if (userId == _newGuestUserId) {
      _account.value = AccountInfo.guest;
    } else {
      _account.value = AccountInfo.unknown;
      unawaited(_loadAccount(userId));
    }
  }

  Future<void> _loadAccount(UuidValue userId) async {
    final AccountInfo loaded;
    try {
      final fetch =
          _fetchAccountEmailOverride ?? _client.account.getAccountEmail;
      final email = await fetch();
      loaded = email == null ? AccountInfo.guest : AccountInfo.email(email);
    } catch (e) {
      debugPrint('AuthService: account email lookup failed: $e');
      return;
    }
    // Ignore a lookup that finished after the identity changed.
    if (_accountUserId != userId) return;
    _account.value = loaded;
  }
}
