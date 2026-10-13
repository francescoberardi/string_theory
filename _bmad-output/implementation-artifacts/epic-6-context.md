# Epic 6 Context: Technical Debt, Concurrency & Production Polish

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Clear the pre-release technical debt and concurrency gaps left by the hackathon build so the app is production-ready and fully testable by reviewers. That means native UUID tenant identifiers across every server model and endpoint, a daily decay worker that cannot race itself or user session writes, live WebSocket broadcasts of decay changes, BLoC mutation flows that never report a success as a failure, hardened health-workout ingestion, and a real Sessions history screen. It also means real email sign-in with guest-to-email bag linking, so reviewers can open one account in two windows to watch live sync and use a second account to check tenant isolation, plus CI runs that use consistent environments and deterministic tests.

## Stories

- Story 6.1: State Management Resilience (Mutation Refresh Decoupling, Async Pull-to-Refresh & Auth 401 Routing)
- Story 6.2: Health Ingestion Hardening (Lifecycle Resumed Sync, Workout Arrival Queue & Permission Feedback)
- Story 6.3: Native UUID Tenant Migration, Backend Concurrency & Live Updates
- Story 6.4: Dedicated Sessions History Screen & Domain Model Extraction
- Story 6.6: Real Email Sign-In for Multi-Window Testing
- Story 6.5: CI Environment Parity & Deterministic Auth Testing

## Requirements & Constraints

- **Tenant identity:** every tenant-scoped table (`Racquet`, `StringJob`, `SessionLog`, `RestringEvent`) has an indexed `userId` of type `UuidValue`, taken directly from the authenticated `authUserId` with no hashing. Workout idempotency is per tenant: `(userId, externalWorkoutId)` is unique.
- **Decay worker concurrency:** the decay run takes a non-blocking PostgreSQL advisory lock (key `7421893`). When the lock is busy, the dev trigger returns 409 and the cron exits quietly. Score writes are conditional on the `totalCourtHours` value that was read, so jobs a user session changed mid-run are skipped. A health change of at least 1% publishes a `BagStreamMessage` on that user's channel only.
- **Session input bounds:** `1 <= durationMinutes <= 360`, and `startTime` is no later than now + 5 minutes.
- **Client resilience:** a successful mutation followed by a failed bag reload must not show an error. Pull-to-refresh waits for the reload result (8 s safety timeout). HTTP 401 means re-authenticate, never "saved offline".
- **Health ingestion:** sync on app resume with a 60 s cooldown and a 5 s timeout. Batches of workouts, and workouts that arrive while a sheet is open, are queued FIFO. Missing or denied health permissions are explained in the UI. Handled workout IDs persist across restarts.
- **Sign-in and sign-out:** with no stored session, the app opens on a sign-in screen offering email sign-in or sign-up (including the verification-code step) and `[Continue as guest]`. A stored session skips that screen, so the cold-start budget holds. Sign-out removes the token, closes the bag stream, clears the bag state and returns to sign-in. Before a guest signs out, they are warned that their bag becomes unreachable unless they link it first. A fresh email account starts with an empty bag.
- **Guest to email linking:** the guest's racquets, string jobs, sessions and restring history move to the email account. The bag shows the same racquets and scores as before, and racquet IDs are unchanged so queued offline sessions still apply. Google linking is deferred, and no fake auth buttons may ship.
- **Multi-window:** whether two tabs of one browser profile share an identity must be verified by running it, then documented. A second account is opened in a private window or a second browser profile.
- **Fresh clone:** one script (`tool/init_passwords.sh`) generates `config/passwords.yaml` with random development and test secrets and refuses to overwrite an existing file. CI env vars stay as they are.
- **CI:** auth secrets and IDP password env vars are consistent across test jobs, generated-code drift checks are scoped per package, and auth tests use a fake status caller with no network timeouts.
- **Docs:** README ("Start" and "Test it (for reviewers)") and DEMO_SCRIPT must describe only behavior that has shipped on `main`, updated in the same story.

## Technical Decisions

- The pure Dart `DecayEngine` remains the only scoring implementation, shared by the client (optimistic UI) and the server (authoritative writes and cron).
- Every endpoint filters by the resolved tenant on every operation, with no indirect joins.
- **Ownership transfer:** the only sanctioned way to change a row's `userId` is linking. While still signed in as the guest, the client calls `AccountEndpoint.createGuestClaim()`. The server stores a single-use, hashed secret bound to that anonymous-only user, valid for 15 minutes. After the email sign-in, `claimGuestBag(secret)` runs Serverpod `AccountMerger.merge` in one transaction, using an app `applicationMergeHandler` registered via `AccountMergeConfig` in `initializeAuthServices`. Conflicts go to the kept account: duplicate `(userId, externalWorkoutId)` guest sessions are dropped and guest `isPrimary` is cleared. The claim is then deleted and a `BagStreamMessage` is sent to the email user. Reused, expired, foreign or unauthenticated claims change no rows. The secret exists because, after the identity switch, the server can no longer see that the caller used to be the guest.
- New `GuestClaim` table: the schema goes in `.spy.yaml` and the migration is created through MCP.
- Flutter: an auth gate in `main.dart` picks between the sign-in screen and the bag. `AuthService` no longer creates a guest at `initialize`; it exposes `continueAsGuest` and `signOut`, and keeps the existing in-flight guest dedupe. The unused template `sign_in_screen.dart` and `greetings_screen.dart` are replaced or deleted. State uses `flutter_bloc` with `bloc_test` coverage.
- Generated code is never edited. Server tests run against the embedded PostgreSQL from `config/test.yaml`, with fixed UUID test tenants.

## UX & Interaction Patterns

- The sign-in screen uses the Court Midnight theme and comes before the bag. Settings shows the account banner for a guest, with `[Continue with Email]` (links and keeps the bag), or shows the account email for an email user. `[Sign Out]` returns to the sign-in screen. The "Re-authenticate Guest" action is removed.
- Navigation (bottom nav, rail, drawer) includes a Sessions tab with a chronological history and a prominent `[+ Log Session]` action.
- The demo flow starts at the sign-in screen with `[Continue as guest]`, and includes a Sessions beat and a live two-window sync beat, in about 90 seconds.

## Cross-Story Dependencies

- 6.1 to 6.4 are done. 6.6 builds on 6.3 (UUID tenants, `BagStreamMessage` channels) and on the 6.1 401 path, which sends a signed-out tab back to sign-in.
- 6.6 runs before 6.5: 6.5 rewrites `auth_service_test.dart` with a fake status caller and must build on the final 6.6 `AuthService`.
- 6.6 changes existing tests that assume an automatic guest (Patrol E2E, widget, settings and auth tests) so they tap `[Continue as guest]`.
- If 6.6 runs past a day, the linking work (claim endpoints, merge handler, Settings link flow) can be split off as Story 6.7.
