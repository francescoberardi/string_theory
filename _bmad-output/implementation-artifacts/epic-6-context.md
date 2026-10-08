# Epic 6 Context: Technical Debt, Concurrency & Production Polish

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Clear the pre-release technical debt and concurrency gaps left by the hackathon build so the app is production-ready: native UUID tenant identifiers across every server model and endpoint, a daily decay worker that cannot race itself or user session writes, live WebSocket broadcasts of decay changes, BLoC mutation flows that never misreport success as failure, hardened health-workout ingestion, a real Sessions history screen, and CI runs that are environment-consistent and deterministic.

## Stories

- Story 6.1: State Management Resilience (Mutation Refresh Decoupling, Async Pull-to-Refresh & Auth 401 Routing)
- Story 6.2: Health Ingestion Hardening (Lifecycle Resumed Sync, Workout Arrival Queue & Permission Feedback)
- Story 6.3: Native UUID Tenant Migration, Backend Concurrency & Live Updates
- Story 6.4: Dedicated Sessions History Screen & Domain Model Extraction
- Story 6.5: CI Environment Parity & Deterministic Auth Testing

## Requirements & Constraints

- **Tenant identity:** every tenant-scoped table (`Racquet`, `StringJob`, `SessionLog`, `RestringEvent`) carries an indexed `userId` typed `UuidValue`, taken directly from the authenticated user's `authUserId` — no hashing or modulus mapping. Workout idempotency is per tenant: unique on `(userId, externalWorkoutId)`.
- **Data migration decision:** existing rows in the four tenant tables may be discarded during the UUID migration; auth users are kept (guests keep their identity and see an empty bag). The schema the migration ends with must match `definition.sql`.
- **Decay worker concurrency:** the decay run takes a non-blocking PostgreSQL advisory lock (key `7421893`); when busy, the dev trigger answers 409 and the scheduled cron exits quietly. Score writes are optimistic (conditional on the `totalCourtHours` value read), skipping jobs a user session updated mid-run.
- **Live updates:** a decay change of at least 1% health publishes a `BagStreamMessage` on that user's bag channel; other tenants receive nothing.
- **Session input bounds:** `logSession` accepts `1 <= durationMinutes <= 360` and `startTime` no later than now + 5 minutes.
- **Client resilience:** a successful mutation followed by a failed bag reload must not surface an error; pull-to-refresh waits for the reload result (8 s safety timeout); HTTP 401 means re-authenticate, never "saved offline".
- **Health ingestion:** sync on app resume with a 60 s cooldown and 5 s timeout; multi-workout batches and workouts arriving during an open sheet are queued FIFO; missing/denied health permissions are explained in the UI; handled workout IDs persist across restarts.
- **CI:** auth secrets and IDP password env vars consistent across test jobs; generated-code drift checks scoped per package; auth tests use a fake status caller (no network timeouts).

## Technical Decisions

- Pure Dart `DecayEngine` remains the single scoring implementation, shared by client (optimistic UI) and server (authoritative writes and cron).
- Every endpoint filters by the resolved tenant on every operation; no cross-table joins for scoping.
- Real-time channel per user's bag, carrying typed `BagStreamMessage` events via Serverpod messaging.
- Flutter state uses `flutter_bloc` with unidirectional flow; all BLoC logic covered by `bloc_test`.
- Generated code (`lib/src/generated/`, `string_theory_client`) is never edited; only a generated `migration.sql` may be hand-edited, e.g. to empty tables before a destructive column change.
- Server tests run against the embedded PostgreSQL from `config/test.yaml`; test tenants use fixed UUID identities so fixtures are valid under `UuidValue` validation.

## Cross-Story Dependencies

- 6.3 goes first: the UUID tenant type change touches server models, the generated client, and Flutter fixtures that 6.1, 6.2 and 6.4 build on.
- 6.4's Sessions screen consumes session-log data scoped by the 6.3 tenant model.
- 6.5's CI parity work verifies the test suites the earlier stories extend.
