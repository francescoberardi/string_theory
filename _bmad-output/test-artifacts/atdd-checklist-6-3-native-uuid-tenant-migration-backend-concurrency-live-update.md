---
stepsCompleted:
  - 'step-01-preflight-and-context'
  - 'step-02-generation-mode'
  - 'step-03-test-strategy'
  - 'step-04-generate-tests'
  - 'step-04c-aggregate'
  - 'step-05-validate-and-complete'
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-10-08'
workflowType: 'testarch-atdd'
storyId: '6.3'
storyKey: '6-3-native-uuid-tenant-migration-backend-concurrency-live-update'
storyFile: '_bmad-output/planning-artifacts/epics.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-6-3-native-uuid-tenant-migration-backend-concurrency-live-update.md'
generatedTestFiles:
  - 'string_theory_server/test/integration/support/test_tenants.dart'
  - 'string_theory_server/test/integration/tenant_schema_test.dart'
  - 'string_theory_server/test/integration/decay_concurrency_test.dart'
  - 'string_theory_server/test/integration/tenant_resolver_test.dart'
  - 'string_theory_server/test/integration/session_endpoint_test.dart'
inputDocuments:
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/test-artifacts/test-design-epic-6.md'
  - '_bmad-output/implementation-artifacts/sprint-status.yaml'
  - '_bmad/tea/config.yaml'
  - 'string_theory_server/lib/src/models/racquet.spy.yaml'
  - 'string_theory_server/lib/src/models/string_job.spy.yaml'
  - 'string_theory_server/lib/src/models/session_log.spy.yaml'
  - 'string_theory_server/lib/src/models/restring_event.spy.yaml'
  - 'string_theory_server/lib/src/models/bag_stream_message.spy.yaml'
  - 'string_theory_server/lib/src/util/tenant_resolver.dart'
  - 'string_theory_server/lib/src/future_calls/daily_decay_future_call.dart'
  - 'string_theory_server/lib/src/endpoints/session_endpoint.dart'
  - 'string_theory_server/lib/src/endpoints/bag_endpoint.dart'
  - 'string_theory_server/lib/src/messaging/bag_channels.dart'
  - 'string_theory_server/test/integration/tenant_resolver_test.dart'
  - 'string_theory_server/test/integration/daily_decay_future_call_test.dart'
  - '.claude/skills/bmad-testarch-atdd/resources/knowledge/data-factories.md'
  - '.claude/skills/bmad-testarch-atdd/resources/knowledge/component-tdd.md'
  - '.claude/skills/bmad-testarch-atdd/resources/knowledge/test-quality.md'
  - '.claude/skills/bmad-testarch-atdd/resources/knowledge/test-healing-patterns.md'
acceptanceCriteria:
  - id: 'AC-1'
    idSource: 'generated'
    text: 'Given Serverpod models Racquet, StringJob, SessionLog, and RestringEvent, when the schema is migrated, then all userId columns are typed as UuidValue with database indices.'
  - id: 'AC-2'
    idSource: 'generated'
    text: 'SessionLog includes a composite unique index (userId, externalWorkoutId) isolating tenants.'
  - id: 'AC-3'
    idSource: 'generated'
    text: 'TenantResolver returns session.authenticated?.authUserId directly without custom hash or modulus workarounds.'
  - id: 'AC-4'
    idSource: 'generated'
    text: 'DailyDecayService acquires a non-blocking PostgreSQL advisory lock (pg_try_advisory_lock(7421893)); if busy, dev triggers return 409 and background cron exits gracefully.'
  - id: 'AC-5'
    idSource: 'generated'
    text: 'Decay batch updates execute optimistic conditional writes (WHERE id = @jobId AND "totalCourtHours" = @readCourtHours), skipping jobs concurrently updated by user sessions.'
  - id: 'AC-6'
    idSource: 'generated'
    text: 'When stringbed health score changes by >= 1%, DailyDecayService publishes a BagStreamMessage to the user''s stream channel.'
  - id: 'AC-7'
    idSource: 'generated'
    text: 'SessionEndpoint.logSession validates 1 <= durationMinutes <= 360 and startTime <= now() + 5 minutes.'
---

# ATDD Checklist: Story 6.3: Native UUID Tenant Migration, Backend Concurrency & Live Updates

**Date:** 2026-10-08
**Author:** Francesco
**Detected Stack:** `mobile` (auto: `pubspec.yaml`; Flutter client + Serverpod backend in one repo)
**Primary Test Level:** API / endpoint integration (`serverpod_test` `withServerpod`, embedded PostgreSQL)
**Story Key:** `6-3-native-uuid-tenant-migration-backend-concurrency-live-update`

---

## Step 1: Preflight & Context

### Prerequisites

- Story ACs: clear, 7 criteria (source: `epics.md` Story 6.3; no story spec file yet).
- Framework: `string_theory_server` uses `test` + `serverpod_test` 4.0.3, `dart_test.yaml` defines the
  `integration` tag, `config/test.yaml` boots an embedded PostgreSQL. No Docker needed.
- Sequencing: test design (dependency #1) puts 6.3 first. This run was switched from 6.1 to 6.3 for that reason.

### Affected Components

| Component | File | Change driven by |
| --- | --- | --- |
| Models (4 tables) | `lib/src/models/{racquet,string_job,session_log,restring_event}.spy.yaml` | AC-1, AC-2 |
| Tenant resolver | `lib/src/util/tenant_resolver.dart` (`resolveUserId` → `UuidValue`; delete `resolveUserIdFromIdentifier`) | AC-3 |
| Decay service | `lib/src/future_calls/daily_decay_future_call.dart` | AC-4, AC-5, AC-6 |
| Dev trigger | `BagEndpoint.triggerDailyDecayNow` | AC-4 (409) |
| Channels | `BagChannels.forUser(int)` → UUID | AC-1, AC-6 |
| Session endpoint | `SessionEndpoint.logSession`, `_findByExternalWorkoutId` (409 branch removed) | AC-2, AC-7 |
| Migration | new `migrations/<ts>/migration.sql` (hand-edited `TRUNCATE … CASCADE`) | AC-1 / R-001 |

### Existing Patterns

- `withServerpod('Given …', (sessionBuilder, endpoints) { … })`, auth via
  `AuthenticationOverride.authenticationInfo('<identifier>', {})`.
- Fixtures use numeric identifiers (`'101'`, `'1'`, `'3201'`) and `userId: 101`. These break under
  `UuidValue.withValidation` (R-003), so a shared `TestTenants` helper is needed first.
- Test names carry `[P0]`/`[P1]` and `AC-n` prefixes.

### Knowledge Fragments (closed set for `mobile`)

`data-factories.md`, `component-tdd.md`, `test-quality.md`, `test-healing-patterns.md`.

---

## Step 2: Generation Mode

**Mode:** AI generation, from the story ACs, test design, and source analysis.

**Why:** all 7 ACs are server-side (schema, resolver, advisory lock, conditional write, broadcast, endpoint
validation) with no UI. Browser recording doesn't apply: the stack is `mobile` and Flutter renders to canvas.

---

## Step 3: Test Strategy

### Red-phase constraints

- CI runs `flutter analyze --fatal-infos`, so scaffolds must **compile against today's API** and stay
  `skip`ped on `main` (Story 2.1 precedent: `skip: tddRedPhaseReason`).
- No `userId` literals in new tests: setup goes through endpoints (`createRacquet`, `logSession`), so the
  scaffolds survive the `int` → `UuidValue` type change without edits.
- Tenants are fixed UUID strings (`TestTenants.a` / `.b`). These parse under today's resolver (hashed)
  and under `UuidValue.withValidation` after 6.3.
- One tooling stub is needed: an `afterPageRead` callback on `DailyDecayService.performDecayCalculation`
  (the test design's "post-read seam"). It is called after each page read and changes no behavior.

### Primary red-phase scaffolds (one per criterion)

| AC | Level | Pri | File | Scenario | First (criterion-defining) assertion | Fails today because |
| --- | --- | --- | --- | --- | --- | --- |
| AC-1 | Integration (DB catalog) | P0 | `test/integration/tenant_schema_test.dart` | Read `information_schema.columns` for `userId` on the 4 tables | type map == `{racquet: uuid, string_job: uuid, session_log: uuid, restring_event: uuid}` | columns are `bigint` |
| AC-2 | API | P1 | `test/integration/tenant_schema_test.dart` | Tenants A and B each log the same `externalWorkoutId` | B's `logSession` completes (no throw) | global unique index → 409 "already registered to another account" |
| AC-3 | Integration (unit on Session) | P0 | `test/integration/tenant_resolver_test.dart` | Authenticated as `TestTenants.a` | `resolveUserId(session) == session.authenticated!.authUserId` | returns hashed `int` |
| AC-4 | API (concurrency) | P0 | `test/integration/decay_concurrency_test.dart` (`RollbackDatabase.disabled`) | Hold `pg_advisory_xact_lock(7421893)` in an open transaction, call `triggerDailyDecayNow` | throws `BagException` with `statusCode == 409` | no lock, returns a count |
| AC-5 | API (concurrency, seam) | P0 | `test/integration/decay_concurrency_test.dart` | Seam logs a 90-min session between page read and write | stored `currentHealthScore` == score written by the session | batch write overwrites it with the stale score (lost update) |
| AC-6 | API (stream) | P1 | `test/integration/decay_concurrency_test.dart` (`RollbackDatabase.disabled`) | Subscribe `bagUpdates(A)`, run decay with `now` +30 days | message for the racquet arrives with `healthScore` == new stored score | decay publishes nothing (timeout) |
| AC-7 | API | P1 | `test/integration/session_endpoint_test.dart` | `logSession` with `durationMinutes: 361` | throws `BagException` with `statusCode == 400` | only `<= 0` is rejected |

Priorities follow the test design: AC-1/3/4/5 map to R-001..R-006 (score 6, P0); AC-2/6/7 map to R-004/R-007/R-008 (P1).

### Secondary branches (green-phase automation, no red leaves)

- **AC-1:** `userId` index on each of the 4 tables (catalog); migration on a populated DB at
  `20261005101241116` → succeeds, 4 tables empty, auth rows kept; `pg_dump --schema-only` diff vs
  `definition.sql` is empty. The migration checks are **not reachable from `dart test`** and need a script/CI job (R-001).
- **AC-2:** same tenant, same ID → original row returned, hours counted once; catalog shows a unique index on
  `(userId, externalWorkoutId)`; the dead cross-tenant 409 branch is removed.
- **AC-3:** unauthenticated → 401; non-UUID identifier (`'101'`) → `BagException(401)`, not a 500 `FormatException`.
  Delete the 21 hash/modulus tests in `test/unit/util/tenant_resolver_test.dart` and the golden-value test.
- **AC-4:** cron path returns quietly (no throw, 0 updates) while locked; the lock can be taken again after a
  successful run **and** after a run that threw (R-006 pooled-connection leak); two concurrent triggers → exactly one runs.
- **AC-5:** untouched jobs in the same page are still updated; return value excludes skipped jobs; the skipped
  job decays on the next run.
- **AC-6:** no score change → no message; tenant B's stream gets nothing (R-002).
- **AC-7:** boundaries 0 / 1 / 360 / 361; `startTime` now+5m accepted, now+6m rejected (injected clock).
- **Isolation suite (R-002):** convert existing int fixtures to `TestTenants` across `getVirtualBag`,
  `createRacquet`, `setPrimary`, `deleteRacquet`, `restringRacquet`, `logSession`, `getSessionLogs`, `bagUpdates`.
  Convert, don't duplicate.

---

## Step 4: Red-Phase Scaffolds

**Execution mode:** sequential, in-session. Config `tea_execution_mode: auto` would pick subagents, but every
input was already loaded here and subagents weren't requested. No worker temp files were written.
**Worker B (E2E):** 0 tests. 6.3 has no UI journey; the Flutter fixture update (R-015) belongs to the green phase.

### Files

| File | Change | Leaves |
| --- | --- | --- |
| `test/integration/support/test_tenants.dart` | **New.** `tddRedPhaseReason`, `TestTenants.a/.b` (fixed UUIDs) + `auth()`, `sessionLogFor()` factory (the only place holding a placeholder `userId`) | – |
| `test/integration/tenant_schema_test.dart` | **New** | AC-1, AC-2 |
| `test/integration/decay_concurrency_test.dart` | **New.** Lock + broadcast group (`RollbackDatabase.disabled`); optimistic-write group (default rollback) | AC-4, AC-6, AC-5 |
| `test/integration/tenant_resolver_test.dart` | Added one test | AC-3 |
| `test/integration/session_endpoint_test.dart` | Added one test to the rollback-disabled group | AC-7 |
| `lib/src/future_calls/daily_decay_future_call.dart` | **Tooling stub:** `afterPageRead` callback on `performDecayCalculation`, invoked after each page read. No behavior change | – |

All 7 leaves use `skip: tddRedPhaseReason`. `dart analyze` reports no issues; `dart format` made no changes.

### Red-phase evidence (`dart test --run-skipped`, 2026-10-08)

| AC | Result | Failure (the expected reason) |
| --- | --- | --- |
| AC-1 | 🔴 | `at location ['racquet'] is 'bigint' instead of 'uuid'` |
| AC-2 | 🔴 | `BagException(Workout already registered to another account, 409)` |
| AC-3 | 🔴 | Expected `UuidValue:<6f1e2a7d-…1a01>`, actual `<8826879987572848887>` |
| AC-4 | 🔴 | Expected throws 409, trigger `emitted <0>` |
| AC-5 | 🔴 | Expected `<83>` (session's score), actual `<76>` (stale decay overwrite) |
| AC-6 | 🔴 | `TimeoutException after 0:00:05`: no message published |
| AC-7 | 🔴 | Expected throws 400, `durationMinutes: 361` accepted |

Regular `dart test`: **99 passed, 7 skipped, 0 failed**.

---

## Step 5: Validation & Handoff

### Checklist validation

- [x] Prerequisites satisfied (ACs clear, `serverpod_test` + embedded PostgreSQL)
- [x] Criterion ids AC-1..AC-7 generated deterministically in source order; no supplied ids
- [x] Exactly one skipped leaf per criterion; every leaf title carries one declared id
- [x] Criterion-defining assertion is the first that can fail (verified by the failure messages above)
- [x] Setup uses only implemented endpoints (`createRacquet`, `logSession`, `getVirtualBag`); no `userId` literals in test bodies
- [x] Secondary branches recorded as green-phase work (Step 3)
- [x] No browser sessions opened; artifacts stored in `_bmad-output/test-artifacts/`
- [ ] Story file link-back: N/A. `storyFile` is `epics.md` (no story spec yet); `bmad-build` should reference this checklist when it creates the spec

### Activation order (green phase, task by task)

1. **Fixtures first (R-003/R-015):** convert existing server tests from numeric identifiers to `TestTenants`
   and drop `userId:` int literals; update the Flutter fixture factory for `UuidValue` in the same commit.
2. **AC-1/AC-2/AC-3:** change the 4 models, add the composite index, rewrite `resolveUserId` to return `authUserId`
   (non-UUID → 401), type `BagChannels.forUser` to `UuidValue`. Generate the migration, then hand-edit
   `migration.sql` to `TRUNCATE racquet, string_job, session_log, restring_event CASCADE` before the column
   changes (R-001). Un-skip AC-1, AC-2, AC-3. Delete `test/unit/util/tenant_resolver_test.dart` hash tests and the golden test.
3. **AC-7:** bounds in `logSession`. Un-skip AC-7, add the 0/1/360/361 and now+5m/+6m boundaries.
4. **AC-4:** advisory lock (prefer `pg_try_advisory_xact_lock` in one transaction, R-006). Un-skip AC-4, add
   re-acquire after success/after throw and cron-quiet cases.
5. **AC-5:** conditional write per job. Un-skip AC-5.
6. **AC-6:** publish on score change. Un-skip AC-6, add the no-change and tenant-B-silent cases.
7. **Migration script/CI job (R-001):** populated DB at `20261005101241116` → apply → tables empty, auth kept,
   schema diff vs `definition.sql` empty. Not reachable from `dart test`.

Run: `dart test` in `string_theory_server` after each step; remove `skip: tddRedPhaseReason` only for the
task being implemented.

### Risks & assumptions

- **AC-4 test design:** the lock is held with `pg_advisory_xact_lock` inside an open transaction so the trigger
  must use another pooled connection. It conflicts with both session-level and xact try-locks on the same key,
  so it doesn't constrain which one the implementation uses.
- **AC-6** relies on a 200 ms subscription settle delay (same pattern as `bag_stream_test.dart`) and a 5 s timeout.
- **AC-5** runs under default rollback, so the seam's `logSession` and the decay write share one transaction
  and run strictly in sequence (deterministic).
- `sessionLogFor` holds `userId: 0`; it becomes a `UuidValue` placeholder in step 1 above.
