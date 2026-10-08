---
workflowStatus: 'completed'
totalSteps: 5
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
nextStep: ''
lastSaved: '2026-10-08'
inputDocuments:
  - _bmad-output/planning-artifacts/epics.md
  - _bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/ARCHITECTURE-SPINE.md
  - _bmad-output/implementation-artifacts/sprint-status.yaml
  - _bmad-output/implementation-artifacts/deferred-work.md
  - string_theory_server/lib/src/models/{racquet,string_job,session_log,restring_event,bag_stream_message}.spy.yaml
  - string_theory_server/lib/src/util/tenant_resolver.dart
  - string_theory_server/lib/src/future_calls/daily_decay_future_call.dart
  - string_theory_server/lib/src/endpoints/session_endpoint.dart
  - string_theory_server/lib/src/messaging/bag_channels.dart
  - string_theory_flutter/lib/bloc/bag_bloc.dart
  - .github/workflows/tests.yml
  - serverpod_auth_core_server-4.0.3/lib/src/auth_user/util/authentication_info_extension.dart
  - knowledge/risk-governance.md
  - knowledge/probability-impact.md
  - knowledge/test-levels-framework.md
  - knowledge/test-priorities-matrix.md
  - knowledge/nfr-criteria.md
  - knowledge/playwright-cli.md
---

# Test Design: Epic 6 - Technical Debt, Concurrency & Production Polish

**Date:** 2026-10-08
**Author:** Francesco
**Status:** Draft

---

## Executive Summary

**Scope:** Epic-level test design for Epic 6 (Stories 6.1–6.5, TD-1..TD-14), weighted toward Story 6.3.

**Risk Summary:**

- Total risks identified: 15
- High-priority risks (≥6): 5 (one scored 9 → **BLOCK** until mitigated)
- Critical categories: DATA (tenant re-keying), SEC (tenant isolation), OPS (advisory lock lifecycle)

**Headline finding:** today's integer `userId` is a **lossy** projection of the auth UUID
(`resolveUserIdFromIdentifier` reduces the 128-bit UUID modulo int64 max). The integer cannot be turned
back into a UUID on its own. Existing rows can only be re-keyed by recomputing that same projection for
every `serverpod_auth_core_user.id` in SQL and joining on it. A generated `int → uuid` migration will either
fail or drop data, and `dart test` will never notice, because the test database is created from
`definition.sql` and never runs `migration.sql`.

**Coverage Summary:**

- P0 scenarios: 22 (~35–50 hours)
- P1 scenarios: 31 (~25–35 hours)
- P2/P3 scenarios: 13 (~6–10 hours)
- **Total effort**: ~66–95 hours (~8–12 days)

**Sequencing recommendation:** implement **6.3 first**. It changes the `userId` type in every generated
client model, which breaks fixtures in 14 Flutter test files and every server integration suite. Story 6.1,
6.2 and 6.4 tests written before it would need rework.

---

## Not in Scope

| Item | Reasoning | Mitigation |
| --- | --- | --- |
| **Load/perf testing of the decay cron** | No throughput threshold in Epic 6; paging already shipped in the Epic 2 retro work | Existing paging tests in `daily_decay_future_call_test.dart` stay as regression |
| **Real HealthKit / Health Connect devices** | Plugin behaviour can't run in CI | `NativeHealthSyncService` tested against a fake plugin + fake clock; manual device check before release |
| **Browser exploration (playwright-cli)** | Flutter renders to canvas; no DOM snapshot to drive | Patrol + `flutter_driver` cover UI flows |
| **Rate limiting of `triggerDailyDecayNow`** | Listed in `deferred-work.md`, not in Epic 6 ACs | Advisory lock (TD-7) bounds concurrent execution |

---

## Risk Assessment

### High-Priority Risks (Score ≥6)

| Risk ID | Category | Description | Probability | Impact | Score | Mitigation | Owner | Timeline |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R-001 | DATA | TD-10 migrates `userId` int→`UuidValue` on 4 tables. The int is `UUID mod 0x7FFF…FFFF` (`tenant_resolver.dart`), so it can't be cast back. A generated type change needs `--force` and drops or fails on existing rows, so every guest loses their bag | 3 | 3 | **9** | Hand-edited `migration.sql`: add `userUuid uuid`, backfill by joining `serverpod_auth_core_user` on the SQL port of the projection, assert zero NULLs, drop old column, rename. Keep the end schema identical to `definition.sql`. **Or** record an explicit decision to discard guest data | Dev (6.3) | Before 6.3 merge |
| R-002 | SEC | Converting ~60 `userId` call sites (`bag_endpoint.dart`, `session_endpoint.dart`, `BagChannels.forUser(int)`) risks one missed filter or a channel-name mismatch, which leaks or misroutes another tenant's bag | 2 | 3 | 6 | Two-UUID-tenant isolation suite over every endpoint + stream, written red before the type change | Dev (6.3) | With 6.3 |
| R-003 | TECH | `authUserId` is `UuidValue.withValidation(userIdentifier)`. Every server fixture uses numeric identifiers (`'101'`, `'1'`, `'3201'`), which will throw `FormatException` and surface as a 500 instead of a 401. Whole suites go red for the wrong reason | 3 | 2 | 6 | Shared test identity helper (fixed UUID constants per tenant); TenantResolver maps a missing/invalid identifier to `BagException(401)` | Dev (6.3) | First commit of 6.3 |
| R-005 | DATA | TD-8 conditional write (`WHERE id=@jobId AND "totalCourtHours"=@read`) can't be expressed through the current batch `StringJob.db.update(columns: …)`. A naive rewrite either keeps overwriting (lost race) or skips every row | 2 | 3 | 6 | Deterministic race test with a seam between page read and write; assert skip count and preserved hours | Dev (6.3) | With 6.3 |
| R-006 | OPS | TD-7 uses session-level `pg_try_advisory_lock`. Serverpod pools connections, so the unlock can run on a different connection than the lock. The lock then leaks, and decay never runs again until restart | 2 | 3 | 6 | Prefer `pg_try_advisory_xact_lock` inside one transaction, or pin one connection. Test that a second run after success **and** after an exception acquires the lock | Dev (6.3) | With 6.3 |

### Medium-Priority Risks (Score 3-4)

| Risk ID | Category | Description | Probability | Impact | Score | Mitigation | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R-004 | DATA | Composite unique `(userId, externalWorkoutId)` changes dedup semantics: the cross-tenant 409 at `session_endpoint.dart:118` disappears, and the same workout ID becomes valid for two tenants | 2 | 2 | 4 | Integration tests for same-tenant idempotency + cross-tenant independence; remove the dead 409 branch | Dev |
| R-008 | BUS | New `logSession` bounds (`1..360` min, `startTime ≤ now+5m`). A replayed offline session rejected with 400 could loop forever in the offline queue | 2 | 2 | 4 | Boundary tests server-side; queue drops on a 4xx validation error | Dev |
| R-009 | BUS | TD-1/TD-2: keeping optimistic state after a failed reload can diverge from the server; pull-to-refresh that never resolves hangs the spinner | 2 | 2 | 4 | bloc_test per mutation + widget test with 8 s timeout via fake async | Dev |
| R-010 | SEC | TD-3: `bag_bloc.dart:565` enqueues on any failure, so 401s are queued as "saved offline" forever | 2 | 2 | 4 | bloc_test: 401 → re-auth, not queued, no toast | Dev |
| R-011 | DATA | TD-5/TD-6: FIFO buffer + persisted processed IDs. Marking an ID processed before assignment completes silently loses a match | 2 | 2 | 4 | Unit tests on mark-after-assign/dismiss; restart test | Dev |
| R-012 | TECH | TD-4: `resumed` sync with 60 s cooldown and 5 s timeout; `_isSyncing` stuck true blocks all future syncs | 2 | 2 | 4 | Fake clock + hanging plugin fake; assert `finally` reset | Dev |
| R-015 | TECH | Generated client models change `userId` type; 14 Flutter test files construct models with `userId: <int>` | 3 | 1 | 3 | Shared Flutter fixture factory updated in the same commit as 6.3 | Dev |

### Low-Priority Risks (Score 1-2)

| Risk ID | Category | Description | Probability | Impact | Score | Action |
| --- | --- | --- | --- | --- | --- | --- |
| R-007 | BUS | TD-9 ≥1% broadcast; scores are ints, so any change broadcasts; wrong channel would hit R-002 | 1 | 2 | 2 | Document; covered by broadcast tests |
| R-013 | OPS | TD-13/14: `SERVERPOD_PASSWORD_*` only set on the server job in `tests.yml`; auth test waits on live sockets | 1 | 2 | 2 | Document; Epic 1.5 retro items close here |
| R-014 | BUS | TD-11/12: Sessions screen + preset relocation regress add-racquet defaults or navigation | 1 | 2 | 2 | Document; widget tests |

### Residual Risk

After mitigation: R-001 drops to 3 (P1×I3) with the harness green; R-002, R-005 and R-006 drop to 3 with their tests green; R-003 drops to 2. The remaining exposure is real-device health plugin behaviour (6.2), which is covered by a manual check only.

### Risk Category Legend

- **TECH**: Technical/Architecture (flaws, integration, scalability)
- **SEC**: Security (access controls, auth, data exposure)
- **PERF**: Performance (SLA violations, degradation, resource limits)
- **DATA**: Data Integrity (loss, corruption, inconsistency)
- **BUS**: Business Impact (UX harm, logic errors, revenue)
- **OPS**: Operations (deployment, config, monitoring)

---

## NFR Planning

| NFR Category | Requirement / Threshold | Risk Link | Planned Validation | Evidence Needed |
| --- | --- | --- | --- | --- |
| Security | Zero cross-tenant reads/writes/stream messages (multi-tenant rule in AGENTS.md) | R-002, R-010 | Two-tenant integration suite, stream isolation | `dart test` report |
| Data integrity | 100% of pre-migration rows keep their owner after migration; 0 NULL `userId` | R-001 | Migration harness on a seeded prior-schema DB | Harness log + row-count diff |
| Reliability | Exactly one concurrent decay run; dev trigger 409 when busy (TD-7); sync timeout 5 s, cooldown 60 s (TD-4); refresh timeout 8 s (TD-2) | R-006, R-012, R-009 | Integration + fake-clock unit tests | Test reports |
| Maintainability | CI deterministic, no live-socket waits (TD-14); scoped drift check (TD-13) | R-013 | CI run on PR | GitHub Actions logs |

**Unknown thresholds:** max acceptable broadcast volume per decay run (TD-9) — not specified; treat as N/A for this epic.

---

## Entry Criteria

- [ ] **Decision recorded for R-001:** backfill existing tenant rows, or wipe guest data (see Assumptions)
- [ ] Shared UUID test-identity helper exists on server and Flutter sides (R-003, R-015)
- [ ] Migration harness can boot the embedded PostgreSQL at migration `20261005101241116` and apply the new `migration.sql`
- [ ] Epic 5 suites green on `main`

## Exit Criteria

- [ ] All P0 tests passing
- [ ] All P1 tests passing (or failures triaged)
- [ ] R-001 score reduced below 6 (harness green) or a signed waiver for data discard
- [ ] Post-migration schema diff vs `definition.sql` is empty
- [ ] Epic 1.5 open retro items closed by 6.5

---

## Test Coverage Plan

### P0 (Critical)

| Requirement | Test Level | Risk Link | Test Count | Owner | Notes |
| --- | --- | --- | --- | --- | --- |
| 6.3 Migration preserves ownership: seed rows under projected ints for 3 known auth UUIDs (+1 orphan int with no auth user) → apply `migration.sql` → each row's `userId` equals its UUID; counts unchanged; orphan handled per decision | Integration (DB script) | R-001 | 3 | Dev | **Not reachable from `dart test`** (test DB is built from `definition.sql`). Needs its own script/CI job |
| 6.3 Post-migration schema equals `definition.sql` | Integration (DB script) | R-001 | 1 | Dev | `pg_dump --schema-only` diff |
| 6.3 Tenant isolation, two UUID tenants: `getVirtualBag`, `addRacquet`, `setPrimaryRacquet`, `deleteRacquet`, `restringRacquet`, `logSession`, `getSessions`, `bagUpdates` | API (endpoint integration) | R-002 | 8 | Dev | Many exist with int fixtures; convert, don't duplicate |
| 6.3 TenantResolver: valid identifier → `UuidValue`; unauthenticated → 401; non-UUID identifier → 401 (not 500) | Unit + API | R-002, R-003 | 3 | Dev | Replaces the 21 hash/modulus unit tests, which get deleted |
| 6.3 Advisory lock: concurrent runs → one executes; dev trigger 409; cron returns quietly; lock re-acquirable after success and after a thrown error | API (integration) | R-006 | 4 | Dev | Concurrency via two sessions; error path via a bad row |
| 6.3 Optimistic write: session logged between read and write → job skipped, hours preserved; untouched jobs still updated; skipped job decays next run | API (integration) | R-005 | 3 | Dev | Needs a test seam (callback after page read) |

**Total P0**: 22 tests, ~35–50 hours

### P1 (High)

| Requirement | Test Level | Risk Link | Test Count | Owner | Notes |
| --- | --- | --- | --- | --- | --- |
| 6.3 Composite unique index: same tenant duplicate → original row returned; same `externalWorkoutId` for two tenants → both succeed; index exists | API | R-004 | 3 | Dev | |
| 6.3 `logSession` bounds: duration 0 / 1 / 360 / 361; startTime now+5m accepted, now+6m rejected | API | R-008 | 6 | Dev | Use injected clock; avoid wall-clock flake |
| 6.1/6.3 Offline queue drops a session rejected with a 4xx validation error | Unit (Flutter) | R-008 | 1 | Dev | |
| 6.3 Decay broadcast: score change publishes to owner's channel only; no change → no message | API (stream) | R-007, R-002 | 3 | Dev | Reuse `bag_stream_test.dart` patterns |
| 6.1 Mutation OK + reload fails → no error, state kept, resync scheduled (add/delete/setPrimary/fastForward) | Unit (bloc_test) | R-009 | 4 | Dev | |
| 6.1 Pull-to-refresh awaits `BagLoaded`/`BagError`; 8 s timeout releases spinner | Component (widget) | R-009 | 3 | Dev | `fakeAsync` |
| 6.1 401 on `logSession` → re-auth prompt; not queued; no "saved offline" toast | Unit (bloc_test) | R-010 | 2 | Dev | |
| 6.2 `resumed` sync gated at 60 s; 5 s timeout; `_isSyncing` reset in `finally`; concurrent call guard | Unit | R-012 | 4 | Dev | Fake clock + hanging plugin fake |
| 6.2 FIFO: batch of 3 presented in order; arrival while sheet open buffered; dismiss advances | Unit (bloc) + Component | R-011 | 3 | Dev | |
| 6.2 Processed IDs persisted only after assign/dismiss; cold start doesn't re-alert | Unit | R-011 | 2 | Dev | Fake key-value store |

**Total P1**: 31 tests, ~25–35 hours

### P2 (Medium)

| Requirement | Test Level | Risk Link | Test Count | Owner | Notes |
| --- | --- | --- | --- | --- | --- |
| 6.2 Missing/denied health permission shows guidance, not an empty list | Component | R-011 | 2 | Dev | |
| 6.4 `SessionsScreen`: chronological list with date/duration/racquet/hours; empty state; `[+ Log Session]`; reachable from bottom nav, rail, drawer | Component | R-014 | 4 | Dev | Replaces `SessionsPlaceholder` tests |
| 6.4 `RacquetPreset` / `StringCategoryDefaults` in domain; add-racquet modal still applies defaults | Unit | R-014 | 2 | Dev | Existing `add_racquet_modal_test.dart` is the regression |
| 6.5 `auth_service_test.dart` fake status caller: valid session and guest fallback | Unit | R-013 | 2 | Dev | No network |
| 6.3 Index on `userId` present for all 4 tables | Integration | R-001 | 1 | Dev | Can fold into schema diff |

**Total P2**: 11 tests, ~5–8 hours

### P3 (Low)

| Requirement | Test Level | Risk Link | Test Count | Owner | Notes |
| --- | --- | --- | --- | --- | --- |
| 6.5 CI secret parity across jobs; drift check scoped per package | CI | R-013 | 1 | Dev | Verified by a green PR run |
| 6.4 Patrol: guest launch → log session → Sessions tab shows it | E2E | R-014 | 1 | Dev | Extend `app_patrol_test.dart` |

**Total P3**: 2 tests, ~1–2 hours

---

## Execution Strategy

- **Order within a run:** analyze/format smoke → migration harness + server P0 → P1 → P2/P3 → Patrol.
- **Pull request:** all server `dart test` suites (embedded PostgreSQL), all Flutter unit/widget/bloc tests, the Patrol app test, and the **migration harness** (R-001). It's one extra job of a few minutes and the only guard on `migration.sql`, so it should not be nightly.
- **Nightly:** none needed. The concurrency tests are deterministic via seams and don't need repetition.
- **Weekly:** manual device check of HealthKit / Health Connect lifecycle sync (6.2).

---

## Resource Estimates

| Priority | Count | Hours/Test | Total Hours | Notes |
| --- | --- | --- | --- | --- |
| P0 | 22 | ~1.5–2.5 | ~35–50 | Migration harness is most of it |
| P1 | 31 | ~0.8–1.1 | ~25–35 | |
| P2 | 11 | ~0.5–0.7 | ~5–8 | |
| P3 | 2 | ~0.5–1 | ~1–2 | |
| **Total** | **66** | **-** | **~66–95** | **~8–12 days** |

### Prerequisites

**Test Data:**

- `TestTenants` constants (server + Flutter): fixed UUIDs for tenants A/B and a matching `AuthenticationOverride` builder
- Projection helper in SQL and Dart, used both by the migration and to seed the harness with "old" int keys

**Tooling:**

- Migration harness script: embedded PostgreSQL → apply migrations up to `20261005101241116` → seed → apply new migration → assert
- Test seam on `DailyDecayService` (post-read callback) for the race test
- `fakeAsync` / injectable clock for 6.1 and 6.2

**Environment:**

- `config/test.yaml` embedded DB (existing)
- `SERVERPOD_PASSWORD_*` available to every job that needs them (6.5)

---

## Quality Gate Criteria

### Pass/Fail Thresholds

- **P0 pass rate**: 100%
- **P1 pass rate**: ≥95% (waivers required)
- **P2/P3 pass rate**: ≥90% (informational)
- **High-risk mitigations**: 100% complete or approved waivers

### Coverage Targets

- **Tenant-scoped endpoints with isolation tests**: 100%
- **Security scenarios**: 100%
- **Business logic**: ≥70%

### Non-Negotiable Requirements

- [ ] All P0 tests pass
- [ ] R-001 harness green, or a written data-discard decision
- [ ] SEC isolation tests pass 100%
- [ ] Planned NFR evidence exists or `nfr-assess` has documented CONCERNS/waivers

---

## Mitigation Plans

### R-001: Lossy int → UUID tenant re-keying (Score: 9)

**Mitigation Strategy:** Edit the generated `migration.sql` (the AGENTS.md exception for data-preserving migrations):
1. Add a nullable `uuid` column per table.
2. Backfill: `UPDATE racquet r SET new_id = u.id FROM serverpod_auth_core_user u WHERE r."userId" = projection(u.id)`. `projection` is a temporary PL/pgSQL function that ports `resolveUserIdFromIdentifier`'s hex branch (strip `-`, parse hex as numeric, `mod 9223372036854775807`).
3. Handle orphans (rows whose int matches no auth user, e.g. test data) per the recorded decision.
4. Set the column NOT NULL, drop the old column, rename, recreate indexes. Drop the temp function.
5. Check that the resulting schema is byte-identical to `definition.sql`.

**Owner:** Dev · **Timeline:** before the 6.3 merge · **Status:** Planned
**Verification:** P0 migration harness (4 tests) + schema diff.

### R-002: Tenant isolation regression (Score: 6)

**Mitigation Strategy:** write the two-tenant suite against UUID fixtures first (red), then change types. Change `BagChannels.forUser` to take `UuidValue` so the compiler finds every caller.
**Owner:** Dev · **Status:** Planned · **Verification:** 8 isolation tests green.

### R-003: Numeric fixture identifiers throw (Score: 6)

**Mitigation Strategy:** introduce `TestTenants` before touching models; TenantResolver catches `FormatException` → 401.
**Owner:** Dev · **Status:** Planned · **Verification:** resolver unit tests; all existing suites green on UUID fixtures.

### R-005: Optimistic write correctness (Score: 6)

**Mitigation Strategy:** per-row conditional `UPDATE … WHERE id = $1 AND "totalCourtHours" = $2` (unsafe query with parameters) inside the page loop. Count the affected rows to report skips.
**Owner:** Dev · **Status:** Planned · **Verification:** 3 race tests.

### R-006: Advisory lock leak under pooling (Score: 6)

**Mitigation Strategy:** use `pg_try_advisory_xact_lock(7421893)` in a transaction that wraps the run, or document why session-level is safe. Either way, test re-acquisition after an error.
**Owner:** Dev · **Status:** Planned · **Verification:** 4 lock tests.

---

## Assumptions and Dependencies

### Assumptions

1. Every existing tenant int was produced from a real `serverpod_auth_core_user` UUID via the hex branch. Only test data used numeric identifiers (stated in the `tenant_resolver.dart` doc comment).
2. Discarding guest data is acceptable **only if** explicitly decided. This plan does not assume it. **Open question for Francesco.**
3. Serverpod's `unsafeQuery`/`unsafeExecute` is acceptable for the advisory lock and the conditional write.

### Dependencies

1. 6.3 lands before 6.1/6.2/6.4 test work (fixture churn).
2. The migration harness job is added to `tests.yml` alongside 6.5's CI changes.

### Risks to Plan

- **Risk**: the migration harness is harder than estimated (embedded PG lifecycle outside `serverpod_test`)
  - **Impact**: P0 slips by 1–2 days
  - **Contingency**: run the harness against the docker-compose Postgres locally and in CI

---

## Follow-on Workflows (Manual)

- Run `/bmad-testarch-atdd` to generate failing P0 tests for 6.3 (separate workflow; not auto-run).
- Run `/bmad-testarch-automate` for broader coverage once implementation exists.

---

## Approval

**Test Design Approved By:**

- [ ] Tech Lead: Francesco Date: ____

---

## Interworking & Regression

| Service/Component | Impact | Regression Scope |
| --- | --- | --- |
| **BagEndpoint / SessionEndpoint** | `userId` type, isolation, validation | `bag_endpoint_test.dart`, `session_endpoint_test.dart` |
| **bagUpdates stream** | Channel key type, new decay event | `bag_stream_test.dart` |
| **DailyDecayService** | Lock, conditional write, broadcast | `daily_decay_future_call_test.dart` |
| **Generated client / Flutter models** | `userId` type | 14 Flutter test files using `userId` |
| **Offline queue** | 401 + 4xx handling | `offline_session_queue_test.dart`, `bag_bloc_test.dart` |
| **Navigation** | Sessions tab | `bag_bottom_nav_test.dart`, `bag_navigation_rail_test.dart`, `bag_navigation_drawer_test.dart` |

---

## Appendix

### Knowledge Base References

- `risk-governance.md` - Risk classification framework
- `probability-impact.md` - Risk scoring methodology
- `test-levels-framework.md` - Test level selection
- `test-priorities-matrix.md` - P0-P3 prioritization
- `nfr-criteria.md` - NFR planning

### Related Documents

- Epic: `_bmad-output/planning-artifacts/epics.md` (Epic 6)
- Architecture: `_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/ARCHITECTURE-SPINE.md`
- Deferred work: `_bmad-output/implementation-artifacts/deferred-work.md`

---

**Generated by**: BMad TEA Agent - Test Architect Module
**Workflow**: `bmad-testarch-test-design`
**Version**: 4.0 (BMad v6)
