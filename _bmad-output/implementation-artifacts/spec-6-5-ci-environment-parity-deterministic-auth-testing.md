---
title: 'Story 6.5: CI Environment Parity & Deterministic Auth Testing'
type: 'chore'
created: '2026-10-14'
baseline_commit: '27fa80c606cff25c0dab8d986527f5179d2e0659'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-6-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** CI's server job hard-codes five `SERVERPOD_PASSWORD_*` values. The set has drifted from what a fresh clone gets from `tool/init_passwords.sh`: `redis` is unused and `serviceSecret` is missing. That script never runs in CI (deferred R37 from 6.6). Every Flutter auth test still opens a real socket to `127.0.0.1:1`, because `client.auth.initialize()` and `signOut()` call the `serverpod_auth_core.status` endpoint. That is fast on a laptop but can hang until the 2 s timeout on a runner that drops packets instead of refusing them.

**Approach:** Give CI one source for test secrets, the same one a fresh clone uses, and keep the generator drift check scoped to each package. Replace the status calls in the auth tests with an in-memory fake `serverpod_auth_core` `Caller`. Then the valid-session, revoked-session (falls back to sign-in, then guest), server-error and slow-server branches all run without touching the network.

## Boundaries & Constraints

**Decision (human, 2026-10-14):** the `server-tests` job generates `config/passwords.yaml` with `tool/init_passwords.sh` before `dart test`, and its hard-coded `SERVERPOD_PASSWORD_*` `env` block is deleted. That makes the script the single source of test secrets for CI and for a fresh clone.

**Always:** server tests keep using the embedded PostgreSQL from `config/test.yaml`. The drift check stays limited to `string_theory_server/lib/src/generated/` and `string_theory_client`. Production `AuthService` and `client.dart` behaviour is unchanged. TDD: commit the failing tests first (`test(...)`), then the green change.

**Never:** commit `config/passwords.yaml`; edit generated code; change the `migration-verify` job's Postgres service credentials (they belong to the Docker service, not Serverpod); add real-time waits (`Future.delayed` with real durations) to the auth tests.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Valid session | stored session; fake `isSignedIn` → true | `initialize()` returns true, user and account kept, no guest login | N/A |
| Revoked session | stored session; `isSignedIn` → false | fake `signOutDevice` called once, signed out, queue cleared, `account` = signedOut; a later `continueAsGuest` signs in a guest | N/A |
| Server error | `isSignedIn` throws `ServerpodClientException` | session kept, `initialize()` returns true | swallowed by `initialize` |
| Slow server | `isSignedIn` never completes | after the 2 s timeout (fake time), session kept | `TimeoutException` swallowed |
| Sign-out offline | `signOutDevice` throws | local session cleared anyway | finally path |

</frozen-after-approval>

## Code Map

- `.github/workflows/tests.yml` -- `server-tests` job: `env` (5 hard-coded secrets, incl. unused `redis`; no `serviceSecret`), drift step (already scoped: `git diff --exit-code lib/src/generated/ ../string_theory_client` + `git status --porcelain`, keep). Other jobs need no Serverpod secrets.
- `string_theory_server/tool/init_passwords.sh` -- writes `development` + `test` with database, serviceSecret, emailSecretHashPepper, jwtHmacSha512PrivateKey, jwtRefreshTokenHashPepper. Refuses an existing file; needs `openssl` (present on ubuntu-latest).
- `string_theory_server/lib/server.dart:14-32` -- `JwtConfigFromPasswords`, `ServerpodCloudEmailIdpConfig`, `AnonymousIdpConfig`: the consumers of those secrets.
- `serverpod_auth_core_client-4.0.3/lib/src/session_manager.dart` -- `initialize({timeout: 2s})` = `restore()` + `validateAuthentication`. For `authStrategy: 'session'` the refresh is skipped, then `caller.status.isSignedIn()`. False → `signOutDevice()` → `caller.status.signOutDevice()` + `updateSignedInUser(null)`. `ServerpodClientException`/`TimeoutException` → returns false and keeps the session. `updateSignedInUser` calls `_caller?.client.closeStreamingMethodConnections` (local).
- `serverpod_auth_core_flutter-4.0.3/lib/src/session_manager.dart` -- `set authSessionManager` calls `setCaller(getCaller())` and **overwrites** any caller passed to the constructor. Call `client.auth.setCaller(fake)` after assignment.
- `serverpod_auth_core_client` `Caller(client)` / `EndpointStatus(caller)` (`protocol/client.dart:23,126`) -- subclass `EndpointStatus` and override `isSignedIn`/`signOutDevice`; subclass `Caller` with `@override EndpointStatus get status`.
- `string_theory_flutter/test/helpers/fake_auth.dart` -- shared `InMemoryAuthSuccessStorage`, `buildOfflineTestClient` (127.0.0.1:1). Used by `settings_screen_test`, `widget_test`, `screens/sign_in_screen_test`.
- `string_theory_flutter/test/auth_service_test.dart` -- has its own duplicate `InMemoryAuthSuccessStorage` + `buildTestClient` (lines 10-57); keep its richer `FakeEndpointAnonymousIdp`. Existing `validateSession` tests use the `validateAuthentication:` override; keep them.
- `string_theory_flutter/test/client_test.dart` -- real loopback `HttpServer` for the `onFailedCall` wiring (R1); deterministic, leave as is.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` -- action items `epic-1-5-retro-item-1…`, `…-item-2…` → done.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_flutter/test/helpers/fake_auth.dart` -- add `FakeAuthStatus` (configurable `isSignedIn` result/error/never-completing, `signOutDevice` error, call counters) and `FakeAuthCoreCaller`. `buildOfflineTestClient` installs it, default "server error", so no helper user opens a socket. -- one fake for every auth test.
- [x] `string_theory_flutter/test/auth_service_test.dart` -- red first: the matrix rows (slow server via `fakeAsync`); drop the duplicate storage/client builder in favour of the helper. Add `fake_async` to `dev_dependencies` (already transitive). -- TD-14.
- [x] `.github/workflows/tests.yml` -- `server-tests`: delete the `env` secrets (keep `VERSION`), add a step running `./tool/init_passwords.sh` before the tests; keep the scoped drift step with a comment naming the scope rule. -- TD-13, R37.
- [x] `README.md` -- update the line-117 CI sentence only if what CI runs changes in a way it describes.
- [x] `sprint-status.yaml` -- close both Epic 1.5 retro action items when green.

**Acceptance Criteria:**
- Given the Flutter test suite, when it runs with networking disabled, then every test in `auth_service_test.dart`, `settings_screen_test.dart`, `widget_test.dart` and `sign_in_screen_test.dart` passes without opening a socket (no `127.0.0.1:1` connection attempt is reached).
- Given a push to `main`, when `tests.yml` runs, then `server-tests` gets its secrets from one source shared with the fresh-clone setup, and all jobs pass.

## Implementation Notes

- Commits: `973904f` (red: matrix tests, compile-fail on missing `FakeAuthStatus`), `6ec2d4c` (green: fake in `fake_auth.dart`), `5ee8002` (CI).
- `FakeAuthStatus` implements `EndpointStatus` (with `noSuchMethod`, like the existing `FakeEndpointAnonymousIdp`) instead of subclassing it, because `EndpointStatus` needs its caller at construction and the caller needs the status. `FakeAuthCoreCaller extends Caller` and overrides `status`.
- The shared helper's `FakeEndpointAnonymousIdp` collides with the richer one in `auth_service_test.dart`, so that file imports the helper with `hide FakeEndpointAnonymousIdp`.
- No-socket check: a temporary `HttpOverrides` tripwire around the helper's `Client` showed 0 requests from `auth_service_test.dart` (26 real `status/*` socket attempts with the fake disabled). The widget tests still send 8 `bag/getVirtualBag` requests, which the Flutter test binding's mock `HttpClient` answers with 400 without opening a socket; these are bag calls, not auth calls.
- README line 117 does not mention secrets, so it is unchanged.
- Review patches (R1, R7, R8, R11, R14) in `cfa1aeb`: real-path `validateSession` tests against the fake (check counted; revoked signs out and clears the queue), extra matrix assertions, the default fake renamed `FakeAuthStatus.unreachable()` (network exception), a faked `signOutAllDevices`, and a doc note that helper sessions must use the 'session' strategy. Final verification: Flutter 474 and server 105 tests pass; analyze and format are clean. Open: the first GitHub Actions run of the new `Generate test secrets` step (user confirms after pushing).

## Spec Change Log

## Review Triage Log

| ID | Source | Finding | Verdict | Evidence | Route |
|---|---|---|---|---|---|
| R1 | Verification Gap | The only real-path `validateSession` test holds no fake handle (it passes even if the check never runs); real-path revoked case untested | medium | Pre-verified: every other `validateSession` test injects `validateAuthentication:`; the 536 test asserts only that the session is kept. | patch (test) |
| R2 | Verification Gap | Root `pubspec.lock` still says `fake_async: transitive`; next `pub get` dirties it | false | Ran `flutter pub get`: the workspace lock is unchanged (it records types for the root workspace package). | reject |
| R3 | Blind Hunter | Epic 1.5 retro items marked done before CI ran on a runner | low | True that CI hasn't run; the CI run is the user's manual check at hand-off, before the story is marked done. Reopen them if it fails. | reject (low) |
| R4 | Blind Hunter | Spec `in-review` vs sprint-status `in-progress` | false | By design: Build syncs sprint-status at implementation start and again when the story is done. | reject |
| R5 | Blind Hunter | No lasting tripwire for "no socket" | low | Real, but the closed-port URL still makes a missed fake fail fast, and a global `HttpOverrides` guard adds test infrastructure. | reject (low) |
| R6 | Blind Hunter | A non-Serverpod error from `isSignedIn` propagates out of `AuthService.initialize()` and throws at startup | false | `initializeClient` (`client.dart`) wraps `authService.initialize()` in try/catch; production behavior is unchanged by this story. | reject |
| R7 | Blind Hunter, Edge Case Hunter | `signOutAllDevices` not faked; `noSuchMethod` swallowed by `_signOut`, so a test would pass while proving nothing | low | Confirmed in `session_manager.dart` `_signOut` catch. The app has no caller yet; the fix is a direct override. | patch (test) |
| R8 | Blind Hunter | Default `FakeAuthStatus.serverError()` is documented as "can't be reached" but throws a 500 | low | Confirmed; the old helper was a connection failure (`ServerpodClientNetworkException extends ServerpodClientException`). | patch (test) |
| R9 | Blind Hunter | Slow-server test relies on the library's 2 s default `initialize` timeout | low | True, but pinning it means a production constant (the spec keeps production unchanged); an upgrade that changes the default fails loudly at 'still waiting for the server'. | reject (low) |
| R10 | Blind Hunter | Duplicate `FakeEndpointAnonymousIdp` kept; no refactor commit | low | The spec's Code Map says to keep the richer local fake; the `hide` import is explicit. | reject (spec decision) |
| R11 | Blind Hunter | Matrix tests miss assertions (revoked `isSignedInCalls`, slow-server storage/queue, server-error `pumpEventQueue`) | low | Confirmed in the diff; direct additions. | patch (test) |
| R12 | Blind Hunter | Removed CI secrets remain public in history; rotation undecided | false | The values match only the local `test:` run mode (the scaffold's test secrets; the DB one is also in the committed `docker-compose.yaml` since `841d039`). Development and production use other values. | reject |
| R13 | Blind Hunter | Existing developer `passwords.yaml` files can still lack keys | low | Pre-existing setups; server tests fail loudly on a missing key, and the local file passes. | reject (low) |
| R14 | Edge Case Hunter | A stored `jwt`-strategy session in the helper would call the real `refreshJwtTokens` endpoint | low | Confirmed in `authKeyProviderDelegate`; every helper session uses `'session'`. A doc sentence is enough. | patch (doc) |

## Design Notes

Install the fake after the extension setter, which replaces the caller:

```dart
final client = Client('http://127.0.0.1:1/')
  ..authSessionManager = FlutterAuthSessionManager(storage: storage);
client.auth.setCaller(FakeAuthCoreCaller(client, status));
```

Keep `127.0.0.1:1` as the URL so a missed seam fails fast rather than reaching a dev server.

## Verification

**Commands:**
- `flutter test` in `string_theory_flutter` -- all green; `dart analyze` + `dart format --set-exit-if-changed .` clean in touched packages.
- `dart test` in `string_theory_server` -- green (local passwords unchanged).
- Simulate the CI server job in a scratch `git worktree` of `HEAD` (no `config/passwords.yaml`, no `SERVERPOD_PASSWORD_*` env): run the job's secret step, then `dart test` -- green. The real `config/passwords.yaml` is never touched.

**Manual checks:**
- After pushing, the GitHub Actions `Tests` run on `main` is green (user confirms).
