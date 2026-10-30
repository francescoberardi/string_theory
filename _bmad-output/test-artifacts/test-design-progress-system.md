---
runScope: 'system-level'
runKey: 'system'
workflowStatus: 'completed'
totalSteps: 5
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
nextStep: ''
lastSaved: '2026-10-30'
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/prd.md
  - _bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/addendum.md
  - _bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/ARCHITECTURE-SPINE.md
  - _bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/reviews/review-adversary.md
  - _bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/reviews/review-rubric.md
  - _bmad-output/planning-artifacts/epics.md
  - _bmad/tea/config.yaml
  - .github/workflows/tests.yml
  - resources/knowledge/adr-quality-readiness-checklist.md
  - resources/knowledge/nfr-criteria.md
  - resources/knowledge/test-levels-framework.md
  - resources/knowledge/risk-governance.md
  - resources/knowledge/test-quality.md
  - resources/knowledge/playwright-cli.md
---

# Test Design Progress — System Level (Firebase v1)

## Step 1: Mode Detection

- **Mode:** System-Level (explicit user intent: "System-level test plan for the Firebase v1 epics")
- **Prerequisites present:**
  - PRD: `_bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/prd.md` (+ `addendum.md`)
  - Architecture / ADRs: `_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/ARCHITECTURE-SPINE.md` (+ reviews)
  - Epics & stories: `_bmad-output/planning-artifacts/epics.md` (Firebase v1, finalized 2026-10-30)
  - UX: `_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/{DESIGN,EXPERIENCE}.md`
- **Note:** `sprint-status.yaml` exists but tracks the retired Serverpod epics; ignored for mode detection.

## Step 2: Context Loaded

**Config:** tea_use_playwright_utils=true, tea_use_pactjs_utils=true (no package.json/Pact in repo → contract branch closed), tea_pact_mcp=mcp (not relevant), tea_browser_automation=auto, test_stack_type=auto.

**Detected stack:** `mobile` (Flutter `pubspec.yaml`, `android/`) with a serverless backend (Firebase: Firestore rules, Auth, one extension/function). No `firebase.json`, `firestore.rules` or `rules_test/` yet — all introduced by Epic 1.

**Tech stack & test tooling (AD-13):** `dart test` (engine), `flutter test` + `bloc_test` + `mocktail` (BLoCs/widgets), `fake_cloud_firestore` (repositories, needs equatable override), `@firebase/rules-unit-testing` 6.0.0 on the Firestore emulator (`rules_test/`, npm, Node ≥ 24.12), local-only network-off emulator tests (Android emulator / Chrome). Patrol E2E retired.

**Integration points:** Firebase Auth (Google Sign-In Android `google_sign_in` 7.x / Web popup), Firestore (snapshots, WriteBatch, arrayUnion, increment, offline persistence, multi-tab), App Check (Play Integrity / reCAPTCHA Enterprise, monitor → enforce), `delete-user-data` extension → v2 `onUserDeleted` function, Crashlytics/Perf/Analytics/Remote Config, Firebase Hosting (SPA rewrite + `/privacy.html`), Google Play.

**NFR thresholds:** NFR-1 60 fps gauge; NFR-2 < 500 ms sync; NFR-3 < 1.5 s cold start to bag; NFR-4/5 offline + atomic; NFR-6 zero sensitive permissions; NFR-7 rules key/length bounds; NFR-8 Data Safety; NFR-9 WCAG 2.2 AA; SM-2 > 99.5 % crash-free; SM-3 ≥ 98 % App Check verified; SM-C1 ≤ 3 taps; SM-C2 one query.

**Missing threshold questions:** NFR-1/2/3 have no named measurement device/method or CI gate (manual dev-project measurement only); no RTO/RPO for Firestore PITR/backups; no availability target (relies on Firebase SLA).

**Existing coverage (brownfield):** engine `dart test` (1 file), ~37 Flutter test files, most bound to Serverpod/health surfaces that Story 1.7 deletes. CI `tests.yml` still runs Serverpod, migration and Patrol jobs on Flutter 3.44.4.

**Knowledge fragments loaded:** adr-quality-readiness-checklist, nfr-criteria, test-levels-framework, risk-governance, test-quality, playwright-cli (Flutter Web is canvas-rendered; CLI exploration only usable through the semantics tree and not applicable pre-implementation).

## Step 3: Testability & Risk Assessment

### 🚨 Testability Concerns

| ID | Concern | Evidence | Recommendation |
| --- | --- | --- | --- |
| TC-1 | Offline queueing (NFR-4/5) is only proven by local, manual-recorded emulator runs; no CI regression gate | Epics → Testing and CI: network-off tests "run locally … not in CI" | Add one CI job running a Flutter `integration_test` on headless Chrome against the Firestore + Auth emulators, using `disableNetwork()`/`enableNetwork()` as the fault injector |
| TC-2 | `fake_cloud_firestore` may not model snapshot metadata (`hasPendingWrites`, `isFromCache`), pending server timestamps or server rejections, yet several ACs depend on them | Stories 2.2 (isPendingSync, pending timestamp), 2.3 (empty-from-cache = loading), AD-14 | Keep mappers pure: `decode(Map, {hasPendingWrites, isFromCache})` with no `DocumentSnapshot` parameter, so metadata behaviour is unit-tested; verify fake fidelity in Story 2.2 before relying on it |
| TC-3 | Late-rejection path (AD-14) has no deterministic seam: the commit future is not awaited and the fake cannot reject | AD-14, Story 3.3 | Route every unawaited commit through one repository handler that is unit-testable with an injected failing future; prove one real rejection end-to-end in the TC-1 emulator job |
| TC-4 | Auth platform branches (Android `google_sign_in` 7.x vs Web popup) and the `GoogleSignIn.instance` singleton are hard to fake | AD-9, Story 1.5 | Inject `FirebaseAuth`/`GoogleSignIn` into `FirebaseAuthRepository`; use the Auth emulator for integration; real Google + SHA config verified only on device (Story 5.8) |
| TC-5 | Local-date logic (12:00 local → UTC, "picked date ≤ today", floored days) passes trivially on UTC CI runners | AD-15, Stories 2.4, 4.1, 4.6 | Run date-sensitive test files under pinned non-UTC zones in CI (one positive offset, one negative offset) |
| TC-6 | Rules (CEL, tested in TS) and Dart `schema_bounds`/mappers can drift with no mechanical check | AD-3 "same PR must update…" | Shared JSON fixture corpus of valid/invalid documents consumed by both `rules_test/` and Dart tests |
| TC-7 | Deletion purge (FR-4) has manual-only evidence until Story 5.9 | Story 5.1 verification notes; 5.9 adds CI test | Accept for launch with recorded dev verification + Cloud Monitoring alert; 5.9 CI emulator test is mandatory |
| TC-8 | NFR-1/2/3 have thresholds but no named device, build mode or method | PRD §8.1, Story 2.3 | Define reference device + profile build; use Perf `_app_start` trace for NFR-3, DevTools frame chart for NFR-1, the two-client check for NFR-2 |
| TC-9 | CI still runs Serverpod/Patrol jobs on Flutter 3.44.4; rules job needs Java + Node ≥ 24.12 + firebase-tools (version unpinned) | `tests.yml`, Stack table | Pin `firebase-tools` and emulator versions when the rules job is added (Story 1.5) |

### ✅ Testability Strengths

- AD-1 layering + domain interfaces (`*Repository`, `ErrorReporter`, `AnalyticsSink`) → BLoCs fully testable with `mocktail`, no Firebase SDK.
- AD-7 "now" from `package:clock`, engine takes required `now` → deterministic health tests (`withClock`), no timers.
- AD-5 enumerates exactly six write shapes, each with a mandated positive + negative rules test.
- AD-8 `resolvePrimary` and AD-6 dedupe-by-id are pure domain functions.
- `@firebase/rules-unit-testing` supports custom token claims → `auth_time` create rule is testable.
- Typed failures (`lib/domain/failures.dart`) → BLoC error states assertable without Firebase codes.
- Multi-tenancy by path (`/users/{uid}`) gives natural test-data segregation in emulator runs.

### ASRs

| ASR | Requirement | Source | Status |
| --- | --- | --- | --- |
| ASR-1 | Rules are the only server-side write check; per-shape pos/neg tests required in CI | AD-3, AD-5, FR-18, NFR-7 | ACTIONABLE |
| ASR-2 | Mutations complete on local accept; offline writes queue and sync; late rejections surface | AD-14, NFR-4, NFR-5 | ACTIONABLE (TC-1, TC-3) |
| ASR-3 | Only `lib/data/` imports Firebase data SDKs | AD-1 | ACTIONABLE — add an import-boundary check in CI |
| ASR-4 | Flavor guard: no default flavor; mismatch stops `main()` | AD-12 | ACTIONABLE — extract a pure flavor-resolution function and unit-test it |
| ASR-5 | Zero sensitive Android permissions | NFR-6, Story 1.7 | ACTIONABLE — merged-manifest CI check |
| ASR-6 | Account deletion purges all data; extension replaced before 2027-03-31 | AD-10, FR-4, NFR-8 | ACTIONABLE |
| ASR-7 | WCAG 2.2 AA on Android + Web | NFR-9, UX-DR26 | ACTIONABLE — `flutter_test` accessibility guidelines in widget tests + Story 5.6 manual pass |
| ASR-8 | Health computed client-side, never stored | AD-7, FR-11 | FYI — covered by engine + BLoC tests |
| ASR-9 | Bag = one collection query | SM-C2 | FYI — repository test |
| ASR-10 | App Check monitor → enforce at ≥ 98 % | AD-12, SM-3 | FYI — console evidence, Story 5.10 |

### Risk Register

Scoring: Probability (1–3) × Impact (1–3). ≥ 6 HIGH (mitigation required), 9 CRITICAL (gate blocker).

| ID | Cat | Risk (grounding) | P | I | Score | Mitigation | Owner | Timeline |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| R-01 | SEC | Rules let one user read/write another user's data or bypass schema; rules are "the only server-side check on writes" (spine paradigm, FR-18) | 2 | 3 | **6** | Pos/neg rules test per path and AD-5 shape incl. wrong uid and missing user doc; required CI job; deploy to dev each story | Dev | Story 1.5 harness → every rules story |
| R-02 | DATA | App-valid writes rejected by rules (or vice versa) because `schema_bounds`, mappers and rules drift (AD-3 "Prevents", AD-14 "a rules rejection means a bug") | 2 | 3 | **6** | Shared fixture corpus (TC-6); same-PR rule enforced in review | Dev | Stories 2.2, 2.4, then each rules story |
| R-03 | DATA | Offline-queued writes lost or rejected without the user knowing (NFR-4, AD-10 no `clearPersistence()` while pending, AD-14 failures stream) | 2 | 3 | **6** | Network-off emulator tests (3.1, 4.5) made CI-runnable (TC-1); failures-stream BLoC tests (3.3); test that sign-out never calls `clearPersistence()` | Dev | Epic 3–4 |
| R-04 | SEC | Deleted user's data survives (extension misconfig, other device recreates `/users/{uid}`, Extensions shutdown 2027-03-31) — Play/GDPR requirement (FR-4, NFR-8, AD-10) | 2 | 3 | **6** | Rules test: no writes without user doc; stale `auth_time` create rejected; recorded dev purge (5.1); Monitoring alert + runbook; 5.9 with CI emulator test before deadline | Dev / Owner | Epic 5; 5.9 by 2027-03-31 |
| R-05 | OPS | Wrong Firebase project or missing SHA fingerprints → Google sign-in fails in the Play build; Google-only auth means total lockout (AD-12, FR-1, review-rubric F1) | 2 | 3 | **6** | Unit-tested flavor guard; README fingerprint checklist; sign-in verified on a real device from the internal track (5.8) before promotion | Dev / Owner | Stories 1.3, 5.8 |
| R-06 | DATA | logSession / restring update-shape rules wrong: allow decreasing hours or truncating `pastStringJobs`, or block legit writes (AD-5 nested diff, list-size + id checks) | 2 | 2 | 4 | Negative tests named in 3.1/4.5 (decreased hours, >24, changed material, remove past job, append two, reused id) | Dev | Stories 3.1, 4.5 |
| R-07 | DATA | Over-strict decode drops racquets from the bag (unknown material, pending timestamp, int vs double) — UX-DR28 "left out silently" (adversary F1, F10) | 2 | 2 | 4 | Mapper tests for pending timestamp, int-valued numbers, unknown material, bad past job (2.2) | Dev | Story 2.2 |
| R-08 | TECH | `google_sign_in` 7.x init/authenticate flow and web re-auth popup blocked after an await (AD-9, Story 5.2) | 2 | 2 | 4 | Inject SDK instances (TC-4); BLoC tests per `AuthFailure` incl. `popupBlocked`, `user-mismatch`; manual Android + Web check | Dev | Stories 1.5, 5.2 |
| R-09 | PERF | NFR-1 (60 fps), NFR-2 (< 500 ms), NFR-3 (< 1.5 s) unmeasured; bootstrap runs several awaited Firebase steps before first frame (AD-11) | 2 | 2 | 4 | Define method + reference device (TC-8); Remote Config fetch never awaited (unit test, 1.4); record measurements | Dev | Stories 1.4, 2.3 |
| R-10 | DATA | Local-date / time-zone errors: off-by-one stringing dates, today rejected late at night, negative durations (AD-15, 2.4, 4.1) | 2 | 2 | 4 | TZ-pinned tests (TC-5); 09:00/15:00 widget cases; DST span engine case | Dev | Stories 2.1, 2.4, 4.1, 4.6 |
| R-11 | SEC | Billing/storage abuse while App Check is monitor-only; doc counts are uncapped (`free_racquet_limit` unused, `pastStringJobs` no cap) | 2 | 2 | 4 | Rules size bounds (NFR-7); budget alerts (5.7); enforce App Check (5.10) | Owner | Stories 5.7, 5.10 |
| R-12 | BUS | Play review rejection: leftover health permissions, Data Safety mismatch, broken deletion URL (NFR-6, NFR-8) | 2 | 2 | 4 | Merged-manifest CI check (1.7, 5.7); privacy.html claims reviewed against telemetry; internal-track review | Dev / Owner | Stories 1.7, 5.3, 5.8 |
| R-13 | BUS | Accessibility floor missed (NFR-9 WCAG 2.2 AA, UX-DR26 200 % text, 48 dp targets) | 2 | 2 | 4 | `meetsGuideline` tap-target/label/contrast checks + 200 % text-scale widget tests on every UI story; SR pass (5.6) | Dev | Every UI story; 5.6 |
| R-14 | TECH | Brownfield cleanup (1.7) deletes most existing tests and surfaces; reused widgets regress unnoticed | 2 | 2 | 4 | Keep and port pure widget tests (radial gauge, theme); theme value assertions (1.2) | Dev | Stories 1.2, 1.7 |
| R-15 | DATA | Decay math wrong at tier boundaries, `maxHours` 0, future dates or DST (FR-9, FR-10) | 1 | 3 | 3 | Engine fixtures listed in 2.1 (39/40/69/70, 69.5, 39.5, fixtures 92 and 6) | Dev | Story 2.1 |
| R-16 | SEC | Previous user's state visible after sign-out / account switch, or post-sign-out permission-denied reported as crashes (FR-3, AD-10) | 1 | 3 | 3 | Data BLoCs under signed-in subtree; stream completes on uid change (repo tests 2.2); dropped permission-denied test | Dev | Stories 1.6, 2.2 |
| R-17 | OPS | App Check enforcement blocks genuine users (AD-12, SM-3) | 1 | 3 | 3 | Monitor-only until ≥ 98 %; typed App Check failure (5.10) | Owner | Story 5.10 |
| R-18 | OPS | Manual deploys leave prod rules out of step with installed app versions (Deploy convention; automated deploy deferred) | 1 | 2 | 2 | Dev-then-prod order; rules changes after launch must accept the previous app version's writes | Owner | Post-launch |

**Summary:** 18 risks — 0 CRITICAL, 5 HIGH (R-01…R-05), 9 MEDIUM, 4 LOW. No gate blocker. Highest priorities: rules correctness (R-01/R-02), offline integrity (R-03), deletion compliance (R-04), sign-in lockout via environment config (R-05).

### NFR Planning

| Category | Requirement | Threshold | Evidence source | Status |
| --- | --- | --- | --- | --- |
| Security | Tenant isolation + payload bounds | FR-18, NFR-7 (≤ 15 / ≤ 12 keys, AD-3 bounds) | `rules_test/` CI job | Defined |
| Security | App Check verification | SM-3 ≥ 98 % | Prod console metrics (5.10) | Defined |
| Security | No secrets in repo | AGENTS.md policy | Secret scanning | **UNKNOWN** tool/gate |
| Performance | Gauge smoothness | NFR-1 60 fps | Profile-mode frame chart | **UNKNOWN** device/method |
| Performance | Sync latency | NFR-2 < 500 ms | Two-client check on dev (2.3) | Defined (one-shot, manual) |
| Performance | Cold start to bag | NFR-3 < 1.5 s | Perf `_app_start` trace / stopwatch | **UNKNOWN** device/method |
| Performance | Logging speed | SM-1 > 90 % ≤ 10 s | None: `session_logged` carries no timing | **UNKNOWN** — no telemetry source |
| Reliability | Offline + atomic | NFR-4, NFR-5 | Emulator network-off tests | Defined (local-only today) |
| Reliability | Crash-free | SM-2 > 99.5 % (Android only) | Crashlytics | Defined; web has no crash reporting (accepted in PRD) |
| DR | Backups / PITR | 5.7 enabled | README operations | **UNKNOWN** RTO/RPO |
| Maintainability | CI gates | analyze, format, engine, flutter test, rules, build web | GitHub Actions | Defined; coverage threshold **UNKNOWN** |
| Compliance | Permissions, Data Safety, a11y | NFR-6, NFR-8, NFR-9 | Manifest check, privacy.html review, SR notes (5.6) | Defined |

**Clarifications needed:** reference device/method for NFR-1/NFR-3; SM-1 measurement source; RTO/RPO; coverage threshold (if any); secret-scanning gate.

## Step 4: Coverage Plan & Execution Strategy

**Level vocabulary (Flutter + Firebase):** UNIT (pure Dart: engine, domain, mappers, flavor), BLOC (`bloc_test` + `mocktail`), WIDGET (`flutter test` widget/component), REPO (repository vs `fake_cloud_firestore`), RULES (`@firebase/rules-unit-testing` on emulator — the API level for this system), EMU (Dart client vs Firestore/Auth emulator, network toggled), CI (static/config check), MANUAL (device/console verification recorded in story notes — Patrol E2E is retired).

### Coverage Matrix

| ID | Scenario | Level | Pri | Risk Link | Story |
| --- | --- | --- | --- | --- | --- |
| 1.5-RULES-001 | User doc: owner-only read; create ≤ 10 keys with fresh `auth_time`; update only email/displayName; `createdAt` immutable; other uid, stale `auth_time` denied | RULES | P0 | R-01, R-04 | 1.5 |
| 1.5-RULES-002 | Default deny: unauthenticated and any path outside `/users/{uid}/**` denied | RULES | P0 | R-01 | 1.5 |
| 2.4-RULES-001 | Racquet create: full AD-3 shape; reject > 15 keys, tension out of range, missing `pastStringJobs`, wrong owner, missing user doc | RULES | P0 | R-01, R-02 | 2.4 |
| 3.1-RULES-001 | Session create-only + logSession racquet update; reject decreased hours, > 24 increase, changed material, batch on deleted racquet | RULES | P0 | R-01, R-06 | 3.1 |
| 4.x-RULES-001 | updateRacquet, setPrimary, deleteRacquet, restring shapes, each ≥ 1 pos + ≥ 1 neg (restring: remove past job, append two, same job twice, reused id, hours > 0, maxHours 0) | RULES | P0 | R-01, R-06 | 4.2–4.5 |
| 2.2-UNIT-001 | Shared fixture corpus: valid fixtures decode + pass `schema_bounds`; invalid fail; same corpus drives RULES tests | UNIT + RULES | P0 | R-02 | 2.2, 2.4 |
| 3.1-REPO-001 | logSession batch: session fields, `stringJobId` = current job id, increment via `racquet_fields`, bounds failure → typed failure and no write | REPO | P0 | R-03, R-06 | 3.1 |
| 3.1-EMU-001 | Network off: logSession queued, hours visible locally at once, session + increment on server after reconnect | EMU | P0 | R-03 | 3.1 |
| 4.5-EMU-001 | Network off: restring `arrayUnion` queued, applied locally, present on server after reconnect | EMU | P0 | R-03 | 4.5 |
| 3.3-UNIT-001 | Unawaited commit failure → `MutationFailure` on failures stream + `ErrorReporter`; permission-denied after sign-out and `unavailable` suppressed | UNIT | P0 | R-03 | 3.3 |
| 3.3-BLOC-001 | Sign-out: dialog when `waitForPendingWrites` > 500 ms (fake_async); `clearPersistence()` never called on sign-out | BLOC | P0 | R-03 | 1.6, 3.3 |
| 5.2-BLOC-001 | Delete account: success (terminate + `clearPersistence` + Google sign-out), recent-login re-auth + retry, user-mismatch, cancel, failure keeps streams, web popup blocked → Retry | BLOC | P0 | R-04, R-08 | 5.2 |
| 5.1-MANUAL-001 | Dev purge: delete Auth user with racquets/past jobs/sessions → all gone; recorded | MANUAL | P0 | R-04 | 5.1 |
| 5.9-EMU-001 | `onUserDeleted` function recursively deletes `users/{uid}` (CI on emulator) | EMU | P0 | R-04 | 5.9 |
| 1.3-UNIT-001 | Flavor resolution: missing FLAVOR stops; Android mismatch stops; dev/prod pick matching options | UNIT | P0 | R-05 | 1.3 |
| 5.8-MANUAL-001 | Internal-track build on real device: Google sign-in, log, restring, delete account | MANUAL | P0 | R-05, R-12 | 5.8 |
| 1.6-WIDGET-001 | Auth gate: no core route reachable without a user | WIDGET | P0 | R-01, R-16 | 1.6 |
| 2.1-UNIT-001 | Engine: material constants, boundaries 39/40/69/70 and 39.5/69.5, 0/over-limit hours, `maxHours` 0 → ArgumentError, future date, DST span, fixtures 92 and 6 | UNIT | P0 | R-15 | 2.1 |
| 2.2-UNIT-002 | Mapper: absent → null, int → double, pending timestamp → `clock.now()`, unknown material excluded + reported, bad past job skipped, dedupe by id, `isPendingSync` | UNIT | P1 | R-07 | 2.2 |
| 2.2-REPO-001 | `watchRacquets` = one query; streams complete on uid change; late permission-denied dropped | REPO | P1 | R-16 | 2.2 |
| 2.2-UNIT-003 | `resolvePrimary` with 0/1/2 flags, tie by lowest id, empty → null | UNIT | P1 | R-06 | 2.2 |
| 1.5-REPO-001 | `ensureUserDoc`: create only when server-absent, update otherwise, offline deferral, `reload()` → gone → sign out | REPO | P1 | R-04, R-16 | 1.5 |
| 1.5-BLOC-001 | `AuthFailure` mapping (canceled, popupBlocked, network, unknown) → Welcome messages | BLOC | P1 | R-08 | 1.5, 1.6 |
| 1.6-WIDGET-002 | Restored session offline opens the shell without waiting for the server | WIDGET | P1 | R-09 | 1.6 |
| 1.4-UNIT-001 | Remote Config exact defaults; slow fetch doesn't delay first frame; `AnalyticsSink` allowlist, no email/displayName; web analytics disabled | UNIT | P1 | R-09, R-12 | 1.4 |
| 2.3-BLOC-001 | Bag recompute on snapshot and `AppResumed` (`withClock`); primary-first ordering | BLOC | P1 | R-15 | 2.3 |
| 2.3-WIDGET-001 | Card lines, critical treatment, pending line; skeleton; empty-from-cache = loading; empty bag | WIDGET | P1 | R-07 | 2.3 |
| 2.4-WIDGET-001 | Add form: `schema_bounds` messages, maxHours refill rule, focus to first invalid, double-submit ignored, discard prompt, `racquet_created` | WIDGET | P1 | R-02 | 2.4 |
| 2.4-UNIT-002 | TZ-pinned: picked date ≤ today (09:00, 15:00, 23:30 local), 12:00 local → UTC; Change Strings date ≥ current `strungAt` | UNIT | P1 | R-10 | 2.4, 4.6 |
| 3.2-WIDGET-001 | Quick-Log: default path ≤ 3 taps, pre-selection, vanished racquet fallback, double-tap ignored, snackbar, `session_logged` on local accept | WIDGET | P1 | R-03 | 3.2 |
| 4.1-WIDGET-001 | Timeline newest first, dedupe, floored non-negative days; deleted-elsewhere vs not-found messages | WIDGET | P1 | R-10 | 4.1 |
| 4.3-REPO-001 | setPrimary batch with 0/1/2 flagged beforehand | REPO | P1 | R-06 | 4.3 |
| 4.4-WIDGET-001 | Delete racquet: sessions kept as `Deleted racquet`; own-device delete never shows remote message | WIDGET | P1 | R-06 | 4.4 |
| 4.5-BLOC-001 | Keep Same copies material/brand/tension/maxHours, new id, `manual_restring`; Change Strings reasons; double-tap ignored; `racquet_restrung` | BLOC | P1 | R-06 | 4.5, 4.6 |
| 1.7-CI-001 | Merged-manifest check fails on any health/sensor/activity/fitness permission | CI | P1 | R-12 | 1.7, 5.7 |
| 1.3-CI-001 | Import boundary: only `lib/data/` imports `cloud_firestore`/`firebase_auth`/`google_sign_in` | CI | P1 | R-02 | 1.3 |
| ALL-WIDGET-A11Y | Per UI story: `meetsGuideline` tap-target/labeled/contrast + 200 % text-scale no-overflow | WIDGET | P1 | R-13 | 1.6–5.4 |
| 5.6-MANUAL-001 | Flows 1–4 with TalkBack, NVDA + Chrome, VoiceOver + Safari | MANUAL | P1 | R-13 | 5.6 |
| 5.3-MANUAL-001 | Hosting smoke on dev: `/privacy.html` served as static HTML, deep link resolves via rewrite | MANUAL | P1 | R-12 | 5.3 |
| 3.3-WIDGET-001 | Bag Sync Summary count and copy, no extra query | WIDGET | P2 | R-03 | 3.3 |
| 3.4-WIDGET-001 | Sessions feed paging, racquet filter, `Deleted racquet` only after server emit, empty states | WIDGET | P2 | R-07 | 3.4 |
| 1.2-WIDGET-001 | Theme tokens asserted by value; pure widget tests (radial gauge) ported before cleanup | WIDGET | P2 | R-14 | 1.2, 1.7 |
| 2.3-MANUAL-001 | Two-client sync latency on dev vs 500 ms (NFR-2) | MANUAL | P2 | R-09 | 2.3 |
| PERF-MANUAL-001 | Cold start to bag (NFR-3) and gauge frames (NFR-1) on the reference device, profile build | MANUAL | P2 | R-09 | 2.3 |
| 5.4-WIDGET-001 | `L`/`N` shortcuts only on bag with no sheet/focus and switch on; `Esc` closes topmost | WIDGET | P2 | R-13 | 5.4 |
| 5.10-UNIT-001 | App Check rejection maps to its own typed failure, distinct from post-sign-out permission-denied | UNIT | P2 | R-17 | 5.10 |
| 5.7-MANUAL-001 | Budget alerts and PITR/backups configured and recorded | MANUAL | P2 | R-11 | 5.7 |
| POST-RULES-001 | After launch: rules still accept the previous app version's write fixtures | RULES | P3 | R-18 | post-launch |

**Totals:** 18 P0 · 21 P1 · 8 P2 · 1 P3 (48 scenarios). Every register risk R-01…R-18 has ≥ 1 row.

### NFR Coverage & Evidence Plan

| NFR | Validation | Evidence artifact for `nfr-assess` |
| --- | --- | --- |
| Security (FR-18, NFR-7) | RULES suites | `rules_test` CI job report |
| Security (secrets) | Secret scanning | **UNKNOWN** — gate not defined |
| Security (App Check, SM-3) | Console metrics | README operations entry (5.10) |
| Reliability (NFR-4/5) | EMU network-off tests | CI job log or story verification notes |
| Reliability (SM-2) | Crashlytics crash-free | Crashlytics dashboard (Android) |
| Performance (NFR-1/2/3) | MANUAL measurements | Story verification notes — device/method **UNKNOWN** |
| Performance (SM-1) | — | **UNKNOWN** — no telemetry carries logging duration |
| Compliance (NFR-6/8/9) | CI manifest check, privacy review, SR pass | CI log, 5.3/5.6/5.8 notes |
| Maintainability | CI gates + coverage | `flutter test --coverage` lcov for engine/domain/data |
| DR | PITR/backups | README operations (5.7); RTO/RPO **UNKNOWN** |

### Execution Strategy

- **PR (target < 15 min):** analyze, format, engine `dart test`, `flutter test` (UNIT/BLOC/WIDGET/REPO, plus TZ-pinned date files), RULES on the emulator, `flutter build web`, manifest and import-boundary checks. Add the EMU Chrome job here if it fits the budget.
- **Nightly (on `main`):** the EMU Chrome job if it doesn't fit the PR budget.
- **Per story:** deploy rules/indexes to dev; record MANUAL items in verification notes.
- **Release (before Play promotion):** 5.8 device checklist, 5.6 SR pass, perf measurements, 5.1 purge verification.

### Resource Estimates (one developer, inside story work)

- P0: ~30–45 h (rules suites + fixture corpus, emulator CI job setup ~6–10 h)
- P1: ~35–55 h
- P2: ~12–20 h
- P3: ~2–4 h
- **Total: ~80–125 h**, spread across Epics 1–5

### Quality Gates

- P0 pass rate 100 %; P1 ≥ 95 % (failures need a waiver with owner)
- Every AD-5 write shape and the user doc: ≥ 1 positive and ≥ 1 negative RULES test
- HIGH risks R-01…R-05 mitigated before production promotion (Story 5.8)
- Coverage ≥ 80 % lines for `string_theory_decay_engine/lib`, `lib/domain`, `lib/data` (UI excluded; widget ACs cover it). Proposed, not yet agreed
- NFR evidence source named for every in-scope NFR; PASS/CONCERNS/FAIL deferred to `nfr-assess`

## Step 5: Outputs Generated & Validated

- **Execution mode:** sequential (auto resolved; subagents not used in this session)
- **Outputs:**
  - `_bmad-output/test-artifacts/test-design-architecture.md`
  - `_bmad-output/test-artifacts/test-design-qa.md`
  - `_bmad-output/test-artifacts/test-design/string_theory-handoff.md`
- **Checklist:** passed. Fixes applied: residual-risk statement (architecture), bug-severity exit criterion (QA). N/A: Playwright/playwright-utils example items (Flutter/Dart stack, no Playwright), "Quality & Testing Progress" log (no such tracker), stakeholder acceptance of exclusions (pending Francesco's review).
- **Browser sessions:** none opened.
- **Open decisions:** D-1 offline tests in CI, D-2 perf reference device/method, D-3 SM-1 measurement source.
- **Completed:** 2026-10-30
