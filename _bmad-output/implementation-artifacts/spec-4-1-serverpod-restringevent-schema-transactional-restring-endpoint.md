---
title: 'Story 4.1: Serverpod RestringEvent Schema & Transactional Restring Endpoint'
type: 'feature'
created: '2026-10-04'
status: 'done'
baseline_commit: 'b4d5918131cf00ee9600adba1292cf6abf21f791'
route: 'dispatch'
review_loop_iteration: 0
context:
  - 'string_theory/_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/ARCHITECTURE-SPINE.md'
  - 'string_theory/_bmad-output/implementation-artifacts/epic-4-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Tennis players need to retire exhausted stringbeds (<40% health) and mount fresh setups. Without an atomic, multi-tenant persistence model, retiring a stringbed and mounting a fresh one risks inconsistent bag state, orphaned string records, and missing historical telemetry.

**Approach:** Introduce the Serverpod `RestringEvent` database model with multi-tenant scoping (`userId: int`), generate database migrations, and implement a transactional `restringRacquet` endpoint in `BagEndpoint` that atomically marks the active string job inactive, archives a `RestringEvent` snapshot, initializes a fresh active string job (100% health, 0 court hours), and publishes a real-time WebSocket event. Also implement `getRestringHistory` for chronological timeline retrieval.

## Boundaries & Constraints

**Always:**
- Execute retiring the old `StringJob`, persisting the `RestringEvent`, creating the new `StringJob`, and updating the `Racquet.activeStringJobId` inside a single Serverpod database transaction (`session.db.transaction`).
- Enforce multi-tenancy: verify `racquetId` belongs to the authenticated user (`session.authenticated.userId`); all tables (`RestringEvent`, `StringJob`, `Racquet`) scope by `userId`.
- Roll back all changes if any query or insertion in the transaction fails (NFR-5).
- Publish a `BagStreamMessage` with `eventType: BagChannels.restrung` (`'restrung'`), `racquetId`, `healthScore: 100`, and `totalCourtHours: 0.0` to `user_{userId}_bag` upon transaction success.
- Calculate `finalDaysActive` as `restringDate.difference(stringingDate).inDays` clamped to $\ge 0$.

**Never:**
- Never perform the database operations across separate non-transactional calls.
- Never delete the retired `StringJob`; set `isActive = false` to retain foreign key integrity with `RestringEvent`.
- Never allow a user to restring or view history of a racquet owned by another user.
- Never leave a racquet without an active `StringJob` if the transaction completes.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Restring (Keep Same) | `racquetId`, `keepSame: true` | Retired job `isActive: false`; `RestringEvent` persisted with final hours & days active; new `StringJob` created with identical specs, `0.0` hours, `100` health, `isActive: true`; `Racquet.activeStringJobId` updated; WebSocket broadcast sent; returns `Racquet` with active job | N/A |
| Restring (Change Specs) | `racquetId`, `keepSame: false`, `newSpecs` (or spec parameters) | Retired job archived; new `StringJob` created with new brand/model/tension/category/maxHours; WebSocket broadcast sent; returns updated `Racquet` | Fall back to sensible defaults if maxHours <= 0 |
| Transaction Failure / Rollback | Mid-transaction DB error or constraint violation | DB rolls back completely; old `StringJob` remains active; no `RestringEvent` created; no new `StringJob` created | Throws exception; no WebSocket message published |
| Racquet Not Found or Unauthorized | `racquetId` belongs to another user or does not exist | No DB modification | Throws `BagException(statusCode: 404)` |
| Racquet Missing Active Job | `racquetId` exists but has no active string job | No DB modification | Throws `BagException(statusCode: 400, message: 'Racquet has no active string job to retire')` |
| Get Restring History | Valid `racquetId` owned by user | Returns `List<RestringEvent>` sorted by `restringDate` descending | Returns empty list if no prior restrings |
| Get Restring History (Unauthorized) | `racquetId` owned by another user or not found | No records leaked | Throws `BagException(statusCode: 404)` |

</frozen-after-approval>

## Code Map

- `string_theory_server/lib/src/models/restring_event.spy.yaml` -- New Serverpod model defining table `restring_event` with fields `userId`, `racquetId`, `stringJobId`, `stringDescription`, `materialCategory`, `stringingDate`, `restringDate`, `finalCourtHours`, `finalDaysActive`, `finalHealthScore`, `createdAt` and indexes on `userId` and `racquetId`.
- `string_theory_server/migrations/` -- Generated Serverpod migration for `restring_event` table and foreign key constraints.
- `string_theory_server/lib/src/util/tenant_resolver.dart` -- Extracted shared helper for `resolveUserId(Session session)` addressing tech-debt action item from Epic 3 retrospective.
- `string_theory_server/lib/src/endpoints/bag_endpoint.dart` -- Add `restringRacquet` and `getRestringHistory` endpoints, with transactional atomicity and WebSocket broadcasting via `BagChannels.restrung`.
- `string_theory_server/lib/src/endpoints/session_endpoint.dart` -- Refactor to reuse `resolveUserId(Session session)` from `tenant_resolver.dart`.
- `string_theory_server/lib/src/messaging/bag_channels.dart` -- Verify `restrung` constant is in place.
- `string_theory_server/test/integration/bag_endpoint_test.dart` -- Add comprehensive integration tests verifying `restringRacquet` (keep same, change specs, 404, 400, rollback on error) and `getRestringHistory`.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_server/lib/src/models/restring_event.spy.yaml` -- Create `RestringEvent` model schema with table definition, relations, and indexes -- Enables historical stringbed archival.
- [x] `string_theory_server/lib/src/util/tenant_resolver.dart` -- Create shared tenant resolver helper and migrate `BagEndpoint` and `SessionEndpoint` to use it -- Eliminates code duplication and fulfills epic-3 retro action item.
- [x] Run migration creation & code generation via MCP / CLI -- Generate Serverpod database migration and client protocols.
- [x] `string_theory_server/lib/src/endpoints/bag_endpoint.dart` -- Implement `restringRacquet` with transaction, archival, fresh job creation, and WebSocket event; implement `getRestringHistory` -- Provides core restringing API.
- [x] `string_theory_server/test/integration/bag_endpoint_test.dart` -- Add integration test suite for `RestringEvent`, `restringRacquet`, transactional rollback, and `getRestringHistory` -- Guarantees atomic restringing and regressions-free endpoints.

**Acceptance Criteria:**
- Given a racquet with an active stringbed having accumulated court hours and decayed health, when `restringRacquet` is called with `keepSame: true`, then within a single database transaction the existing job is deactivated (`isActive: false`), a `RestringEvent` is persisted with accurate final hours and active days, a new active `StringJob` is inserted with 0 hours and 100 health, the racquet's `activeStringJobId` points to the new job, and a `BagStreamMessage` is broadcast.
- Given an intentional failure during the transaction, then neither the `RestringEvent` nor the new `StringJob` is persisted, the old `StringJob` remains active, and the database state is completely unchanged.
- Given a user querying `getRestringHistory` for their racquet, then only restringing events belonging to that user and racquet are returned in descending chronological order.

## Implementation Notes

## Spec Change Log

## Review Triage Log

## Design Notes

### String Description Formatting
When archiving a retired `StringJob` into `RestringEvent`, `stringDescription` is derived as:
```dart
String _formatStringDescription(StringJob job) {
  final brand = job.brand?.trim() ?? '';
  final model = job.model?.trim() ?? '';
  if (brand.isNotEmpty && model.isNotEmpty) {
    return '$brand $model';
  } else if (brand.isNotEmpty) {
    return brand;
  } else if (model.isNotEmpty) {
    return model;
  } else {
    return '${job.materialCategory.name} setup';
  }
}
```

### Days Active Calculation
```dart
final daysActive = restringDate.difference(oldJob.stringingDate).inDays;
final finalDaysActive = daysActive < 0 ? 0 : daysActive;
```

## Verification

**Commands:**
- `cd string_theory_server && dart test test/integration/bag_endpoint_test.dart` -- expected: All integration tests pass, including new restringing tests.
- `dart analyze` -- expected: 0 errors across workspace.

### Review Findings

Code review of the hand-written chunk (endpoints, tenant resolver, model, `migration.sql`, tests). Generated code and migration definition files were out of scope for this pass. Reviewed 2026-10-05, mode `full`.

- [x] [Review][Patch] Harden the test-only knobs on `restringRacquet` (resolved from decision: keep both params, harden them) — medium. Move the `simulateFailure` run-mode guard before the transaction so non-test calls fail before any write. Honor `restringDate` only in test mode and reject it with 400 otherwise. Set the new job's `stringingDate` to now (FR-15) instead of `restringDate`, and update the AC-2 assertion that expects `newJob.stringingDate == restringDate`. The existing clamp of `finalDaysActive` to >= 0 stays, as the spec requires (AC-10). [bag_endpoint.dart:296-312, 390-398, 439]
- [x] [Review][Patch] Concurrent `restringRacquet` calls can leave duplicate events and two active jobs — medium. The racquet and active job are read with no lock. Two simultaneous calls (e.g. a double-tap on "Restrung Today" in Story 4.2) both see `isActive == true`. The second blocks on the first's `updateRow` and then proceeds, so it inserts a second `RestringEvent` for the same job and a second active `StringJob`, while the racquet points only at the last one. Fix: lock the racquet row inside the transaction, or re-check `oldJob.isActive` after acquiring the lock. [bag_endpoint.dart:316-358] — applied: `LockMode.forUpdate` on the racquet row (no include). A concurrency test was added; the in-process test harness may serialize calls, so it does not prove the lock under real contention.
- [x] [Review][Patch] Rollback test under-asserts the spec'd behaviour — medium. `throwsA(isA<Exception>())` is also satisfied by the production-guard `BagException(400)`, because `BagException` implements `Exception`, so the test cannot show the intended failure point was reached. It never asserts that no new `StringJob` row exists, and never asserts that no `restrung` message is published after rollback (spec I/O matrix). Assert the exact exception and message, count the racquet's `StringJob` rows, and subscribe to the bag stream to check that nothing is published. [bag_endpoint_test.dart:655-696]
- [x] [Review][Patch] Snapshot assertions cannot distinguish old, new and zero values — medium. `finalCourtHours` is only asserted in AC-2, where no session is logged, so 0.0 passes whether the code reads the old job, the new job or a constant. `materialCategory` is coPoly for both old and new job in AC-2 and AC-3, and AC-3b never asserts `history.first.materialCategory`. Change the event to record `nextCategory`, drop the scalar `materialCategory` param, or hard-code `finalCourtHours` to 0 and no test fails. Add a test that logs a session (non-zero hours), restrings to a different category, and asserts the event holds the OLD category and hours while the new job has 0.0 hours. [bag_endpoint_test.dart:513, 541-564, 621-626]
- [x] [Review][Patch] Non-finite `maxRatedHours` (Infinity) is persisted — low. Only `NaN` and `<= 0` fall back to 20.0, so `Infinity` passes through and the stringbed never decays. Use `!nextMaxHours.isFinite || nextMaxHours <= 0`. [bag_endpoint.dart:426] — applied; not testable end-to-end because Serverpod's JSON encoding cannot carry `Infinity` over the wire, so no test was added.
- [x] [Review][Patch] Stale doc comment on `BagChannels.restrung` — low. It still says "reserved for Story 4.1", but the constant is now used by `_publishRestrung`. [string_theory_server/lib/src/messaging/bag_channels.dart:6]
- [x] [Review][Defer] `resolveUserId` maps auth identifiers to `int` by UUID mod 2^63-1 or FNV-1a hash; negative integer strings are accepted; the shared helper has no unit tests and throws a domain `BagException` from `util/` [string_theory_server/lib/src/util/tenant_resolver.dart:14-32] — deferred: pre-existing logic moved verbatim from `SessionEndpoint`; collision odds are negligible. Revisit the identity-to-`userId` mapping when auth is reworked.
- [x] [Review][Defer] No test that other users' `bagUpdates` streams receive nothing from a restring, or that a failed `postMessage` leaves the restring committed [bag_endpoint_test.dart] — deferred: secondary guarantees (the success path is verified); add to `bag_stream_test.dart` as a follow-up.

#### Rejected

- `ServerpodRunMode` comparison may be wrong in Serverpod 4.0.3 (false): `Serverpod.runMode` is a `String` and `ServerpodRunMode.*` are string constants (`serverpod-4.0.3/lib/src/server/serverpod.dart:98`); `dart analyze lib` reports no issues.
- AC-2 `finalDaysActive == 40` is flaky (false): `stringingDate = now`, fast-forward subtracts exactly 40 days, and `restringDate = now`, so the difference is exactly 40 days.
- AC-10 locks in acceptance of inconsistent chronology (false): the spec explicitly requires clamping `finalDaysActive` to >= 0.
- `finalHealthScore` is recomputed instead of snapshotted, so the retired job's stored score can diverge (low): no consumer reads the retired job's score; the event value at `restringDate` is the meaningful one.
- Racquet pointing at an already-inactive job is unrecoverable (false): the transaction keeps the pointer and `isActive` in sync, and no code path was shown that produces that state.
- `oldJob` ownership/racquet not re-checked (false): `oldJob` comes from the already ownership-checked racquet's own `activeStringJob` relation.
- `keepSame: true` silently ignores specs, and `keepSame: false` with no specs behaves as keep-same (low): both fallbacks are spec-defined (epic signature defaults `keepSame = true`; the I/O matrix specifies fallbacks), and the fix would add rejection branches.
- Blank or whitespace brand/model, and invalid `tension` (NaN, zero, negative), accepted (low): affects only the caller's own data, and the fix adds guards.
- No idempotency key for retries (low): speculative and outside the spec; the double-submit case is covered by the concurrency patch.
- `getRestringHistory` is unbounded and has no `id` tie-breaker (low): per-racquet restring counts are small and the spec requires neither.
- Missing index on `stringJobId` and no composite `(racquetId, restringDate)` index (low): the spine and epic specify only the `userId` and `racquetId` indexes; negligible at this data size.
- `ON DELETE CASCADE` on `restring_event` FKs deviates from the spine (low): the `racquetId` cascade is required because `deleteRacquet` exists (AC-9), and no code path deletes a single `StringJob`, so the `stringJobId` cascade has no effect.
- `restrung` broadcast payload is thin and a failed or crashed post is only logged (false): the payload matches the spec exactly, and the spec requires publishing after commit.
- AC-1 test only counts FKs and contains `expect(RestringEvent, isNotNull)` (low): a schema smoke test; the nit does not hide a defect.
- Fixed `Future.delayed` sleeps in AC-2 (low): a theoretical flake risk; the fix is a stream-test rewrite out of proportion to the risk.
- Duplicate include in the `activeStringJob == null` fallback lookup (low): cosmetic.
- Refactor, feature and migration are in one change, against the atomic-commit rule (low): a commit-hygiene note, not a code defect; nothing is committed yet.

#### Generated-code pass (2026-10-05)

Checked by cross-referencing instead of line-by-line reading, because the files are tool output. Clean review, no findings.

- `migration.json` has one `createTable` action and no warnings.
- `migration.sql` and `definition.sql` define the same `restring_event` table, the two indexes and the two FKs. `definition.json` agrees (12 columns, none nullable).
- The diff of `definition.sql` against the previous migration contains only `restring_event` additions and the version bump. No other table changed.
- `migration_registry.txt` lists the new version last.
- Client and server `RestringEvent` have the same fields. The server-only `updateTable` is expected.
- The server dispatcher, client stub and test tools all carry the same ten `restringRacquet` parameters, and the `getRestringHistory` wiring and protocol registration are present on both sides. The signature is unchanged by the review patches, so regeneration was not needed.
- Not run: `serverpod generate` and `create_migration` were not re-run to confirm a byte-identical regeneration. Run `serverpod start` and watch for a "no changes" generation to confirm.
