---
title: 'Make auth_service_test hermetic and fix FakeEndpointAnonymousIdp null safety'
type: 'bugfix'
created: '2026-10-06'
status: 'done'
route: 'oneshot'
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `string_theory_flutter/test/auth_service_test.dart` fails when the local dev server is running (epic-5 retro item 1). The test clients point at `http://localhost:8080/`, so `client.auth.initialize()` validates the stored fake token against the live server. The server rejects it, the session manager signs the device out, `AuthService` falls back to `loginAsGuest()`, and the unconfigured `FakeEndpointAnonymousIdp` crashes on `successToReturn!`. This breaks the rehydrate and signOut tests. CI has no server, so the network error is swallowed and the tests pass there. The failure is environmental, not a race.

**Approach:** Keep the fix test-only. Point every test `Client` at a closed local port so session validation fails fast with a connection error, which `ClientAuthSessionManager.initialize()` swallows while keeping the restored session. Make the fake fail loudly with a descriptive `StateError` when it is unconfigured, instead of a bare null check. Do not give it a silent default `AuthSuccess`, because that would hide unexpected login calls.

</frozen-after-approval>

## Implementation Notes

- Root cause (serverpod_auth_core_client 4.0.3 `session_manager.dart`): `initialize()` = `restore()` + `validateAuthentication()`. Validation calls `refreshAuthKey(force: true)` and `caller.status.isSignedIn()`. `ServerpodClientException` and `TimeoutException` are caught and the session is kept, but `isSignedIn() == false` triggers `signOutDevice()`.
- Only `test/auth_service_test.dart` changes. `lib/services/auth_service.dart` stays as it is: blocking validation on startup is product behavior and out of scope.
- Extract a small `buildTestClient(storage)` helper using an unreachable base URL (e.g. `http://127.0.0.1:1/`) to remove the six duplicated client constructions.
- Also fix the unawaited `expect(authService.initialize(), throwsA(...))` → `await expectLater(...)` so the network-failure test actually asserts before the test ends.
- Verify with the dev server running on :8080: `flutter test test/auth_service_test.dart` must pass all 6 tests.
- Review patch: renamed the rehydrate test to "given stored session and unreachable server ...", because it now covers the offline path, not a server-validated one. `buildTestClient` registers `addTearDown(client.close)`.
- Result with the dev server live on :8080: `auth_service_test.dart` 6/6 pass; full `flutter test` 365/365 pass; `dart analyze` clean.

## Review Triage Log

- Rehydrate test name overstates coverage (only the unreachable-server path is exercised) — medium, patched (renamed).
- No test for "server rejects stored session → guest login fallback" / valid-session path — medium, deferred (needs a fake auth-core status caller, which is more than a simple fix).
- Dead port 1 is not truly hermetic — low: a refused or dropped connection is still swallowed by `initialize()` (TimeoutException caught, at worst 2s slower). Deferred together with the fake-caller item above.
- Doc comment relies on unasserted library behavior — low, rejected: the rehydrate test's assertions already fail loudly if that behavior changes.
- Clients never closed — low, patched (`addTearDown(client.close)` in the helper).
- Same flakiness in settings_screen_test / widget_test — false: the full suite passed 365/365 with the dev server live (these run under `testWidgets`, whose binding stubs HTTP).
- Test doubles duplicated across files — low, rejected (pre-existing, cosmetic).
- New fake StateError guard untested / `exceptionToThrow` typed `Exception?` — low, rejected (test-double hygiene, no caller needs it).
- Spec missing sections / baseline — false: oneshot route deletes those sections by design; status finalized here.
- Sprint status not updated; retro calls it a "flake" — low: sprint item set to done in this commit; retro text left unchanged (retro docs are records).
- Slug says "null safety" but main fix is hermeticity — low, rejected (title documents the scope).
- `AuthService.initialize()` doc says "without network blocking" but awaits validation (≤2s) — low, deferred (pre-existing, not caused by this change).
