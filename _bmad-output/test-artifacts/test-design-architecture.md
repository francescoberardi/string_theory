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
  - _bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/addendum.md
  - _bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/ARCHITECTURE-SPINE.md
  - _bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/reviews/review-adversary.md
  - _bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/reviews/review-rubric.md
  - _bmad-output/planning-artifacts/epics.md
  - .github/workflows/tests.yml
  - _bmad/tea/config.yaml
---

# Test Design for Architecture: String Theory v1 (Firebase)

**Purpose:** Architectural concerns, testability gaps, and NFR requirements for review by Architecture/Dev. Serves as the contract on what must be in place before, or alongside, test development.

**Date:** 2026-10-30
**Author:** Murat (TEA) for Francesco
**Status:** Architecture Review Pending
**Project:** string_theory
**PRD Reference:** `_bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/prd.md`
**ADR Reference:** `_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/ARCHITECTURE-SPINE.md` (AD-1…AD-16)

---

## Executive Summary

**Scope:** String Theory v1.0, a Flutter Android + Web app on Firebase (Google-only Auth, Firestore with offline persistence, `firestore.rules`, App Check, the `delete-user-data` extension and its v2 function replacement, telemetry, Remote Config, Hosting). Covers Epics 1–5 (stories 1.1–5.10).

**Business Context** (from PRD):

- **Impact:** Players' arm health depends on trusting the health score; Play Store compliance (account deletion, Data Safety, zero health permissions) gates the launch.
- **Problem:** Strings go dead unnoticed; logging must take ≤ 10 s, including on courts with no signal.
- **GA Launch:** Google Play internal track, then production (Story 5.8). Web URL announced only after the consent decision (Story 5.5).

**Architecture** (from the spine):

- **AD-1/AD-13:** Layered client (UI → BLoC → repository interfaces ← Firestore implementations), so BLoCs test with `mocktail` fakes and no Firebase.
- **AD-3/AD-5:** `firestore.rules` is the only server-side write check. It covers six enumerated write shapes, each needing a positive and a negative rules test.
- **AD-7/AD-14:** Health is computed on the device with an injected clock. Mutations complete when the device accepts them locally, and late rejections reach a failures stream.

**Expected Scale:** Consumer app with per-user data under `/users/{uid}`. No throughput or availability targets are stated beyond Firebase's managed SLAs.

**Risk Summary:**

- **Total risks:** 18
- **High-priority (≥ 6):** 5 risks needing mitigation before production promotion. None is critical (score 9).
- **Test effort:** ~48 scenarios (many expand to several test cases), about 80–125 hours, or about 2–3 weeks for one developer, spread across story work.

---

## Quick Guide

### 🚨 BLOCKERS - Team Must Decide (Can't Proceed Without)

**No hard pre-implementation blockers.** The spine already settled the issues the architecture reviews rated HIGH: pending timestamps (AD-3), the meaning of "done" offline (AD-14), per-shape rules (AD-5) and flavors (AD-12). The three story-gating decisions were made by Francesco on 2026-10-30 and are recorded in `epics.md`:

1. **D-1: Offline tests in CI. Decided: CI.** The network-off emulator tests run as a headless-Chrome `integration_test` job against the Firestore and Auth emulators, required before merge. Story 3.1 adds the job.
2. **D-2: Performance reference. Decided:** the newest Pixel phone on the latest stable Android release, profile build, with device model and Android version recorded. Applies to NFR-1 and NFR-3 in Story 2.3.
3. **D-3: SM-1 measurement. Decided:** SM-C1's ≤ 3-tap widget test (Story 3.2) is the accepted proxy for SM-1. No logging-duration telemetry is added.

---

### ⚠️ HIGH PRIORITY - Team Should Validate (We Provide Recommendation, You Approve)

1. **R-01/R-02: One shared schema fixture corpus.** JSON fixtures of valid and invalid documents used by both `rules_test/` and the Dart mapper and `schema_bounds` tests, so the four AD-3 artifacts can't drift. (Approve: Francesco, Stories 2.2/2.4)
2. **R-03: Pure mappers and one commit-error handler.** Mappers take `(Map, hasPendingWrites, isFromCache)` rather than `DocumentSnapshot`. Every unawaited `commit()`/`update()` routes its error through one testable handler. (Approve: Francesco, Stories 2.2/3.3)
3. **R-05: Testable flavor guard and injected auth SDKs.** Extract flavor resolution into a pure function. Inject `FirebaseAuth` and `GoogleSignIn` into `FirebaseAuthRepository`. (Approve: Francesco, Stories 1.3/1.5)
4. **R-10: Time-zone-pinned date tests.** Run date-sensitive test files in CI under one positive-offset and one negative-offset zone. (Approve: Francesco, Story 2.4)

---

### 📋 INFO ONLY - Solutions Provided (Review, No Decisions Needed)

1. **Test strategy:** Unit/BLoC/widget-heavy (`flutter test`), REPO on `fake_cloud_firestore`, RULES on the Firestore emulator as the API layer, a few EMU integration tests, and MANUAL verification for device, console and screen-reader items. No Patrol E2E (retired).
2. **Tooling:** `dart test`, `flutter test`, `bloc_test`, `mocktail`, `fake_cloud_firestore` (with the equatable override), `@firebase/rules-unit-testing` 6.0.0, the Firebase Emulator Suite, and `flutter_test` accessibility guidelines.
3. **Tiered CI:** PR target under 15 min (analyze, format, engine, flutter test, rules, build web, manifest and import-boundary checks). The EMU job is also required on PRs (D-1). Release checks are manual.
4. **Coverage:** 48 scenarios (18 P0, 21 P1, 8 P2, 1 P3) prioritized by risk.
5. **Quality gates:** P0 100 %, P1 ≥ 95 %, a positive and a negative test for every write shape, HIGH risks mitigated before Play promotion, and ≥ 80 % line coverage on engine, domain and data (proposed).

---

## For Architects and Devs - Open Topics 👷

### Risk Assessment

**Total risks identified:** 18 (5 high-priority score ≥ 6, 9 medium, 4 low)

#### High-Priority Risks (Score ≥6) - IMMEDIATE ATTENTION

| Risk ID | Category | Description | Probability | Impact | Score | Mitigation | Owner | Timeline |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **R-01** | **SEC** | Rules let one user read or write another's data, or bypass the schema. The spine makes rules "the only server-side check on writes" (FR-18) | 2 | 3 | **6** | Positive and negative RULES tests per path and per AD-5 shape, including wrong uid and missing user doc. Required CI job. Deploy to dev each story | Dev | Story 1.5 → every rules story |
| **R-02** | **DATA** | Writes the app considers valid are rejected by rules (or the reverse) because `schema_bounds`, mappers and rules drift (AD-3 "Prevents"; AD-14 "a rules rejection means a bug") | 2 | 3 | **6** | Shared fixture corpus. Enforce the same-PR rule in review | Dev | Stories 2.2, 2.4 |
| **R-03** | **DATA** | Offline-queued writes are lost or rejected without the user knowing (NFR-4; AD-10 bans `clearPersistence()` while writes are pending; AD-14 failures stream) | 2 | 3 | **6** | Network-off EMU tests (3.1, 4.5) in the required CI job (D-1). Failures-stream tests (3.3). A test that sign-out never clears persistence | Dev | Epics 3–4 |
| **R-04** | **SEC** | A deleted user's data survives: extension misconfigured, another device recreates `/users/{uid}`, or the Extensions shutdown on 2027-03-31 (FR-4, NFR-8, AD-10) | 2 | 3 | **6** | Rules tests: no writes without the user doc, stale `auth_time` create denied. Recorded dev purge (5.1). Monitoring alert and runbook. Story 5.9 with a CI emulator test | Dev / Owner | Epic 5; 5.9 by 2027-03-31 |
| **R-05** | **OPS** | Wrong Firebase project or missing SHA fingerprints break Google sign-in in the Play build. With Google-only auth, that locks out every user (AD-12, FR-1, review-rubric F1) | 2 | 3 | **6** | Unit-tested flavor guard. README fingerprint checklist. Sign-in verified on a real device from the internal track before promotion | Dev / Owner | Stories 1.3, 5.8 |

#### Medium-Priority Risks (Score 3-5)

| Risk ID | Category | Description | Probability | Impact | Score | Mitigation | Owner |
| --- | --- | --- | --- | --- | --- | --- | --- |
| R-06 | DATA | logSession or restring update-shape rules allow decreasing hours or truncating `pastStringJobs`, or block legitimate writes (AD-5) | 2 | 2 | 4 | The negative tests named in 3.1 and 4.5 | Dev |
| R-07 | DATA | Over-strict decode drops racquets from the bag without telling the user (UX-DR28; adversary F1, F10) | 2 | 2 | 4 | Mapper tests: pending timestamp, int-valued numbers, unknown material, bad past job | Dev |
| R-08 | TECH | `google_sign_in` 7.x initialize/authenticate flow; web re-auth popup blocked after an await (AD-9, Story 5.2) | 2 | 2 | 4 | Injected SDK instances. BLoC tests per `AuthFailure`. Manual Android and Web check | Dev |
| R-09 | PERF | NFR-1 (60 fps), NFR-2 (< 500 ms) and NFR-3 (< 1.5 s) are unmeasured. The bootstrap awaits several Firebase steps before the first frame (AD-11) | 2 | 2 | 4 | Measured on the D-2 reference device. Unit test that the Remote Config fetch is not awaited. Recorded measurements | Dev |
| R-10 | DATA | Local-date and time-zone bugs: off-by-one stringing dates, today rejected late at night, negative durations (AD-15) | 2 | 2 | 4 | TZ-pinned tests. 09:00/15:00/23:30 cases. DST engine case | Dev |
| R-11 | SEC | Billing or storage abuse while App Check is monitor-only. Document counts are uncapped (`free_racquet_limit` unused; `pastStringJobs` has no cap) | 2 | 2 | 4 | Rules bounds. Budget alerts (5.7). App Check enforcement (5.10) | Owner |
| R-12 | BUS | Play review rejection: leftover health permissions, Data Safety mismatch, deletion URL (NFR-6, NFR-8) | 2 | 2 | 4 | Merged-manifest CI check. Review privacy.html against actual telemetry | Dev / Owner |
| R-13 | BUS | Accessibility floor missed (NFR-9, UX-DR26) | 2 | 2 | 4 | `meetsGuideline` checks and 200 % text-scale widget tests. Screen-reader pass (5.6) | Dev |
| R-14 | TECH | The brownfield cleanup (1.7) deletes most existing tests; reused widgets can regress unnoticed | 2 | 2 | 4 | Port the pure widget tests (radial gauge, theme) before deleting | Dev |
| R-15 | DATA | Decay math wrong at tier boundaries, with `maxHours` 0, with future dates or across DST (FR-9, FR-10) | 1 | 3 | 3 | Engine fixtures listed in Story 2.1 | Dev |
| R-16 | SEC | Previous user's state visible after sign-out, or post-sign-out permission-denied errors reported as crashes (FR-3, AD-10) | 1 | 3 | 3 | BLoCs under the signed-in subtree. Stream-completion and dropped-error repository tests | Dev |
| R-17 | OPS | App Check enforcement blocks genuine users (AD-12, SM-3) | 1 | 3 | 3 | Monitor-only until ≥ 98 %. Typed App Check failure (5.10) | Owner |

#### Low-Priority Risks (Score 1-2)

| Risk ID | Category | Description | Probability | Impact | Score | Action |
| --- | --- | --- | --- | --- | --- | --- |
| R-18 | OPS | Manual deploys leave prod rules out of step with installed app versions (Deploy convention; automated deploy deferred) | 1 | 2 | 2 | Document: post-launch rule changes must accept the previous app version's writes |

#### Risk Category Legend

- **TECH**: Technical/Architecture (flaws, integration, scalability)
- **SEC**: Security (access controls, auth, data exposure)
- **PERF**: Performance (SLA violations, degradation, resource limits)
- **DATA**: Data Integrity (loss, corruption, inconsistency)
- **BUS**: Business Impact (UX harm, logic errors, revenue)
- **OPS**: Operations (deployment, config, monitoring)

---

### NFR Testability Requirements

| NFR Category | Threshold / Requirement | Current Design Support | Gap / Decision Needed | Planned Evidence |
| --- | --- | --- | --- | --- |
| Security | FR-18 / NFR-7: owner-only `/users/{uid}/**`; ≤ 15 / ≤ 12 / ≤ 10 keys; AD-3 bounds | Supported (AD-3, AD-5, AD-13) | Shared fixture corpus (R-02) | `rules_test` CI job |
| Security | SM-3 App Check ≥ 98 % verified | Supported (AD-12 monitor → enforce) | None | Prod console metrics, README entry (5.10) |
| Security | No secrets in the repo (AGENTS.md) | Policy only | **UNKNOWN** gate: GitHub secret scanning or a gitleaks job | Scan report |
| Performance | NFR-1 60 fps gauge; NFR-3 < 1.5 s cold start to bag | Partial (persistence; Remote Config not awaited) | Decided (D-2): newest Pixel, latest Android, profile build | Profile-mode frame chart; Perf `_app_start` trace |
| Performance | NFR-2 < 500 ms sync | Partial (a one-off manual check in 2.3) | Accept manual evidence for v1 | Story 2.3 verification notes |
| Performance | SM-1 > 90 % of logs ≤ 10 s | Proxy accepted (D-3) | None: no timing telemetry | SM-C1 ≤ 3-tap widget test (3.2) |
| Reliability | NFR-4 / NFR-5 offline + atomic | Supported (persistence, WriteBatch, AD-14) | Decided (D-1): required CI job | EMU job log |
| Reliability | SM-2 > 99.5 % crash-free (Android) | Supported (Crashlytics) | Web has no crash reporting (accepted in PRD) | Crashlytics dashboard |
| Reliability (DR) | Backups / PITR (5.7) | Planned | **UNKNOWN** RTO/RPO | README operations section |
| Maintainability | CI gates required before merge | Supported (CI convention) | Coverage threshold **UNKNOWN** (proposed ≥ 80 % for engine, domain and data) | lcov report |
| Compliance | NFR-6, NFR-8, NFR-9 | Supported (1.7 check, 5.3, 5.6) | None | CI log; 5.3, 5.6 and 5.8 notes |

**Unknown thresholds:** RTO/RPO, coverage threshold, secret-scanning gate. (D-2 and D-3 settled the perf method and SM-1 source.)

**Assessment boundary:** Final PASS/CONCERNS/FAIL status belongs to `nfr-assess` once implementation evidence exists.

---

### Testability Concerns and Architectural Gaps

**🚨 ACTIONABLE CONCERNS.** None blocks the start of work. Each is attached to the story where it is cheapest to address.

#### 1. Blockers to Fast Feedback (WHAT WE NEED FROM ARCHITECTURE)

| Concern | Impact | What Architecture Must Provide | Owner | Timeline |
| --- | --- | --- | --- | --- |
| **Offline behaviour has no CI gate** (TC-1) | NFR-4/5, the riskiest property, can regress silently between manual runs | A headless-Chrome `integration_test` job against the Firestore and Auth emulators, using `disableNetwork()`/`enableNetwork()` | Dev | Story 3.1 (decided, D-1) |
| **Late-rejection path has no seam** (TC-3) | AD-14's failures stream can't be tested deterministically: the commit isn't awaited and the fake can't reject | One repository-internal handler for unawaited commit errors, unit-testable with an injected failing future, plus one real rejection in the EMU job | Dev | Stories 2.4, 3.3 |
| **Snapshot metadata may be outside the fake's fidelity** (TC-2) | Six ACs depend on `hasPendingWrites`, `isFromCache` or pending timestamps | Pure mapper signature `decode(Map, {hasPendingWrites, isFromCache})`. Check `fake_cloud_firestore` fidelity in 2.2 before relying on it | Dev | Story 2.2 |

#### 2. Architectural Improvements Needed (WHAT SHOULD BE CHANGED)

1. **Shared schema fixture corpus** (TC-6)
   - **Current problem:** AD-3 relies on one PR updating four artifacts in two languages, with no mechanical check that they agree.
   - **Required change:** A versioned set of valid and invalid JSON documents, read by `rules_test/` (TS) and the Dart mapper and `schema_bounds` tests.
   - **Impact if not fixed:** Writes accepted on the device and rejected by the server, which shows up as data loss after sync (R-02).
   - **Owner:** Dev. **Timeline:** Stories 2.2/2.4. Every rules story adds to it.

2. **Injectable auth SDKs and a pure flavor resolver** (TC-4, ASR-4)
   - **Current problem:** `GoogleSignIn.instance` is a singleton, and the flavor guard lives in `main()`.
   - **Required change:** Constructor-inject `FirebaseAuth` and `GoogleSignIn`. Expose `resolveFlavor(String? define, String? appFlavor)` as a pure function.
   - **Impact if not fixed:** The platform branches and the guard that prevents prod lockout (R-05) go untested.
   - **Owner:** Dev. **Timeline:** Stories 1.3/1.5.

3. **Import-boundary check** (ASR-3)
   - **Current problem:** AD-1's rule that only `lib/data/` imports the Firebase SDKs is enforced only by review.
   - **Required change:** A CI step (grep or a custom lint) that fails when `cloud_firestore`, `firebase_auth` or `google_sign_in` is imported outside `lib/data/`.
   - **Impact if not fixed:** BLoC tests start needing Firebase, and the test pyramid erodes.
   - **Owner:** Dev. **Timeline:** Story 1.3 or 2.2.

4. **Time-zone-pinned date tests** (TC-5)
   - **Current problem:** GitHub runners use UTC, so "12:00 local → UTC" and "picked date ≤ today" pass trivially.
   - **Required change:** Run date-sensitive test files under `TZ=` with a positive and a negative offset in CI.
   - **Owner:** Dev. **Timeline:** Story 2.4.

5. **Pinned emulator tooling** (TC-9)
   - **Required change:** Pin the `firebase-tools` version and a Java runtime in the rules CI job, next to `@firebase/rules-unit-testing` 6.0.0 and Node ≥ 24.12.
   - **Owner:** Dev. **Timeline:** Story 1.5.

---

### Testability Assessment Summary

**📊 CURRENT STATE - FYI.**

#### What Works Well

- ✅ AD-1 domain interfaces (`*Repository`, `ErrorReporter`, `AnalyticsSink`) make every BLoC testable without Firebase.
- ✅ AD-7: `package:clock` and a required `now` in the engine give deterministic health tests with no timers.
- ✅ AD-5 lists exactly six write shapes and requires a positive and a negative rules test for each.
- ✅ AD-8 `resolvePrimary` and AD-6 dedupe-by-id are pure functions.
- ✅ `@firebase/rules-unit-testing` custom claims make the `auth_time` create rule testable.
- ✅ Path-scoped multi-tenancy isolates test data naturally in emulator runs.
- ✅ Typed failures mean BLoCs never inspect Firebase codes, so error states are assertable.

#### Accepted Trade-offs (No Action Required)

For v1, the following trade-offs are acceptable:

- **No automated E2E** (Patrol retired, PRD non-goal). Critical journeys are verified manually on the internal-track build (5.8) and by the screen-reader pass (5.6).
- **Manual deletion-purge evidence until Story 5.9.** It is backed by a Monitoring alert and runbook, and 5.9 adds a CI test before 2027-03-31.
- **No web crash reporting** (Crashlytics has no web support; PRD SM-2).
- **One-off NFR-2 measurement** on dev, with no continuous latency monitoring.

These trade-offs are deliberate technical debt for v1 and should be revisited after GA.

---

### Risk Mitigation Plans (High-Priority Risks ≥6)

**Purpose:** Mitigation strategies for all 5 high-priority risks. They must be addressed before production promotion in Story 5.8.

**Residual risk after mitigation:** R-01 and R-02 drop to probability 1 (score 3), since every shape and bound becomes test-locked. R-03 drops to 3 with the required CI job (D-1). R-04 stays at 6 until Story 5.9's CI test exists, because purge evidence is manual until then. R-05 drops to 3 after the 5.8 device run, but recurs whenever signing keys or projects change.

#### R-01: Cross-tenant access or schema bypass through rules (Score: 6) - HIGH

**Mitigation Strategy:**

1. Story 1.5 creates `rules_test/` with a default-deny test and the user-doc suite (wrong uid, immutable `createdAt`, stale `auth_time`).
2. Every story that adds a path or write shape adds at least one positive and one negative test, including a wrong-uid case.
3. The rules job is a required CI check. Rules are deployed to dev before the story is done.

**Owner:** Dev
**Timeline:** Story 1.5, then 2.2, 2.4, 3.1, 4.2–4.5
**Status:** Planned
**Verification:** The rules CI job is green. The AD-5 shape × {positive, negative} matrix is complete in `rules_test/`.

#### R-02: Schema drift between rules and Dart (Score: 6) - HIGH

**Mitigation Strategy:**

1. Create a shared fixture corpus (valid and invalid documents for user, racquet, StringJob and session).
2. The Dart tests assert that valid fixtures decode and pass `schema_bounds`, and that invalid fixtures fail. The rules tests assert the same fixtures are allowed or denied.
3. Every bound change touches the corpus in the same PR.

**Owner:** Dev
**Timeline:** Stories 2.2/2.4
**Status:** Planned
**Verification:** Changing a bound in only one artifact fails a test.

#### R-03: Offline writes lost or rejected silently (Score: 6) - HIGH

**Mitigation Strategy:**

1. Network-off EMU tests for logSession (3.1) and restring (4.5), running in the required CI job (D-1).
2. A unit test for the commit-error handler: the failures stream is published, `ErrorReporter` is called, and permission-denied after sign-out and `unavailable` are suppressed.
3. A BLoC test proving sign-out never calls `clearPersistence()`, and that the pending-writes dialog appears after 500 ms.

**Owner:** Dev
**Timeline:** Epics 3–4
**Status:** Planned
**Verification:** EMU job green. Story 3.3 BLoC tests green.

#### R-04: Deleted user's data survives (Score: 6) - HIGH

**Mitigation Strategy:**

1. Rules tests: no write without the user document, and a create with a stale `auth_time` is denied.
2. Repository test: on a restored session, `ensureUserDoc` → `reload()` → user gone → sign out without writing.
3. Recorded dev purge with the extension (5.1). A Cloud Monitoring alert on function failure, and a runbook.
4. Story 5.9: the v2 `onUserDeleted` function with a CI emulator test, before 2027-03-31.

**Owner:** Dev / Owner
**Timeline:** Stories 1.5, 5.1, 5.2; 5.9 by 2027-03-31
**Status:** Planned
**Verification:** 5.1 verification notes; the 5.9 CI test is green; the alert is configured.

#### R-05: Sign-in lockout from environment misconfiguration (Score: 6) - HIGH

**Mitigation Strategy:**

1. A pure `resolveFlavor` with unit tests: a missing define stops, an Android mismatch stops, and dev/prod pick the matching options.
2. A README checklist of SHA-1/SHA-256 fingerprints per project (debug, upload, Play App Signing).
3. Story 5.8: Google sign-in, logging, restring and deletion verified on a real device installed from the internal track before promotion.

**Owner:** Dev / Owner
**Timeline:** Stories 1.3, 5.8
**Status:** Planned
**Verification:** Unit tests green; 5.8 verification notes.

---

### Assumptions and Dependencies

#### Assumptions

1. There are no production users before Story 5.8 (Epic 1 states this), so the engine's material remap needs no data migration.
2. One developer owns every test level. "QA" in the companion doc means the same person.
3. The Firebase Emulator Suite and `@firebase/rules-unit-testing` 6.0.0 run on GitHub's `ubuntu-latest` with Java and Node ≥ 24.12.
4. `fake_cloud_firestore` with the equatable override resolves on the upgraded SDK (AD-13).

#### Dependencies

1. Dev and prod Firebase projects on Blaze, with test Google accounts in dev. Required by Stories 1.3 and 5.1.
2. User approval of each test dependency (`bloc_test`, `mocktail`, `fake_cloud_firestore`, npm packages) under the AGENTS.md dependency policy. Required by the first story that needs each.
3. A real Android device for 5.8, plus TalkBack, NVDA and VoiceOver set-ups for 5.6. Required before production promotion.

#### Risks to Plan

- **Risk:** `fake_cloud_firestore` can't model the snapshot metadata the ACs need.
  - **Impact:** REPO tests give false confidence.
  - **Contingency:** Pure mappers (TC-2) plus the EMU job cover the gap.
- **Risk:** The EMU Chrome job is flaky or slow in CI.
  - **Impact:** It erodes trust in the PR gate.
  - **Contingency:** Fix the flakiness rather than drop the gate. As a temporary measure only, quarantine it to nightly on `main` with a recorded reason.

---

**End of Architecture Document.**

**Next Steps for Architecture/Dev:**

1. D-1, D-2 and D-3 are decided, and the ⚠️ recommendations are folded into `epics.md` (2026-10-30).
2. Run Sprint Planning.

**Next Steps for QA (same developer):**

1. Refer to `test-design-qa.md` for scenarios and execution.
2. Set up `rules_test/` and the fixture corpus in Stories 1.5 and 2.2.
