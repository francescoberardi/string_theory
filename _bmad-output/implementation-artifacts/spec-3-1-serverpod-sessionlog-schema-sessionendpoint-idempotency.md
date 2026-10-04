---
title: 'Story 3.1: Serverpod SessionLog Schema, SessionEndpoint & Idempotency'
type: 'feature'
created: '2026-10-04'
status: 'in-progress'
baseline_commit: '2869857582d04cced63089ecadd237d1cd297d91'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '_bmad-output/implementation-artifacts/epic-3-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Tennis playtime needs to increment a racquet's active stringbed court hours and dynamically recalculate tension decay, but there is no persistent session log model or backend endpoint to process sessions idempotently and prevent duplicate counts from health synchronizations.

**Approach:** Define the Serverpod `SessionLog` model with foreign key relations, create a database migration with a unique index on `externalWorkoutId`, and implement `SessionEndpoint` with transactional stringbed court hours updates, `DecayEngine` recalculation, and idempotent deduplication.

## Boundaries & Constraints

**Always:**
- Direct multi-tenant scoping: all queries and writes must validate `session.authenticated.userId` and scope by `userId: int`.
- Idempotency: submitting a workout with an already existing `externalWorkoutId` must succeed idempotently by returning the existing record without incrementing hours.
- Atomic execution: `SessionLog` insertion and `StringJob` updates (`totalCourtHours` and `currentHealthScore`) must execute inside a single database transaction.
- Health calculation: `DecayEngine.calculateHealth` must be used to recalculate `currentHealthScore` on the updated `StringJob`.
- Non-negative validation: `durationMinutes` must be $> 0$.

**Never:**
- Never double-count play hours if `externalWorkoutId` matches an existing record.
- Never allow logging sessions for a racquet that does not belong to the authenticated user.
- Never mutate or log against inactive string jobs; the session must target the racquet's active string job.
- Never edit generated code under `lib/src/generated/` or the client package directly.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| First-time session log | Valid auth, valid `racquetId`, `durationMinutes = 90`, `externalWorkoutId = "hk-1"` | `SessionLog` inserted, `StringJob.totalCourtHours` += 1.5, `currentHealthScore` updated, returns `SessionLog` | N/A |
| Duplicate external workout | Valid auth, same `externalWorkoutId = "hk-1"` sent a second time | Returns existing `SessionLog`, `StringJob.totalCourtHours` remains unchanged | N/A (idempotent 200 OK) |
| Manual log without external ID | Valid auth, `externalWorkoutId = null`, `durationMinutes = 60` | `SessionLog` inserted, hours incremented by 1.0, multiple manual sessions allowed without conflict | N/A |
| Invalid duration | `durationMinutes <= 0` | No DB changes | Throws `BagException` with status 400 |
| Foreign / non-existent racquet | `racquetId` belongs to another user or doesn't exist | No DB changes | Throws `BagException` with status 404 |
| Racquet without active string job | Racquet has no active `StringJob` | No DB changes | Throws `BagException` with status 400 |
| Unauthenticated request | `session.authenticated == null` | No DB changes | Throws `BagException` with status 401 |

</frozen-after-approval>

## Code Map

- `string_theory_server/lib/src/models/session_log.spy.yaml` -- New Serverpod model definition for `SessionLog` with `table: session_log`, `userId`, `racquetId`, relations, and unique index on `externalWorkoutId`.
- `string_theory_server/lib/src/endpoints/session_endpoint.dart` -- New Serverpod endpoint with `logSession` and `getSessionLogs` RPC methods.
- `string_theory_server/lib/src/domain/decay_engine.dart` -- Existing pure Dart domain engine; reused for health recalculation on `StringJob`.
- `string_theory_server/lib/src/models/bag_exception.spy.yaml` -- Existing exception model for validation and error reporting.
- `string_theory_server/test/integration/session_endpoint_test.dart` -- Integration tests verifying schema, CRUD, idempotency, health recalculation, and security scoping.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_server/lib/src/models/session_log.spy.yaml` -- Create model -- Define `SessionLog` with `userId`, `racquetId` relation, `startTime`, `durationMinutes`, `courtSurface`, `notes`, `source`, `externalWorkoutId`, `createdAt`, and indexes (`userId`, `racquetId`, unique `externalWorkoutId`).
- [x] `string_theory_server` -- Run Serverpod migration -- Run `serverpod create-migration` and generate client/server code.
- [x] `string_theory_server/lib/src/endpoints/session_endpoint.dart` -- Implement endpoint -- Create `SessionEndpoint` with `logSession(Session session, SessionLog log)` enforcing authentication, idempotency check, transactional insertion, string job hour increment, and `DecayEngine` recalculation, plus `getSessionLogs(Session session, {int? racquetId, int? limit, int? offset})`.
- [x] `string_theory_server/test/integration/session_endpoint_test.dart` -- Add integration test suite -- Test table creation, foreign keys, happy path logging, idempotency on repeated `externalWorkoutId`, duration validation, unauthorized racquet rejection, and health decay recalculation.

**Acceptance Criteria:**
- Given Serverpod model `SessionLog` with `userId: int`, `racquetId: int`, and unique index on `externalWorkoutId`,
- When `SessionEndpoint.logSession(session, log)` is called with valid data,
- Then the session is inserted into `session_log`,
- And the racquet's active `StringJob.totalCourtHours` is incremented by the session duration in hours,
- And `DecayEngine.calculateHealth` recalculates `StringJob.currentHealthScore`,
- And calling `logSession` with the same `externalWorkoutId` acts idempotently without double-counting hours.

## Implementation Notes

## Spec Change Log

## Review Triage Log

## Design Notes

### Idempotency Flow
```dart
if (log.externalWorkoutId != null && log.externalWorkoutId!.isNotEmpty) {
  final existing = await SessionLog.db.findFirstRow(
    session,
    where: (t) => t.externalWorkoutId.equals(log.externalWorkoutId) & t.userId.equals(userId),
  );
  if (existing != null) {
    return existing;
  }
}
```

## Verification

**Commands:**
- `dart analyze` in `string_theory_server` -- expected: No issues found
- `dart test test/integration/session_endpoint_test.dart` in `string_theory_server` -- expected: All integration tests pass
