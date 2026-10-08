---
title: 'Story 6.3: Native UUID Tenant Migration, Backend Concurrency & Live Updates'
type: 'feature'
created: '2026-10-08'
status: 'ready-for-dev'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/test-artifacts/atdd-checklist-6-3-native-uuid-tenant-migration-backend-concurrency-live-update.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-6-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Tenant `userId` is a hashed `int` derived from the auth UUID, workout idempotency is global across tenants, and the decay worker can run twice at once, overwrite scores a user session just wrote, and never tells live clients about decay. `logSession` also accepts absurd durations and future start times.

**Approach:** Drive the 7 skipped ATDD scaffolds green in the checklist's activation order: first move existing tests to `TestTenants` UUID identities, then retype `userId` to `UuidValue` everywhere (migration empties the four tenant tables), then add session bounds, the advisory lock, conditional decay writes, and decay broadcasts.

## Boundaries & Constraints

**Always:** Follow the checklist's activation order, one TDD step per commit (`test(...)` then `feat(...)`), un-skipping only the scaffold being implemented. Every endpoint keeps filtering by the resolved tenant. Publishing never fails a request or a decay run. `main` stays green after every commit.

**Decisions (2026-10-08):** Full spec kept despite size. Migrations go through the `serverpod` MCP (`create_migration`, `apply_migrations`) against the user's running `serverpod start`; applying empties dev tenant data. The R-001 migration verification (populated DB at `20261005101241116` → apply → 4 tables empty, auth rows kept, schema diff vs `definition.sql` empty) is built in this story as a script plus a CI job.

**Never:** Edit generated code (`lib/src/generated/`, `string_theory_client`). Change the end schema of `migration.sql` away from `definition.sql`. Touch `serverpod_auth_*` tables. Hold row locks for a whole decay run.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Non-UUID identity | auth identifier `'101'` | `resolveUserId` rejects | `BagException(401)`, not a 500 `FormatException` |
| Same workout, two tenants | A and B log `externalWorkoutId` X | both stored | – |
| Same workout, same tenant | A logs X twice | original row returned, hours counted once | – |
| Duration bounds | 0 / 1 / 360 / 361 min | 1 and 360 accepted | 0, 361 → `BagException(400)` |
| Future start | now+4m / now+6m | +4m accepted | +6m → `BagException(400)` |
| Decay lock busy | lock `7421893` held elsewhere | dev trigger rejects; cron returns quietly, 0 updates | trigger → `BagException(409)` |
| Lock after failure | previous run threw | next run acquires lock | – |
| Concurrent session | job's `totalCourtHours` changed after page read | job skipped, not counted, session's score kept; decays next run | – |
| Score changes | decay moves score by ≥1 | `BagStreamMessage` on owner's channel only | publish failure logged |
| Score unchanged | – | no message | – |

</frozen-after-approval>

## Code Map

- `string_theory_server/test/integration/support/test_tenants.dart` -- `TestTenants.a/.b`, `auth()`, `sessionLogFor()`; extend with more fixed UUIDs, `UuidValue` getters, and swap the `userId: 0` placeholder to `UuidValue.nil`.
- `string_theory_server/test/integration/{bag_endpoint,bag_stream,session_endpoint,daily_decay_future_call,tenant_resolver}_test.dart` -- numeric identifiers `'1'`,`'2'`,`'101'`,`'3101'`,`'3201'` and `userId: <int>` literals/assertions to convert. Rollback-disabled groups used distinct ids on purpose; keep them distinct.
- `string_theory_server/test/integration/{tenant_schema,decay_concurrency}_test.dart` -- the AC-1/2/4/5/6 scaffolds.
- `string_theory_server/test/unit/util/tenant_resolver_test.dart` -- hash/modulus tests only; delete the file.
- `string_theory_server/lib/src/models/{racquet,string_job,session_log,restring_event}.spy.yaml` -- `userId: int` → `UuidValue`; `session_log_external_id_idx` global unique → composite unique on `userId, externalWorkoutId`.
- `string_theory_server/lib/src/util/tenant_resolver.dart` -- return `authInfo.authUserId` (extension in `serverpod_auth_idp_server/core.dart`, throws `FormatException` on non-UUID); delete `resolveUserIdFromIdentifier`.
- `string_theory_server/lib/src/messaging/bag_channels.dart` -- `forUser(UuidValue)`; add a `decayed` event type.
- `string_theory_server/lib/src/endpoints/session_endpoint.dart` -- bounds check next to the existing `<= 0` check; `_findByExternalWorkoutId` filters by `userId`, 409 branch removed; unique-violation catch matches the new index name.
- `string_theory_server/lib/src/endpoints/bag_endpoint.dart` -- `triggerDailyDecayNow` maps a busy lock to 409; `int userId` parameters retype.
- `string_theory_server/lib/src/future_calls/daily_decay_future_call.dart` -- keyset pagination + `afterPageRead` seam (keep); `_updatePage` batch write and row-by-row fallback (keep the shape, make conditional); cron `execute` swallows busy lock.
- `string_theory_flutter/lib/bloc/bag_bloc.dart:480` -- `SessionLog(userId: 0, …)` placeholder → `UuidValue.nil`. `_onBagStreamReceived` already applies any event type by `racquetId`, so decay broadcasts show live with no client change.
- `string_theory_flutter/test/**` (13 files) -- `userId: 0|1,` fixtures → `UuidValue.nil`; no test asserts on `userId`.

## Tasks & Acceptance

**Execution:**
- [ ] `test/integration/support/test_tenants.dart` + 5 integration test files -- replace numeric identities with `TestTenants` (a=`'1'`, b=`'2'`, plus new c/d/e for `'101'`/`'3101'`/`'3201'`); route direct-insert `userId` literals through the helper -- fixtures must survive `UuidValue.withValidation` (R-003).
- [ ] 4 `.spy.yaml` models, `tenant_resolver.dart`, `bag_channels.dart`, both endpoints, decay service signatures, new migration (`TRUNCATE racquet, string_job, session_log, restring_event CASCADE` hand-inserted before the column changes), Flutter placeholder + fixtures -- un-skip AC-1/2/3; delete the unit resolver test and golden test; replace the cross-tenant 409 tests (session_endpoint, bag_stream) and the old index-name check with the new behavior.
- [ ] `session_endpoint.dart` -- duration and start-time bounds; un-skip AC-7 and add the matrix boundaries.
- [ ] `daily_decay_future_call.dart`, `bag_endpoint.dart` -- advisory lock; un-skip AC-4, add cron-quiet and re-acquire-after-success/throw tests.
- [ ] `daily_decay_future_call.dart` -- conditional writes; un-skip AC-5, add untouched-jobs-still-updated and next-run-decays tests.
- [ ] `daily_decay_future_call.dart` -- broadcast written changes; un-skip AC-6, add no-change and tenant-B-silent tests.
- [ ] `string_theory_server/tool/verify_uuid_migration.sh` + `.github/workflows/` job -- seed a DB at `20261005101241116`, apply migrations, assert 4 tenant tables empty, auth rows kept, `pg_dump --schema-only` matches `definition.sql` (R-001).

**Acceptance Criteria:**
- Given the migrated schema, when the catalog is read, then `userId` is `uuid` and indexed on all 4 tables and `session_log` has a unique index on `(userId, externalWorkoutId)`.
- Given an authenticated UUID session, when `resolveUserId` runs, then it equals `session.authenticated!.authUserId`.
- Given all 7 scaffolds un-skipped, when `dart test` runs in `string_theory_server`, then 0 tests are skipped or failing; `flutter test` and `flutter analyze --fatal-infos` pass in `string_theory_flutter`.

## Implementation Notes

## Spec Change Log

## Review Triage Log

## Design Notes

**Lock without long row locks:** Serverpod pools connections, so a session-level `pg_advisory_lock`/`unlock` pair can land on different connections (R-006). Instead open one `session.db.transaction`, take `pg_try_advisory_xact_lock(7421893)` on it, and run the pages *outside* that transaction (autocommit per page). The lock lives exactly as long as the idle transaction, is released by commit or rollback (including on throw), and user sessions never wait on decay row locks. Busy → throw a `DecayRunInProgressException`; the trigger maps it to `BagException(409)`, the FutureCall logs and returns.

**Conditional batch write:** one raw statement per page, returning written ids:

```sql
UPDATE string_job AS j SET "currentHealthScore" = v.score
FROM unnest(@ids::bigint[], @scores::bigint[], @hours::double precision[]) AS v(id, score, hours)
WHERE j.id = v.id AND j."totalCourtHours" = v.hours
RETURNING j.id
```

The row-by-row fallback uses `StringJob.db.updateWhere` with the same `id` + `totalCourtHours` predicate. Counts and broadcasts use only returned ids.

**≥1% delta:** health scores are integer percent, so any written change is ≥1; broadcast every returned job with `eventType: BagChannels.decayed`.

**Ordering note:** the Flutter fixture update can't land with step 1 (it won't compile until the client `userId` type changes), so it lands with the model commit.

## Verification

**Commands:**
- `dart analyze` and `dart format --set-exit-if-changed .` at repo root -- expected: clean
- `dart test` in `string_theory_server` after each task -- expected: 0 failed; skips drop by the scaffolds un-skipped so far
- `flutter test` and `flutter analyze --fatal-infos` in `string_theory_flutter` -- expected: pass
- `git diff --exit-code string_theory_client string_theory_server/lib/src/generated` after `serverpod generate` -- expected: no drift
