---
title: 'Story 1.1: Anonymous Guest Authentication & Token Rehydration'
type: 'feature'
created: '2026-10-02'
status: 'done'
baseline_commit: 'a20c0d467549bb0d8731748618edc4e92531cf18'
route: 'dispatch'
review_loop_iteration: 0
context:
  - 'AGENTS.md'
  - '_bmad-output/implementation-artifacts/epic-1-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Tennis players and hackathon judges expect instant access to the app without mandatory login walls or OAuth prompts, while downstream multi-tenant endpoints require a valid authenticated `authUserId` to isolate gear bags.

**Approach:** Configure Serverpod's built-in `AnonymousIdpConfig` on the server and expose `AnonymousIdpEndpoint`, wire the Flutter client's `FlutterAuthSessionManager` with secure storage to automatically authenticate as an anonymous guest on first launch, rehydrate the session silently on relaunch, and expose a stubbed account linking option in a Settings screen.

## Boundaries & Constraints

**Always:**
- Use Serverpod 4.0.3 built-in auth module (`serverpod_auth_idp_server` and `serverpod_auth_idp_flutter`).
- Authenticate silently on first boot if no existing session is present, storing the token via `FlutterAuthSessionManager` (using `SecureClientAuthSuccessStorage`).
- On app relaunch, silently rehydrate the existing session without network blocking if the token is valid.
- Maintain multi-tenant row security by ensuring `session.authenticated?.authUserId` is valid for authenticated requests.
- Provide a stubbed `[Link Google / Email]` dialog/sheet in Settings to satisfy FR-2 without data loss.

**Never:**
- Never block app launch with a mandatory login screen or OAuth modal.
- Never edit generated code in `string_theory_client` or `lib/src/generated/`.
- Never store raw authentication credentials in plain unencrypted SharedPreferences.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| First Launch (Fresh Install) | No token in secure storage | Server creates anonymous `AuthUser`, returns `AuthSuccess`; client stores session and enters authenticated state | Display retry snackbar if offline on very first launch |
| App Relaunch (Rehydration) | Valid token in secure storage | `client.auth.initialize()` restores session without network call; `client.auth.isAuthenticated` becomes true | If token is expired/invalid, automatically trigger fresh anonymous login |
| Check Auth State | Client queries `client.auth.isAuthenticated` | Returns `true`; `session.authenticated.authUserId` is accessible | If false, trigger auth initialization |
| Account Upgrade Stub (FR-2) | User taps `[Link Google / Email]` in Settings | Opens dialog explaining account linking to preserve racquet data when Google/Email auth is connected | Displays informative preview confirmation |

</frozen-after-approval>

## Code Map

- `string_theory_server/lib/server.dart` -- Add `AnonymousIdpConfig()` to `identityProviderBuilders` in `pod.initializeAuthServices()`.
- `string_theory_server/lib/src/auth/anonymous_idp_endpoint.dart` -- New endpoint extending `AnonymousIdpBaseEndpoint` to expose anonymous login RPC to client.
- `string_theory_server/test/integration/anonymous_auth_endpoint_test.dart` -- Integration test verifying anonymous login returns valid session and user ID.
- `string_theory_flutter/lib/client.dart` -- Ensure `initializeClient()` sets up `FlutterAuthSessionManager` and triggers auth initialization.
- `string_theory_flutter/lib/services/auth_service.dart` -- Service wrapping anonymous login, silent rehydration, and session state stream.
- `string_theory_flutter/lib/screens/settings_screen.dart` -- Settings UI displaying guest user identifier and stubbed `[Link Google / Email]` upgrade flow.
- `string_theory_flutter/lib/main.dart` -- Update entry flow to listen to `client.auth` and provide navigation to Settings.
- `string_theory_flutter/test/auth_service_test.dart` -- Unit tests for guest login and rehydration logic.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_server/lib/src/auth/anonymous_idp_endpoint.dart` -- Create endpoint subclassing `AnonymousIdpBaseEndpoint` -- Exposes anonymous login to client.
- [x] `string_theory_server/lib/server.dart` -- Add `AnonymousIdpConfig()` to `identityProviderBuilders` -- Enables anonymous auth service on Serverpod.
- [x] `string_theory_server/test/integration/anonymous_auth_endpoint_test.dart` -- Add server integration test for anonymous auth -- Verifies Serverpod authenticates anonymous users via TDD.
- [x] `string_theory_flutter/lib/services/auth_service.dart` -- Implement `AuthService` with automatic guest onboarding and rehydration check -- Encapsulates auth flow cleanly for UI and BLoCs.
- [x] `string_theory_flutter/lib/screens/settings_screen.dart` -- Create Settings screen with Guest ID card and `[Link Google / Email]` button -- Fulfills FR-2 requirement stub.
- [x] `string_theory_flutter/lib/main.dart` -- Wire `AuthService` into app startup and add Settings button in AppBar -- Provides user-facing access to auth status.
- [x] `string_theory_flutter/test/auth_service_test.dart` -- Add unit/widget tests for guest authentication flow -- Ensures regression prevention.

**Acceptance Criteria:**
- Given a user launches the app for the first time without credentials, when the app initializes, then the Serverpod backend creates an anonymous authenticated user session via `serverpod_auth_idp` and returns an auth token.
- Given an existing guest user closes and relaunches the app, when `initializeClient()` executes, then the session silently rehydrates without user friction.
- Given an authenticated guest user navigates to the Settings screen, when they view the account card, then their guest status is shown with a functional `[Link Google / Email]` upgrade option.

## Implementation Notes

## Spec Change Log

## Review Triage Log

| Layer | Finding Claim | Verdict | Evidence / Action |
|-------|---------------|---------|-------------------|
| blind-hunter | `main.dart` lacks `await initializeClient()` | false | Disproven: `main.dart:10` explicitly calls `await initializeClient();` before `runApp`. |
| blind-hunter | `serverpod_test_tools.dart` corrupted in diff | false | Disproven: Diff artifact was generated by shell `git status` concat, file is untouched and valid. |
| blind-hunter | Settings refresh/sign-out lack confirmation dialogs | medium | Patched: Added `_confirmReauthenticate` and `_confirmSignOut` confirmation dialogs with explanation. |
| blind-hunter | `AuthService.initialize()` does not verify token validity against server | low | Rejected: Standard Serverpod token management locally evaluates JWT validity; network verification occurs on RPC endpoints. |
| blind-hunter | No network connectivity listener to retry guest provisioning | false | Out of scope for Story 1.1; real-time offline queue and reconnection sync is scheduled for Story 3.5. |
| blind-hunter | Model `userId: int` in AGENTS.md vs `UuidValue` in Serverpod 4.0.3 | defer | Deferred: Added item to deferred-work.md to align Story 1.2 models with `UuidValue`. |
| blind-hunter | `AuthService.loginAsGuest` does not pass optional token | low | Patched: Added optional `token` parameter forwarded to `_anonymousEndpoint.login(token: token)`. |
| blind-hunter | `setUpAll` in server test manually initializes auth services | false | In `serverpod_test`, tests boot Serverpod without running `server.dart:run()`; manual service init is required. |
| blind-hunter | Server integration test lacks multiple-call distinct identity check | low | Patched: Added test in `anonymous_auth_endpoint_test.dart` verifying distinct user IDs. |
| blind-hunter | Raw color hex values in `main.dart` and `settings_screen.dart` | defer | Deferred: Story 1.3 is dedicated to Court Midnight design system tokens and theme constants. |
| blind-hunter | Link Google/Email does not trigger real account linking | false | Intended design: Story 1.1 spec specifically requires a preview stub for FR-2. |
| edge-case-hunter | `main.dart` post-frame callback missing `mounted` guard | medium | Patched: Added `if (!mounted) return;` before evaluating auth state in `_MyHomePageState`. |
| edge-case-hunter | `_showLinkFeedback` missing `context.mounted` guard | low | Patched: Added `if (!context.mounted) return;` before presenting SnackBar. |
| edge-case-hunter | Concurrent `loginAsGuest` calls can spawn duplicate accounts | medium | Patched: Added in-flight future deduplication guard `_inFlightLogin` in `AuthService`. |
| verification-gap | Missing test for unauthenticated `MyHomePage` OFFLINE badge & retry | medium | Patched: Added test in `widget_test.dart` asserting OFFLINE badge, snackbar, and retry flow. |
| verification-gap | Missing tests tapping settings upgrade tiles & session controls | medium | Patched: Added tests in `settings_screen_test.dart` tapping tiles and confirming session buttons. |


## Design Notes

- In Serverpod 4.0.3, `serverpod_auth_idp_server` exposes `AnonymousIdpBaseEndpoint` with `login(Session session, {String? token})`.
- The Flutter client calls `client.anonymousIdp.login()`, returning `AuthSuccess`.
- Session persistence is handled by `await client.auth.updateSignedInUser(authSuccess);`, which delegates to `SecureClientAuthSuccessStorage` via `flutter_secure_storage`.
- On subsequent launches, `client.auth.initialize()` automatically reads the persisted token from secure storage and restores `client.auth.isAuthenticated` to true.

## Verification

**Commands:**
- `dart analyze` in `string_theory_server` -- expected: No issues found
- `dart analyze` in `string_theory_flutter` -- expected: No issues found
- `dart test` in `string_theory_server` -- expected: All integration tests pass
- `flutter test` in `string_theory_flutter` -- expected: All Flutter tests pass

**Manual checks (if no CLI):**
- Launch Flutter app on Chrome/macOS: verify guest session is created automatically.
- Refresh/restart: verify user is immediately recognized as authenticated without login UI.
- Open Settings screen: verify Guest ID is shown and `[Link Google / Email]` dialog is present.
