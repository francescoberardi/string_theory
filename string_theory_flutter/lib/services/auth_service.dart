import 'dart:async';

import 'package:clock/clock.dart';
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
  final Future<bool> Function()? _validateAuthenticationOverride;

  /// Minimum time between two session checks in [validateSession].
  static const validationCooldown = Duration(seconds: 10);

  /// How long a session check may wait for the server.
  static const validationTimeout = Duration(seconds: 5);

  final _account = ValueNotifier<AccountInfo>(AccountInfo.signedOut);
  Future<bool>? _inFlightLogin;
  Future<void>? _inFlightValidation;
  DateTime? _lastValidation;

  /// Auth user the [account] value belongs to.
  UuidValue? _accountUserId;

  /// Auth user just created by [continueAsGuest], known to be a guest.
  UuidValue? _newGuestUserId;

  /// [offlineQueue] is cleared whenever the user ends up signed out.
  /// [fetchAccountEmail] and [validateAuthentication] override
  /// `client.account.getAccountEmail` and `client.auth.validateAuthentication`
  /// (for tests).
  AuthService({
    required this._client,
    EndpointAnonymousIdp? anonymousEndpoint,
    Future<String?> Function()? fetchAccountEmail,
    this._offlineQueue,
    Future<bool> Function()? validateAuthentication,
  }) : _anonymousEndpointOverride = anonymousEndpoint,
       _fetchAccountEmailOverride = fetchAccountEmail,
       _validateAuthenticationOverride = validateAuthentication {
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

  /// Called when the app regains focus: re-reads the stored session, which
  /// other tabs of the same browser profile share. If another tab signed out
  /// or switched user, this one follows at once. Local only: it never
  /// rotates tokens. Also retries a failed account lookup.
  Future<void> onAppResumed() async {
    try {
      await _client.auth.restore();
    } catch (e) {
      debugPrint('AuthService: session re-read failed: $e');
    }
    await refreshAccount();
  }

  /// Re-checks the session with the server (forced refresh plus
  /// `status.isSignedIn`) and signs out locally when it was revoked. Runs
  /// after a 401: a tab's JWT access token keeps working for a while after
  /// its session is revoked.
  ///
  /// Checks in flight are shared and repeat checks within
  /// [validationCooldown] are skipped. Network failures and timeouts keep the
  /// session; this never throws.
  Future<void> validateSession() {
    if (!isAuthenticated) return Future.value();
    final inFlight = _inFlightValidation;
    if (inFlight != null) return inFlight;
    final now = clock.now();
    final last = _lastValidation;
    if (last != null && now.difference(last) < validationCooldown) {
      return Future.value();
    }
    _lastValidation = now;
    return _inFlightValidation = _validate().whenComplete(
      () => _inFlightValidation = null,
    );
  }

  Future<void> _validate() async {
    try {
      final validate =
          _validateAuthenticationOverride ??
          () => _client.auth.validateAuthentication(timeout: validationTimeout);
      await validate();
    } catch (e) {
      debugPrint('AuthService: session check failed, keeping session: $e');
    }
  }

  /// Hook for the client's `onFailedCall`: a 401 means the session may have
  /// been revoked, so it is re-checked (see [validateSession]).
  void handleFailedCall(Object error) {
    if (error is ServerpodClientUnauthorized) unawaited(validateSession());
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
    final wasSignedIn = _accountUserId != null;
    _accountUserId = userId;
    // Queued sessions are not keyed by user: drop them whenever the signed-in
    // identity goes away, whether to signed-out or to another user.
    if (wasSignedIn) unawaited(_offlineQueue?.clear());
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
