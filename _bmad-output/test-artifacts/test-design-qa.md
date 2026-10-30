---
workflowStatus: 'completed'
totalSteps: 5
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
nextStep: ''
lastSaved: '2026-10-30'
workflowType: 'testarch-test-design'
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/prd.md
  - _bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/ARCHITECTURE-SPINE.md
  - _bmad-output/planning-artifacts/epics.md
  - _bmad-output/test-artifacts/test-design-architecture.md
---

# Test Design for QA: String Theory v1 (Firebase)

**Purpose:** The test execution recipe: what to test, at which level, how it runs, and what it depends on.

**Date:** 2026-10-30
**Author:** Murat (TEA) for Francesco
**Status:** Draft
**Project:** string_theory

**Related:** See `test-design-architecture.md` for testability concerns, decisions D-1 to D-3 (decided 2026-10-30) and the risk mitigation plans.

---

## Executive Summary

**Scope:** All v1 stories (Epics 1–5): Google auth and the user document, the decay engine, live bag, add/edit/primary/delete racquet, atomic offline session logging, restring and history, account deletion and purge, Hosting and privacy page, telemetry and Remote Config, store compliance.

**Risk Summary:**

- Total risks: 18 (5 high-priority score ≥ 6, 9 medium, 4 low)
- Critical categories: SEC (rules isolation, deletion) and DATA (schema drift, offline writes)

**Coverage Summary:**

- P0: 18 scenarios (rules, offline integrity, deletion, flavor guard, engine math, auth gate)
- P1: 21 scenarios (mappers, BLoCs, core widgets, CI checks, accessibility)
- P2: 8 scenarios (secondary UI, performance measurements, ops)
- P3: 1 scenario (post-launch rules compatibility)
- **Total:** 48 scenarios, about 80–125 hours, or about 2–3 weeks for one developer, spread across stories

**Test levels used:** UNIT (pure Dart), BLOC (`bloc_test` + `mocktail`), WIDGET (`flutter test`), REPO (`fake_cloud_firestore`), RULES (`@firebase/rules-unit-testing` on the Firestore emulator; this system's API layer), EMU (Dart client against the emulators with the network toggled), CI (static or config check), MANUAL (device, console or screen-reader run, recorded in the story's verification notes).

---

## Not in Scope

| Item | Reasoning | Mitigation |
| --- | --- | --- |
| **Automated E2E (Patrol)** | Retired for v1 (PRD non-goal, AGENTS.md) | Manual journeys on the internal-track build (5.8) and in the screen-reader pass (5.6) |
| **Serverpod server and client tests** | Packages removed in Story 1.7 | None needed |
| **Load, stress and soak testing** | No throughput target; Firestore is managed and per-user scoped | Rules size bounds (NFR-7) and budget alerts (5.7) |
| **iOS and desktop targets** | PRD non-goal | None |
| **Firebase SDK internals** (atomicity of `WriteBatch`, persistence engine) | Third-party guarantees (test-levels anti-pattern) | EMU tests prove that our use of them queues and syncs |
| **Web crash reporting** | Crashlytics has no web support (PRD SM-2) | Accepted trade-off |
| **Consent banner behavior** | Undecided (Story 5.5); web Analytics stays disabled until then | Story 5.5 adds its own tests when decided |

---

## Dependencies & Test Blockers

### Architecture Dependencies (Pre-Implementation)

**Source:** the Architecture doc's Quick Guide.

1. **D-1: Offline tests in CI. Decided.** Story 3.1 adds the headless-Chrome emulator job.
   - P0-008/P0-009 gate every PR.
2. **Pure mapper signature and commit-error handler.** Dev, Stories 2.2 and 3.3.
   - Needed for P1-001 and P0-010 to be deterministic without the emulator.
3. **Injected auth SDKs and a pure `resolveFlavor`.** Dev, Stories 1.3 and 1.5.
   - Needed for P0-015 and P1-005.

### Test Infrastructure Setup

1. **`rules_test/` harness** (Story 1.5)
   - npm project: `@firebase/rules-unit-testing` 6.0.0, Node ≥ 24.12, pinned `firebase-tools`
   - Helpers: `authed(uid, {auth_time})`, `seedWithRulesDisabled(...)`, `clearFirestore()` in `afterEach`
2. **Shared schema fixture corpus** (Story 2.2)
   - `valid/` and `invalid/` JSON documents for user, racquet, StringJob and session, consumed by both `rules_test/` and Dart tests
3. **Dart test helpers** (Stories 2.2 and onward)
   - `RacquetFactory` / `StringJobFactory` with unique ids and overridable fields; `withClock(Clock.fixed(...))` wrappers
   - Fake `RacquetRepository`, `SessionRepository`, `AuthRepository`, `ErrorReporter` and `AnalyticsSink` (mocktail)
4. **Environments**
   - Local: Firebase Emulator Suite (Firestore + Auth), Android emulator or Chrome for EMU tests
   - CI: `ubuntu-latest` with Flutter (latest stable), Java and Node ≥ 24.12; time-zone-pinned job for date tests
   - Dev project: rules and indexes deployed per story; dedicated test Google accounts for manual and purge checks

**Example rules test pattern:**

```typescript
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import validRacquet from '../fixtures/valid/racquet-minimal.json';
import tooManyKeys from '../fixtures/invalid/racquet-16-keys.json';

test('[P0] racquet create: owner with user doc succeeds; 16 keys fails', async () => {
  const db = env.authenticatedContext('alice').firestore();
  const ref = doc(db, 'users/alice/racquets/r1');
  await assertSucceeds(setDoc(ref, { ...validRacquet, createdAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  await assertFails(setDoc(doc(db, 'users/alice/racquets/r2'), tooManyKeys));
});
```

---

## Risk Assessment

**Note:** Full details are in the Architecture doc.

### High-Priority Risks (Score ≥6)

| Risk ID | Category | Description | Score | QA Test Coverage |
| --- | --- | --- | --- | --- |
| **R-01** | SEC | Cross-tenant access or schema bypass via rules | **6** | P0-001…P0-005, P0-017 |
| **R-02** | DATA | Rules and Dart schema drift | **6** | P0-003, P0-006, P1-008, P1-016 |
| **R-03** | DATA | Offline writes lost or rejected silently | **6** | P0-007…P0-011, P1-010, P2-001 |
| **R-04** | SEC | Deleted user's data survives | **6** | P0-001, P0-012…P0-014, P1-004 |
| **R-05** | OPS | Sign-in lockout from flavor or SHA misconfiguration | **6** | P0-015, P0-016 |

### Medium/Low-Priority Risks

| Risk ID | Category | Description | Score | QA Test Coverage |
| --- | --- | --- | --- | --- |
| R-06 | DATA | logSession/restring shape rules wrong | 4 | P0-004, P0-005, P0-007, P1-003, P1-013, P1-014, P1-015 |
| R-07 | DATA | Over-strict decode drops racquets | 4 | P1-001, P1-007, P2-002 |
| R-08 | TECH | `google_sign_in` 7.x and web popup flows | 4 | P0-012, P1-005 |
| R-09 | PERF | NFR-1/2/3 unmeasured | 4 | P1-006, P1-019, P2-004, P2-005 |
| R-10 | DATA | Local-date and time-zone errors | 4 | P1-009, P1-012 |
| R-11 | SEC | Billing abuse while App Check monitors | 4 | P2-008 |
| R-12 | BUS | Play review rejection | 4 | P0-016, P1-017, P1-019, P1-021 |
| R-13 | BUS | Accessibility floor missed | 4 | P1-018, P1-020, P2-006 |
| R-14 | TECH | Cleanup deletes tests; reused widgets regress | 4 | P2-003 |
| R-15 | DATA | Decay math wrong | 3 | P0-018, P1-011 |
| R-16 | SEC | Prior user state or crash noise after sign-out | 3 | P0-017, P1-002, P1-004 |
| R-17 | OPS | App Check enforcement blocks real users | 3 | P2-007 |
| R-18 | OPS | Prod rules out of step with installed app | 2 | P3-001 |

---

## NFR Test Coverage Plan

| NFR Category | Requirement / Threshold | Planned Validation | Tool / Level | Evidence Artifact | Priority |
| --- | --- | --- | --- | --- | --- |
| Security | FR-18/NFR-7 ownership and bounds | Per-path and per-shape allow/deny | RULES | `rules_test` CI job | P0 |
| Security | SM-3 ≥ 98 % App Check verified | Console review at day 14 | MANUAL | README operations entry | P2 |
| Reliability | NFR-4/NFR-5 offline + atomic | Network-off queue and sync | EMU | CI log or verification notes | P0 |
| Reliability | AD-14 late rejection surfaced | Commit-error handler, failures stream | UNIT/BLOC | `flutter test` | P0 |
| Reliability | SM-2 crash-free > 99.5 % (Android) | Post-launch monitoring | Crashlytics | Dashboard | P2 |
| Performance | NFR-3 < 1.5 s cold start to bag | Restored-session offline shell (logic) plus device timing | WIDGET + MANUAL | Test + verification notes | P1 / P2 |
| Performance | NFR-1 60 fps gauge, NFR-2 < 500 ms | Profile frame chart; two-client check | MANUAL | Story 2.3 verification notes | P2 |
| Compliance | NFR-6 zero sensitive permissions | Merged-manifest check | CI | CI log | P1 |
| Compliance | NFR-8 Data Safety | privacy.html vs telemetry review; device check | MANUAL | 5.3 / 5.8 notes | P1 |
| Compliance | NFR-9 WCAG 2.2 AA | Guideline matchers + screen-reader pass | WIDGET + MANUAL | `flutter test`; 5.6 notes | P1 |
| Maintainability | CI gates + coverage | analyze, format, coverage | CI | lcov (engine, domain, data) | P1 |

**Missing thresholds or evidence sources:** RTO/RPO, coverage threshold (≥ 80 % proposed), secret-scanning gate.

---

## Entry Criteria

- [x] D-1, D-2 and D-3 decided (2026-10-30)
- [ ] Test dependencies approved per AGENTS.md (`bloc_test`, `mocktail`, `fake_cloud_firestore`, npm rules packages)
- [ ] Firebase dev project and emulator suite available; rules deployed to dev for the story under test
- [ ] Story 1.1 SDK upgrade merged, so the CI matrix runs on the target Flutter version
- [ ] For each story: its rules, fixtures and factories exist before its UI tests

## Exit Criteria

- [ ] All P0 scenarios passing, including the RULES matrix complete for every AD-5 shape and the user doc
- [ ] P1 ≥ 95 % passing; any failure has a recorded waiver
- [ ] No open bug that breaks a P0 or P1 scenario
- [ ] HIGH risks R-01…R-05 mitigated before Play production promotion (5.8)
- [ ] MANUAL evidence recorded: 5.1 purge, 5.6 screen-reader pass, 5.8 device run, 2.3 sync and perf measurements
- [ ] Line coverage ≥ 80 % for engine, `lib/domain` and `lib/data` (if agreed)

---

## Test Coverage Plan

**IMPORTANT:** P0–P3 mean priority and risk, not when tests run. See Execution Strategy for timing.

### P0 (Critical)

| Test ID | Requirement | Test Level | Risk Link | Notes |
| --- | --- | --- | --- | --- |
| **P0-001** | User doc: owner-only read; create ≤ 10 keys with fresh `auth_time`; update only email/displayName; immutable `createdAt`; other uid and stale `auth_time` denied | RULES | R-01, R-04 | Story 1.5 |
| **P0-002** | Default deny: unauthenticated users and every path outside `/users/{uid}/**` | RULES | R-01 | Story 1.5 |
| **P0-003** | Racquet create: full AD-3 shape; deny > 15 keys, tension outside 20–80, missing `pastStringJobs`, wrong owner, missing user doc | RULES | R-01, R-02 | Story 2.4, uses fixture corpus |
| **P0-004** | Session create-only + logSession racquet update; deny decreased hours, increase > 24, changed material, batch on a deleted racquet | RULES | R-01, R-06 | Story 3.1 |
| **P0-005** | updateRacquet / setPrimary / deleteRacquet / restring: ≥ 1 allow + ≥ 1 deny each (restring: remove past job, append two, same job twice, reused id, new hours > 0, maxHours 0) | RULES | R-01, R-06 | Stories 4.2–4.5 |
| **P0-006** | Fixture corpus: valid fixtures decode and pass `schema_bounds`; invalid ones fail | UNIT | R-02 | Story 2.2; mirrors P0-003…P0-005 |
| **P0-007** | logSession batch: session fields, `stringJobId` = current job id, increment via `racquet_fields`; bounds failure → typed failure and no write | REPO | R-03, R-06 | Story 3.1 |
| **P0-008** | Network off: logSession queued, hours visible locally at once, server holds session + increment after reconnect | EMU | R-03 | Story 3.1; required CI job (D-1) |
| **P0-009** | Network off: restring `arrayUnion` queued, applied locally, on the server after reconnect | EMU | R-03 | Story 4.5 |
| **P0-010** | Unawaited commit failure → `MutationFailure` + `ErrorReporter`; permission-denied after sign-out and `unavailable` suppressed | UNIT | R-03 | Story 3.3 (seam per Architecture doc) |
| **P0-011** | Sign-out: dialog when `waitForPendingWrites` > 500 ms (fake_async); `clearPersistence()` never called | BLOC | R-03 | Stories 1.6, 3.3 |
| **P0-012** | Delete account: success (terminate + `clearPersistence` + Google sign-out), re-auth + retry, user-mismatch, cancel, failure keeps streams, web popup blocked → Retry | BLOC | R-04, R-08 | Story 5.2 |
| **P0-013** | Dev purge: deleting an Auth user with racquets, past jobs and sessions removes everything | MANUAL | R-04 | Story 5.1, recorded |
| **P0-014** | `onUserDeleted` recursively deletes `users/{uid}` | EMU | R-04 | Story 5.9, CI |
| **P0-015** | `resolveFlavor`: missing define stops; Android mismatch stops; dev/prod select matching options | UNIT | R-05 | Story 1.3 |
| **P0-016** | Internal-track build on a real device: Google sign-in, log, restring, delete account | MANUAL | R-05, R-12 | Story 5.8, before promotion |
| **P0-017** | Auth gate: no core route without a signed-in user | WIDGET | R-01, R-16 | Story 1.6 |
| **P0-018** | Engine: material constants; boundaries 39/40/69/70 and 39.5/69.5; 0 and over-limit hours; `maxHours` 0 → ArgumentError; future date; DST span; fixtures 92 and 6 | UNIT | R-15 | Story 2.1; core safety value, no workaround |

**Total P0:** 18 scenarios

---

### P1 (High)

| Test ID | Requirement | Test Level | Risk Link | Notes |
| --- | --- | --- | --- | --- |
| **P1-001** | Mapper: absent → null, int → double, pending timestamp → `clock.now()`, unknown material excluded and reported, bad past job skipped, dedupe by id, `isPendingSync` | UNIT | R-07 | Story 2.2; pure mapper |
| **P1-002** | `watchRacquets` is one query; streams complete on uid change; late permission-denied dropped | REPO | R-16 | Story 2.2 (SM-C2) |
| **P1-003** | `resolvePrimary` with 0/1/2 flags, ties by lowest id, empty → null | UNIT | R-06 | Story 2.2 |
| **P1-004** | `ensureUserDoc`: create only when the server reports it absent; update otherwise; offline deferral; `reload()` → gone → sign out | REPO | R-04, R-16 | Story 1.5 |
| **P1-005** | `AuthFailure` mapping (canceled, popupBlocked, network, unknown) → Welcome messages | BLOC | R-08 | Stories 1.5, 1.6 |
| **P1-006** | Restored session offline opens the shell without waiting for the server | WIDGET | R-09 | Story 1.6 |
| **P1-007** | Card lines, critical treatment, pending line; skeleton; empty-from-cache counts as loading; empty bag | WIDGET | R-07 | Story 2.3 |
| **P1-008** | Add form: `schema_bounds` messages, maxHours refill rule, focus to first invalid, double submit ignored, discard prompt, `racquet_created` | WIDGET | R-02 | Story 2.4 |
| **P1-009** | TZ-pinned: picked date ≤ today at 09:00, 15:00 and 23:30 local; 12:00 local → UTC; Change Strings date ≥ current `strungAt` | UNIT | R-10 | Stories 2.4, 4.6 |
| **P1-010** | Quick-Log: default path ≤ 3 taps (SM-C1), pre-selection, vanished-racquet fallback, double tap ignored, snackbar, `session_logged` on local accept | WIDGET | R-03 | Story 3.2 |
| **P1-011** | Bag recomputes on snapshot and on `AppResumed` (`withClock`); primary-first ordering | BLOC | R-15 | Story 2.3 |
| **P1-012** | Timeline newest first, deduped, floored non-negative days; deleted-elsewhere vs not-found messages | WIDGET | R-10 | Story 4.1 |
| **P1-013** | setPrimary batch with 0/1/2 racquets flagged beforehand | REPO | R-06 | Story 4.3 |
| **P1-014** | Delete racquet: sessions kept as `Deleted racquet`; own-device delete never shows the remote message | WIDGET | R-06 | Story 4.4 |
| **P1-015** | Keep Same copies material/brand/tension/maxHours, new id, `manual_restring`; Change Strings reasons; double tap ignored; `racquet_restrung` | BLOC | R-06 | Stories 4.5, 4.6 |
| **P1-016** | Import boundary: only `lib/data/` imports `cloud_firestore`/`firebase_auth`/`google_sign_in` | CI | R-02 | Story 1.3 or 2.2 |
| **P1-017** | Merged-manifest check fails on any health, sensor, activity or fitness permission | CI | R-12 | Stories 1.7, 5.7 |
| **P1-018** | Every UI story: `meetsGuideline` (tap target, labeled tap target, text contrast) + 200 % text scale without overflow | WIDGET | R-13 | Stories 1.6–5.4 |
| **P1-019** | Remote Config exact defaults; slow fetch doesn't delay first frame; `AnalyticsSink` allowlist, no email/displayName; web analytics disabled | UNIT | R-09, R-12 | Story 1.4 |
| **P1-020** | Flows 1–4 with TalkBack, NVDA + Chrome, VoiceOver + Safari | MANUAL | R-13 | Story 5.6 |
| **P1-021** | Hosting on dev: `/privacy.html` served as static HTML; deep link resolves through the rewrite | MANUAL | R-12 | Story 5.3 |

**Total P1:** 21 scenarios

---

### P2 (Medium)

| Test ID | Requirement | Test Level | Risk Link | Notes |
| --- | --- | --- | --- | --- |
| **P2-001** | Bag Sync Summary count and copy, from the bag stream with no extra query | WIDGET | R-03 | Story 3.3 |
| **P2-002** | Sessions feed paging, racquet filter, `Deleted racquet` only after the server emits, empty states | WIDGET | R-07 | Story 3.4 |
| **P2-003** | Theme tokens asserted by value; pure widget tests (radial gauge) ported before the cleanup | WIDGET | R-14 | Stories 1.2, 1.7 |
| **P2-004** | Two-client sync latency on dev vs 500 ms (NFR-2) | MANUAL | R-09 | Story 2.3 |
| **P2-005** | Cold start to bag (NFR-3) and gauge frames (NFR-1) on the newest Pixel phone with the latest Android, profile build | MANUAL | R-09 | Story 2.3 (D-2) |
| **P2-006** | `L`/`N` shortcuts only on the bag with no sheet or focused field and the switch on; `Esc` closes the topmost sheet | WIDGET | R-13 | Story 5.4 |
| **P2-007** | App Check rejection maps to its own typed failure, distinct from post-sign-out permission-denied | UNIT | R-17 | Story 5.10 |
| **P2-008** | Budget alerts and PITR/backups configured and recorded | MANUAL | R-11 | Story 5.7 |

**Total P2:** 8 scenarios

---

### P3 (Low)

| Test ID | Requirement | Test Level | Risk Link | Notes |
| --- | --- | --- | --- | --- |
| **P3-001** | After launch, rules still accept the previous app version's write fixtures | RULES | R-18 | Post-launch; versioned fixture corpus |

**Total P3:** 1 scenario

---

## Execution Strategy

**Philosophy:** Run everything automated on every PR while the suite stays under about 15 minutes. The emulator integration job is a required PR check (D-1).

### Every PR (~10–15 min target)

- `flutter analyze --fatal-infos`, `dart format --set-exit-if-changed .`
- Engine `dart test`; `flutter test` (UNIT, BLOC, WIDGET, REPO)
- Time-zone-pinned job: the date-sensitive test files under one positive and one negative UTC offset
- RULES: `rules_test/` against the Firestore emulator
- CI checks: merged-manifest permissions, import boundary
- `flutter build web`
- EMU: headless Chrome + emulators (D-1)

### Nightly on `main` (only if needed)

- The EMU job, if it doesn't fit the PR budget or proves flaky

### Per Story and Release (manual)

- Per story: deploy rules and indexes to dev; record any MANUAL items in verification notes
- Before Play promotion: P0-013, P0-016, P1-020, P1-021, P2-004, P2-005
- Post-launch: P2-007 (5.10), P0-014 (5.9 by 2027-03-31), SM-2/SM-3 monitoring

---

## QA Effort Estimate

One developer covers all levels, as part of story work.

| Priority | Count | Effort Range | Notes |
| --- | --- | --- | --- |
| P0 | 18 | ~30–45 h | Rules matrix and fixture corpus; EMU job setup (~6–10 h) |
| P1 | 21 | ~35–55 h | Mappers, BLoCs, widgets, CI checks, accessibility |
| P2 | 8 | ~12–20 h | Secondary UI, measurements, ops checks |
| P3 | 1 | ~2–4 h | Versioned fixtures |
| **Total** | **48** | **~80–125 h (~2–3 weeks)** | **Spread across Epics 1–5** |

**Assumptions:** Includes design, implementation, debugging and CI wiring. Excludes ongoing maintenance (~10 %). Each scenario may expand to several test cases.

---

## Implementation Planning Handoff

| Work Item | Owner | Target Milestone | Dependencies/Notes |
| --- | --- | --- | --- |
| `rules_test/` harness + required CI job (pinned firebase-tools) | Dev | Story 1.5 | Node ≥ 24.12, Java |
| Pure `resolveFlavor` + unit tests | Dev | Story 1.3 | — |
| Injected `FirebaseAuth`/`GoogleSignIn` in `FirebaseAuthRepository` | Dev | Story 1.5 | — |
| Import-boundary CI check | Dev | Story 1.3 or 2.2 | — |
| Shared schema fixture corpus | Dev | Story 2.2 | Used by rules and Dart tests |
| Pure mapper signature; check fake fidelity | Dev | Story 2.2 | — |
| Time-zone-pinned CI job | Dev | Story 2.4 | — |
| Commit-error handler seam | Dev | Stories 2.4/3.3 | — |
| EMU headless-Chrome job | Dev | Story 3.1 | D-1 |
| NFR-1/NFR-3 measurement on the newest Pixel, latest Android | Dev | Story 2.3 | D-2 |

---

## Tooling & Access

| Tool or Service | Purpose | Access Required | Status |
| --- | --- | --- | --- |
| Firebase Emulator Suite (`firebase-tools`) | RULES and EMU tests, locally and in CI | None (local) | Pending (Story 1.5) |
| Firebase dev project | Manual checks, rules deploys, purge test | Owner | Pending (Story 1.3) |
| Test Google accounts | Dev sign-in and purge tests | Google accounts | Pending |
| Real Android device + Play internal track | P0-016 | Play Console | Pending (Story 5.8) |
| TalkBack / NVDA / VoiceOver set-ups | P1-020 | Devices | Pending (Story 5.6) |

---

## Interworking & Regression

| Service/Component | Impact | Regression Scope | Validation Steps |
| --- | --- | --- | --- |
| **`string_theory_decay_engine`** | Refactored to four materials (2.1); every health figure depends on it | Engine `dart test` | Required on every PR |
| **Existing Flutter widgets** (radial gauge, theme) | Reused after the Serverpod cleanup (1.7) | Ported widget tests | Port before deleting (P2-003) |
| **`firestore.rules`** | Every data story changes it | Full `rules_test/` suite | Required CI job; deploy to dev per story |
| **CI workflows** | Serverpod, migration and Patrol jobs removed (1.6/1.7) | Remaining jobs green | Check after each workflow change |

**Regression strategy:** All automated suites run on every PR. A rules change reruns the whole rules suite, because shapes interact (for example, logSession vs updateRacquet affected keys).

---

## Appendix A: Code Examples & Tagging

**Dart: tagging by priority**

```dart
// test/data/racquet_mapper_test.dart
@Tags(['p1'])
library;

import 'package:clock/clock.dart';
import 'package:test/test.dart';

void main() {
  group('RacquetMapper', () {
    test('pending server timestamp decodes to clock.now()', () {
      final now = DateTime.utc(2026, 10, 30, 12);
      withClock(Clock.fixed(now), () {
        final racquet = RacquetMapper.decode(
          'r1',
          {...validRacquetMap, 'updatedAt': null},
          hasPendingWrites: true,
          isFromCache: true,
        );
        expect(racquet.updatedAt, now);
        expect(racquet.isPendingSync, isTrue);
      });
    });
  });
}
```

**Run subsets:**

```bash
flutter test --tags p0
```

```bash
TZ=Pacific/Auckland flutter test test/domain/stringing_date_test.dart
```

```bash
cd rules_test && npm test
```

---

## Appendix B: Knowledge Base References

- **Risk Governance:** `risk-governance.md` (risk scoring method)
- **Test Priorities Matrix:** `test-priorities-matrix.md` (P0–P3 criteria)
- **Test Levels Framework:** `test-levels-framework.md` (choosing the test level)
- **Test Quality:** `test-quality.md` (Definition of Done: no hard waits, ≤ 1000 lines, < 1.5 min)

---

**Generated by:** BMad TEA Agent
**Workflow:** `bmad-testarch-test-design`
**Version:** 4.0 (BMad v6)
