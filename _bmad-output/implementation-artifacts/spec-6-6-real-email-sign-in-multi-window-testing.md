---
title: 'Story 6.6: Real Email Sign-In for Multi-Window Testing'
type: 'feature'
created: '2026-10-13'
baseline_commit: '68cb1039a448febb698a23c7abefa97486ba6b63'
status: 'done'
route: 'dispatch'
review_loop_iteration: 1
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-6-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The app silently becomes an anonymous guest at launch and has no real sign-in, sign-out or email account. Reviewers therefore can't open one account in two windows to watch live sync, or use a second account to check tenant isolation. The Settings auth UI is fake (Google/Email preview SnackBars), and the "Sign Out" button doesn't leave the bag.

**Approach:** Add an auth gate. With no stored session the app shows a Court Midnight sign-in screen with email sign-in/sign-up (Serverpod `EmailIdp`, including the verification code) and `[Continue as guest]`. A stored session opens the bag directly. Make sign-out real: it clears the token, the bag state and the stream, and returns to sign-in. Show the account email in Settings for email users. Add `tool/init_passwords.sh` for fresh clones. Record how two tabs behave by running them, and rewrite the README and DEMO_SCRIPT from what shipped. Scope is AC-1–5, 9–13 of epics.md Story 6.6. Guest→email linking (AC-6–8) is deferred to Story 6.7 (see deferred-work.md).

## Boundaries & Constraints

**Always:**
- A stored valid session skips sign-in (NFR-3 cold start). `continueAsGuest` keeps the existing in-flight dedupe.
- Sign-out (guest or email): `client.auth.signOutDevice()` (it clears local auth even offline). The BagBloc is closed, so its stream subscription is cancelled. The offline session queue is cleared, because it isn't keyed by user. Any pushed routes are dropped and the sign-in screen shows. The next sign-in gets a fresh BagBloc with `LoadBag`.
- The guest sign-out dialog warns that the guest bag becomes unreachable and can't be recovered.
- Settings for a guest shows the guest banner, saying the bag lives on this guest identity only. There is no link button. For an email user it shows the account email instead. The "Re-authenticate Guest" tile, the Google option and the link dialog are removed. The AppBar GUEST badge shows only for guests.
- The 6.1 401 "Sign in" action signs out locally and lands on the sign-in screen. It never creates a new guest and never queues offline.
- Decision (2026-10-14, after the live check): tabs of one browser profile share the identity (verified). A JWT access token stays valid for up to 10 minutes after a sign-out elsewhere, so a stale tab re-reads the shared stored session (local, no network, no token rotation) whenever the app regains focus: if another tab signed out or switched user, this tab follows immediately. After any 401 it runs a server check (forced refresh plus `status.isSignedIn`), deduped and throttled. A revoked session signs out locally and lands on sign-in, and network failures keep the session. Amended 2026-10-14 after review: forcing a refresh on every focus risked the server revoking a session reused by two tabs. Any change away from a signed-in identity clears the offline queue.
- The README and DEMO_SCRIPT describe only verified behavior. The AC-11 tab-sharing result is observed in a running browser, not assumed.
- TDD red first. Server tests use the embedded DB with fixed UUID tenants.

**Never:**
- Ship no linking endpoints, no `GuestClaim` table and no fake auth buttons.
- Don't edit generated code, and don't change CI env vars in `tests.yml`.
- `init_passwords.sh` never overwrites an existing `config/passwords.yaml`, and never prints secrets.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Cold start, no session | empty auth storage | Sign-in screen; no bag, no guest created | N/A |
| Cold start, stored session | valid token | Bag opens directly | N/A |
| Continue as guest offline | `anonymousIdp.login` throws | Stays on sign-in, inline error + Retry | Old post-launch SnackBar removed |
| Double-tap guest | 2 concurrent taps | One anonymous account | In-flight dedupe |
| Fresh email sign-up | register → code → password | Empty bag; Settings shows the email | Widget shows code/password errors |
| Sign out | confirm in Settings | Sign-in screen; bag state, stream and queue gone | Offline: still signs out locally |
| Signed out in another tab | stale tab regains focus | Stored session re-read; gone → sign-in screen at once | Local only, never rotates tokens |
| Session revoked server-side | a call gets 401 | Server check; revoked → sign-in screen | Offline/timeout: stays signed in; deduped and throttled |
| `getAccountEmail` | email user / guest / no auth | email / `null` / rejected | Client treats a failure as unknown: no GUEST badge, generic account text |

</frozen-after-approval>

## Code Map

- `string_theory_server/lib/src/endpoints/account_endpoint.dart` (new) -- `AccountEndpoint` (`requireLogin`), `getAccountEmail()` → `String?` from `EmailAccount` by `authUserId`. Story 6.7 will add claim methods here.
- `string_theory_server/test/integration/` -- follow the existing `withServerpod` endpoint tests. Note: `test:` in passwords.yaml lacks `serviceSecret`.
- `string_theory_server/tool/init_passwords.sh` (new) -- match `verify_uuid_migration.sh`: bash, `set -euo pipefail`, `script_dir`. Random `development` + `test` values for `database`, `serviceSecret`, `emailSecretHashPepper`, `jwtHmacSha512PrivateKey`, `jwtRefreshTokenHashPepper` (`openssl rand`), refuses if the file exists. Note: `config/test.yaml` sets the test DB name/port only.
- `string_theory_flutter/lib/client.dart:28-38` -- builds the global `client` and `authService`; `initialize()` must no longer log in.
- `string_theory_flutter/lib/services/auth_service.dart` -- `initialize` (40-46) drops the auto-guest; `loginAsGuest` → `continueAsGuest` (keep `_inFlightLogin`). `signOut` (75) exists. Add a listenable account email, loaded after auth changes.
- `string_theory_flutter/lib/main.dart` -- `MyApp` creates the BagBloc above `MaterialApp` (36-44); the old guest SnackBar is in `initState` (74-106); the GUEST/OFFLINE badge is at 114-157. Gate on `authService.authInfoListenable`.
- `string_theory_flutter/lib/screens/sign_in_screen.dart` -- replace the template with the real screen. Use `EmailSignInWidget(client:, startScreen: EmailFlowScreen.login, onAuthenticated:, onError:)` from `serverpod_auth_idp_flutter` plus a `[Continue as guest]` button. Keys follow `static const keyXxx = Key('snake_case')`.
- `string_theory_flutter/lib/screens/greetings_screen.dart` -- delete (unused).
- `string_theory_flutter/lib/screens/settings_screen.dart` -- link dialog (38-120), Re-authenticate (121-179, 583), Sign Out (181-233, 617), banner (387-540).
- `string_theory_flutter/lib/screens/virtual_bag_screen.dart:330-348` -- `_reauthenticate` currently calls `loginAsGuest`.
- `string_theory_flutter/lib/services/offline_session_queue.dart` -- no clear API yet. `SessionQueueStorage.write([])` is the primitive.
- Tests: `test/auth_service_test.dart` (65-128 auto-guest), `test/settings_screen_test.dart`, `test/widget_test.dart` (55-135), `test/virtual_bag_screen_test.dart:1528-1611`. `test/patrol/app_patrol_test.dart` pumps `VirtualBagScreen` with mocks, so it's unaffected.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_server/test/.../account_endpoint_test.dart` → `lib/src/endpoints/account_endpoint.dart` -- red then green: email, guest null, unauthenticated rejected. Generate the client; no migration.
- [x] `string_theory_server/tool/init_passwords.sh` -- create, `chmod +x`. Verify on a temp copy (refuse plus a fresh write) without touching the real file.
- [x] `string_theory_flutter/test/auth_service_test.dart` → `lib/services/auth_service.dart`, `lib/client.dart` -- no auto-guest, `continueAsGuest` dedupe, signOut, account email.
- [x] `string_theory_flutter/lib/services/offline_session_queue.dart` -- add `clear()` plus a unit test.
- [x] `string_theory_flutter/test/` gate + sign-in widget tests → `lib/main.dart`, `lib/screens/sign_in_screen.dart` -- gate; per-identity BagBloc; guest error/retry; remove the old SnackBar and the OFFLINE badge branch; delete `greetings_screen.dart`.
- [x] `string_theory_flutter/test/settings_screen_test.dart` → `lib/screens/settings_screen.dart` -- the Always rules for Settings, plus the guest warning dialog.
- [x] `string_theory_flutter/lib/screens/virtual_bag_screen.dart` + its test -- the 401 action signs out locally.
- [x] `string_theory_flutter/test/widget_test.dart` -- update for the sign-in-first launch.
- [x] Run the app on web: verify AC-11 (two tabs) and AC-12 (two windows on one account sync live; a second account in a private window is empty and isolated).
- [x] `README.md`, `docs/DEMO_SCRIPT.md` -- "Start" uses `init_passwords.sh`. Rewrite "Test it (for reviewers)" covering verification code from `serverpod start` output, two-window sync, second account in a private window, and the tab result; remove the 🚧 note. DEMO Step 1 shows the sign-in screen and guest path, and add a Sessions beat plus a two-window beat within ~90 s, or honestly update the header.

**Acceptance Criteria:**
- Given one email account in two windows, when a session is logged in A, then B's gauge updates without reload. A second email account sees an empty bag and gets no updates.
- Given two tabs of one profile, when tested, then the shared or separate identity result is in the README. If they share an identity, signing out in one tab sends the other to sign-in on its next authenticated call.
- Given the repo, then no code references `greetings_screen.dart`, the Google option or "Re-authenticate Guest".

## Implementation Notes

- Commits `697b953..77f7477` (TDD red commits first). Server: `AccountEndpoint.getAccountEmail` plus tests (tenants `f` and `g`); no migration. Flutter: `AuthService.account` (`AccountKind` signedOut/unknown/guest/email); one app-wide `offlineSessionQueue` in `client.dart`, shared by `AuthService` and each `BagBloc`; gate in `main.dart` per Design Notes, with a `bagBlocFactory` test hook. `VirtualBagScreen.onReauthenticate` became `onSignInRequired`. `test/helpers/fake_auth.dart` added.
- `init_passwords.sh` writes through a temp file plus `ln`, so a file that appears meanwhile is never replaced. Checked on a temp path and on a fresh clone (server auth tests green on a new embedded test DB); the real `config/passwords.yaml` was not touched.
- Matrix audit: offline sign-out is covered by the `signOut` unit test, where the test client has no reachable server. The full EmailSignInWidget sign-up needs a live server, so it is covered by the browser check below.
- Reverted a `flutter build web` side effect that dropped `lib/generated_plugin_registrant.dart` from `string_theory_flutter/.gitignore`.
- Live check (2026-10-14): a scripted check with two clients on one guest session plus a second guest showed `sessionLogged` reaching the twin client within 3 s, and nothing reaching the other account (empty bag). After a sign-out, the twin client's JWT kept working: it stays valid for 10 minutes, and a rejected refresh doesn't sign the client out locally. The user decided to re-check the session on focus and after a 401 (frozen decision).
- Re-check: `AuthService.validateSession()` (in-flight dedupe, 10 s cooldown via `clock`, 5 s timeout, never throws) wraps `client.auth.validateAuthentication`. `handleFailedCall` is wired to `Client(onFailedCall:)`, and `MyHomePage` uses `AppLifecycleListener(onResume:)`. The non-null→null auth transition clears the offline queue. Commits `213fab6` (red) and `f03be2d` (green). A shared-storage script against the live server showed a forced refresh in one client doesn't strand the other (header mode re-reads storage before a refresh), and that validation signs out the stale client.
- Browser (verified by the user): tabs of one profile share the identity, and after a sign-out in tab 1, tab 2 lands on sign-in when focused. Email sign-up with the logged code works, the gauge updates live in a second window, and the private-window account is empty. README/DEMO second-window steps were corrected (same-profile windows are already signed in) in `9a9d18c`.
- Verified: `dart analyze` and format clean in both packages; `flutter test` 454 passed; server `dart test` 105 passed.

- Iteration 1 re-derivation: `f774a67` (red), `9ccbf07`, `0a55efe`. Focus calls `AuthService.onAppResumed()`, which runs `client.auth.restore()` (re-reads the shared storage, no network) and then `refreshAccount()` (R18). `validateSession()` now runs only from `handleFailedCall`, wired through the new `buildAppClient(url, {authSessionManager})` in `client.dart`; R1 tests it against a local HttpServer answering 401. Patches applied: R2 (cooldown-expiry test with `withClock`), R3 (Settings retry test), R4 (`_drain` stops when `_items` was replaced), R10 (warn unless `AccountKind.email`), R11–R13 (README/DEMO: 8-character code, password-reset code, app address is the `serverpod start` page, not `:8080`), R19 (`SIGNED OUT` label), R20 (clear the queue on any change away from a signed-in identity). Flutter 463 and server 105 tests pass; analyze and format are clean.

- Iteration 2 review patches (`c6bd77b` red, `ebc728f`): R30 (the 401 action reuses `SettingsScreen.confirmSignOut` unless the account is known to be email, with tests for the default path), R33 (`SignInScreen` re-reads the shared session on resume), R38 (DEMO Step 7 copy), R40 (same-user token-rotation test), R43 (`clear()` detaches the stopped drain; `sync()` only resets its own slot), R46 (cooldown reset per identity). Deferred: R37 (CI run of `init_passwords.sh`, Story 6.5). Final verification: Flutter 469 and server 105 tests pass; analyze and format are clean in both packages.

## Spec Change Log

- Iteration 1 (intent_gap, resolved by the human): reviewers found that the focus check forced a token refresh behind a 10 s cooldown. The cooldown made "as soon as you switch" untrue, and concurrent forced refreshes from two tabs sharing a refresh token can make the server revoke the session (verified: `RefreshTokenInvalidSecretServerException` revokes it). The frozen decision was amended so focus re-reads the shared stored session locally, and the forced server check runs only after a 401. Re-derive only the re-check code (`213fab6`, `f03be2d`). KEEP: the auth gate, the per-identity BagBloc, `AccountEndpoint`, `init_passwords.sh`, the sign-in screen and the Settings changes, all of which reviewers found sound.

## Review Triage Log

| ID | Source | Finding | Verdict | Evidence | Route |
|---|---|---|---|---|---|
| R1 | Verification Gap, Blind Hunter | `client.dart` `onFailedCall` wiring to `handleFailedCall` has no test | medium | Confirmed: no test builds a client with the hook; dropping it keeps every test green. | patch |
| R2 | Verification Gap | Cooldown expiry never tested (only the skip side) | low | Confirmed; the cooldown remains on the 401 path after the redesign. | patch (test) |
| R3 | Verification Gap | Settings `refreshAccount` retry untested | low | Confirmed: tests use always-fail or always-succeed lookups. | patch (test) |
| R4 | Verification Gap, Blind Hunter, Edge Case Hunter | `OfflineSessionQueue.clear()` doesn't stop an in-flight drain, which keeps sending old sessions | medium | Confirmed: `_drain` iterates its local `items` reference after `_items` is replaced. | patch |
| R5 | Verification Gap | A 401 on the `bagUpdates` stream bypasses `onFailedCall` | low | True (streaming errors take another path), but the focus check covers a stale tab and the fix adds stream error plumbing. | reject (low) |
| R6 | Verification Gap, Blind Hunter, Edge Case Hunter | 10 s cooldown skips the resume check, so README's 'as soon as you switch' is untrue | medium | Confirmed in `validateSession`. | intent_gap → resolved (local re-read on focus) |
| R7 | Blind Hunter, Edge Case Hunter | Forced refresh on every resume can race another tab's refresh and revoke the shared session | medium | Confirmed: the server revokes on an invalid rotating secret (`jwt.dart:241`). | intent_gap → resolved (grouped with R6) |
| R8 | Blind Hunter | Sign-out and expiry drop email users' unsynced sessions | low | Real, but the frozen Always rule chose to clear the queue; the fix would edit the spec. | reject (intended) |
| R9 | Blind Hunter | No warning when sign-out discards pending sessions | low | Rare (offline sessions pending at sign-out); the fix adds a branch and copy. | reject (low) |
| R10 | Blind Hunter, Edge Case Hunter | A guest whose account lookup failed (`unknown`) gets the email sign-out text, not the bag-loss warning | medium | Confirmed: `_newGuestUserId` is memory-only and the dialog checks `isGuest`. | patch |
| R11 | Blind Hunter | README code example `<123456>` is wrong; codes are 8 lower-case alphanumerics | low | Confirmed in the `ServerpodCloudEmailIdpConfig` doc. | patch (docs) |
| R12 | Blind Hunter | Password-reset code not documented | low | Confirmed: logged as `Password reset code for ...`. | patch (docs, one line) |
| R13 | Blind Hunter | README tells reviewers to open `http://localhost:8080`, which is the API, not the app | high | Confirmed: :8080 returns `OK`, :8082 'Flutter web app not built'; the app runs on a Flutter dev-server port (58011 here) in the default browser profile. The human used the window `serverpod start` opened. | patch (docs) |
| R14 | Blind Hunter | `init_passwords.sh` ignores existing setups and docker-compose passwords | false | docker-compose isn't used (embedded PG via `dataPath`); refusing an existing file is the specified behavior. | reject |
| R15 | Blind Hunter | No automated test drives EmailSignInWidget to a successful sign-in | low | True; the path was verified in the browser by the human, and a test needs a fake email endpoint on the client. | reject (low) |
| R16 | Blind Hunter | Sign-in errors show raw exception `toString()` in a SnackBar | false | `EmailAuthController` passes `onError` only `convertToUserFacingException` results, whose `toString()` is the friendly message (`UserFacingException.toString() => message`). | reject |
| R17 | Blind Hunter | Template greeting endpoint left on the server | low | Pre-existing template code; AC-13 covers the Flutter screens. | defer |
| R18 | Blind Hunter | GUEST badge stays hidden after a failed launch lookup until Settings is opened | low | Confirmed; fixed by calling `refreshAccount` from the new focus hook. | patch |
| R19 | Blind Hunter | Unreachable `signedOut` card branch labelled OFFLINE | low | Confirmed; a direct label fix. | patch |
| R20 | Edge Case Hunter | An X→Y identity switch without passing through null keeps X's offline queue | medium | Reachable: a shared tab re-reads Y's session, or a refresh picks up Y's stored token. | patch |
| R21 | Edge Case Hunter | Email sign-in finishing during a guest request in flight is overwritten by the guest | low | Needs completing an email login within the guest round trip; the fix adds a guard. | reject (low) |
| R22 | Edge Case Hunter | Side-by-side windows without a focus change keep the signed-out account | false | Matches the human's decision (focus or 401); README says 'when you switch to it'. | reject |
| R23 | Blind Hunter (iter 2) | Email sign-in errors show raw exception text | false | carried R16: `onError` only receives `UserFacingException`/`InvalidEmailException`, whose `toString()` is the friendly message. | reject |
| R24 | Blind Hunter (iter 2) | Template GreetingEndpoint still exposed | low | carried R17. | defer (already logged) |
| R25 | Blind Hunter (iter 2) | Sign-out/identity change drops unsynced sessions without warning | low | carried R8/R9: the frozen Always rule clears the queue. | reject |
| R26 | Blind Hunter (iter 2) | No widget test drives an email sign-in to the bag; no Patrol two-window test | low | carried R15; verified in the browser by the human. | reject |
| R27 | Blind Hunter (iter 2) | `init_passwords.sh` doesn't warn about existing pgdata with an old password | false | carried R14. | reject |
| R28 | Edge Case Hunter (iter 2) | Unfocused tab keeps acting for the signed-out user until focus or 401 | false | carried R22: matches the human's decision. | reject |
| R29 | Blind Hunter (iter 2) | `signOut` ignores `signOutDevice()`'s false result (offline sign-out leaves the server session) | low | Real, but the token is gone locally, so the leftover server session is unreachable; the fix only adds reporting. | reject (low) |
| R30 | Blind Hunter, Edge Case Hunter, Verification Gap (iter 2) | The 401 'Sign in' action signs a guest out with no bag-loss warning, even when the 401 was transient; its production default is untested | medium | Confirmed: `_signInAgain` calls `authService.signOut` directly; every test injects `onSignInRequired`. | patch |
| R31 | Blind Hunter (iter 2) | `validateSession` force-refreshes a possibly stale refresh token without re-reading storage | false | Header mode calls `invalidateCachedAuthInfo` and re-reads storage before every refresh (`jwt_auth_key_provider.dart` `_HeaderJwtRefreshDelegate.refreshAuthKey`). | reject |
| R32 | Blind Hunter (iter 2) | Email user with an unknown account type sees the guest bag-loss warning | low | Real only when the lookup failed; R10 chose the safe side and hedged copy adds a branch. | reject (low) |
| R33 | Blind Hunter, Edge Case Hunter (iter 2) | Sign-in screen has no focus listener, so it doesn't follow a sign-in made in another tab; Continue as guest there overwrites the shared session | medium | Confirmed: `AppLifecycleListener` lives only in `_MyHomePageState`. | patch |
| R34 | Blind Hunter (iter 2) | Concurrent account lookups aren't deduplicated | low | Extra calls only; stale results are already ignored by identity. | reject (low) |
| R35 | Blind Hunter (iter 2) | Sign-out widget test checks the queue only via raw storage | low | Unit tests cover in-memory clearing. | reject (low) |
| R36 | Blind Hunter (iter 2) | `buildAppClient`'s hook hits the late global `authService` before assignment | false | `initializeClient` assigns `authService` before any call; other tests don't use `buildAppClient`. | reject |
| R37 | Blind Hunter, Verification Gap (iter 2) | `init_passwords.sh` is not exercised by CI | medium | Confirmed (only run manually on a fresh clone); the fix belongs in CI, which Story 6.5 owns, and the spec forbids changing `tests.yml` env vars. | defer |
| R38 | Blind Hunter (iter 2) | DEMO Step 7 narration claims a second account that the demo never shows | low | Confirmed; a direct copy fix. | patch |
| R39 | Blind Hunter, Edge Case Hunter (iter 2) | `getAccountEmail` `findFirstRow` is non-deterministic with several email accounts per user | low | Only reachable after account merging, which is deferred to 6.7. | reject (low) |
| R40 | Verification Gap (iter 2) | Same-user JWT rotation keeping the account, queue and BagBloc is untested | medium | Pre-verified gap; the guard in `_onAuthInfoChanged` and the `authUserId` BlocProvider key are untested. | patch (test) |
| R41 | Edge Case Hunter (iter 2) | Old identity's failing in-flight `logSession` enqueues after `clear()` | low | Needs a log in flight, a network failure and a sign-out together; the server rejects foreign racquets. | reject (low) |
| R42 | Edge Case Hunter (iter 2) | Tabs share queue storage, so another tab can persist X's sessions after a switch to Y | low | Rare offline multi-tab case; the server rejects foreign racquets. | reject (low) |
| R43 | Edge Case Hunter (iter 2) | After `clear()` during a drain, a new identity's `sync()` reuses the old in-flight drain | low | Confirmed; a direct one-line fix (`_syncInFlight = null`). | patch |
| R44 | Edge Case Hunter (iter 2) | A failing unawaited `clear()` raises an unhandled async error | low | Needs SharedPreferences write failure. | reject (low) |
| R45 | Edge Case Hunter (iter 2) | `dispose()` during a pending lookup writes to a disposed notifier | low | The app never disposes the global service. | reject (low) |
| R46 | Edge Case Hunter (iter 2) | New identity inherits the previous identity's validation cooldown | low | Confirmed; a direct one-line reset. | patch |
| R47 | Edge Case Hunter (iter 2) | openssl failure inside heredoc substitution writes empty secrets | low | `openssl rand` practically never fails once `command -v` passed. | reject (low) |

## Design Notes

Gate shape (keeps pushed routes able to `context.read<BagBloc>()`): `ValueListenableBuilder(authInfoListenable)`. When signed out → `MaterialApp(home: SignInScreen)`. When signed in → `BlocProvider(key: ValueKey(authUserId), create: BagBloc(...)..add(LoadBag()))` → `MaterialApp(home: MyHomePage)`. Swapping the subtree closes the old bloc and drops the navigator stack. An injected test `bagBloc` uses `BlocProvider.value`.

## Verification

**Commands:**
- `dart analyze` and `dart format --set-exit-if-changed .` in each package -- clean
- `dart test` in `string_theory_server`; `flutter test` in `string_theory_flutter` -- all green

**Manual checks:**
- Two browser windows/profiles against `serverpod start` (AC-11/12). The verification code appears in `tail_server_logs`.
