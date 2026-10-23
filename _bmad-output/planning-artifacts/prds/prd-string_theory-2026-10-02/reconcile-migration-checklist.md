# Reconciliation Report: Migration Checklist vs. Updated PRD & Addendum

**Reconciled Input Document:** `_bmad-output/brainstorming/brainstorm-firebase-migration-and-store-launch-2026-10-23/migration-checklist.md`  
**Target Documents:**  
- PRD: `_bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/prd.md`  
- Addendum: `_bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/addendum.md`  
**Output Path:** `_bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/reconcile-migration-checklist.md`  
**Date:** 2026-10-23  

---

## 1. Executive Summary

This report reconciles the post-hackathon execution checklist (`migration-checklist.md`) against the modernized Product Requirements Document (`prd.md`) and technical addendum (`addendum.md`). 

The core product and architectural intent—migrating from Serverpod to a serverless Firebase architecture with Google Sign-In, Cloud Firestore real-time streams, pure client-side `DecayEngine`, atomic `WriteBatch` session logging, App Check abuse protection, and GDPR/Play Store compliance—is strongly aligned across both sources.

However, detailed comparison revealed **4 uncaptured operational/technical requirements**, **1 architectural conflict** regarding decay score persistence, and **2 data schema discrepancies** between the checklist and the PRD.

---

## 2. Item-by-Item Reconciliation Matrix

| Section / Item | Checklist Specification | Status in PRD / Addendum | Reconciliation Notes |
|---|---|---|---|
| **1. Codebase Cuts & Cleanup** | | | |
| Remove Serverpod backend & client | Delete `string_theory_server/`, `string_theory_client/`, `docker-compose.yaml`, migrations, cron | **Captured** (PRD §0, §5, §6) | PRD covers architectural removal. Specific deletion of `docker-compose.yaml` and migrations are implementation details. |
| Remove Apple Health & Health Connect | Remove plugins, manifest permissions, iOS HealthKit entitlements, workout UI | **Partially Captured** (PRD §5, NFR-6) | PRD captures removing Health Connect from `AndroidManifest.xml`. Removing iOS entitlements and `Info.plist` usage descriptions is omitted from PRD. |
| Remove Guest Mode & Email/Password | Delete email auth, guest storage, local sync logic | **Captured** (PRD §2.2, FR-1, §5) | Fully aligned. Core routes require verified Google Sign-In. |
| Remove Demo Actions & Local Notifications | Delete demo actions (`Create Sample Bag`, `Simulate Workout`), delete `RestringEvent`, remove local decay notifications | **Partially Captured** (PRD §3, FR-16, §6) | `RestringEvent` removal is captured. Deleting hackathon demo actions and stripping existing local notification scheduling code are omitted. |
| Update CI/CD Pipeline (Pause Patrol E2E) | Disable Patrol E2E jobs in GitHub Actions; retain `analyze`, `format`, unit/widget tests | **Omitted / Gap** | Completely absent from PRD and Addendum (only documented in repo `AGENTS.md`). |
| **2. Firebase Project & FlutterFire** | | | |
| Initialize Firebase & FlutterFire | Android/Web apps, `flutterfire configure`, `firebase_options.dart` | **Captured** (PRD §0, §1, FR-1) | Standard FlutterFire setup. |
| Firebase Auth (Google Sign-In Only) | Google provider only; Android SHA-1/SHA-256 certs; Web OAuth client & domains | **Partially Captured** (PRD FR-1, FR-2) | Google-only auth is fully captured; specific SHA-1/SHA-256 certificate configuration steps are omitted. |
| Cloud Firestore | Provision production database; offline persistence on mobile/web | **Captured** (PRD FR-2, FR-13, NFR-4) | Fully aligned. |
| Telemetry | Crashlytics (`FlutterError.onError`, `PlatformDispatcher.onError`), Performance, Analytics (4 baseline events) | **Captured** (PRD FR-21, SM-2) | Fully aligned; all 4 baseline conversion events (`sign_in`, `racquet_created`, `session_logged`, `racquet_restrung`) captured. |
| Firebase Remote Config | Defaults (`show_ads: false`, `pro_paywall_trigger: false`, `free_racquet_limit: 99`); fetch & activate on startup | **Captured** (PRD FR-22, Addendum §2.1) | Fully aligned. |
| Firebase App Check | Play Integrity (Android) + reCAPTCHA Enterprise (Web); Firestore enforcement | **Captured** (PRD FR-19, SM-3, Addendum §1.4) | Fully aligned. |
| Firebase Hosting | Deploy `build/web`; SPA rewrites to `/index.html`; static `/privacy.html` | **Captured** (PRD FR-20) | Fully aligned. |
| **3. Domain Model Refactor** | | | |
| Unified `Racquet` + `StringJob` | Embedded `currentStringJob`, historical `pastStringJobs` array on `Racquet` | **Discrepancy in Schema** (PRD FR-5, Addendum §1.1) | Checklist schema lists `brand, model, gauge, tensionLbs, strungAt, hoursPlayed`. PRD/Addendum schema lists `brand, material, tensionLbs, strungAt, hoursPlayed, maxHours`. |
| `SessionLog` Collection & `WriteBatch` | Subcollection `/users/{uid}/sessions`; atomic `WriteBatch` increments `hoursPlayed` | **Captured** (PRD FR-13, Addendum §1.1, §1.2) | Fully aligned. |
| Client-Side `DecayEngine` | 70% hours + 30% calendar; green/amber/red tiers; "lazily write back updated health metadata if needed" | **Architectural Conflict** (PRD FR-11, Addendum §1.3) | Checklist suggests optional lazy write-back to Firestore. PRD FR-11 and `AGENTS.md` strictly prohibit writing decay math back to Firestore (pure client read). |
| **4. Security Rules Starter Snippet** | | | |
| Production `firestore.rules` | Concrete rules: user isolation, string lengths, key size limits ($\le 15$ racquet, $\le 12$ session), numeric bounds | **Partially Captured** (PRD FR-18, NFR-7, Addendum §1.4) | PRD/Addendum capture constraints high-level, but omit the concrete starter code. Rule duration is `> 0` in checklist vs `>= 0.1` in Addendum. Rules omit `material` check. |
| **5. GDPR & Store Compliance** | | | |
| `delete-user-data` Extension | Recursive delete `/users/{UID}` and subcollections upon Auth user delete | **Captured** (PRD FR-4, Addendum §1.5) | Fully aligned. |
| In-App & Web Account Deletion | Settings dialog; `FirebaseAuth.currentUser.delete()`; re-auth on `requires-recent-login` | **Captured** (PRD UJ-4, FR-4, Addendum §1.5) | Fully aligned. |
| Static `/privacy.html` on Hosting | Privacy policy, ToS, account deletion instructions | **Captured** (PRD FR-20, NFR-8) | Fully aligned. |
| Play Console Declarations | Privacy URL, Deletion URL, Data Safety breakdown (Personal info, App activity, Performance, Encryption, Deletion) | **Partially Captured** (PRD NFR-8, §9 OQ-3) | URLs are covered; itemized breakdown of Data Safety form answers is omitted from PRD/Addendum. |
| **6. v1.1+ Iteration Prep** | | | |
| Monetization Hooks (v1.1) | Remote Config flags, Analytics custom definitions | **Captured** (PRD §6, FR-22, Addendum §2.1) | Fully aligned. |
| Richer Metadata & Longevity Insights | Optional `surface`, `location`, `notes` in rules; `pastStringJobs` history for String Lab Pro | **Captured** (PRD FR-16, §6, Addendum §1.1, §2.2) | Fully aligned. |
| FCM Push Notification Hook (v1.2+) | Reserve optional `fcmTokens` field on `/users/{uid}` | **Omitted / Gap** | PRD §6 and Addendum §2.2 mention FCM in v1.2+, but reserving `fcmTokens` on `/users/{uid}` is not documented. |
| Web Funnel Landing Widget (v1.2+) | Unauthenticated interactive "String Health Calculator" with Google CTA | **Captured** (PRD §6, Addendum §2.2) | Fully aligned. |

---

## 3. Top Gaps & Uncaptured Items

### Gap 1: CI/CD Pipeline Changes (Pausing Patrol E2E Tests)
* **Location in Checklist:** Section 1 (lines 29–31).
* **Missing in PRD/Addendum:** The PRD and Addendum do not mention disabling or commenting out Patrol E2E test jobs in GitHub Actions workflows to accelerate build/deploy cycles for v1 launch.
* **Impact:** Without documenting this, CI builds may fail on retired hackathon E2E test runners or waste build minutes.

### Gap 2: Reservation of `fcmTokens` on `/users/{uid}` Schema
* **Location in Checklist:** Section 6 (lines 209–210).
* **Missing in PRD/Addendum:** Addendum §1.1 defines the Firestore hierarchy but does not specify schema fields on `/users/{uid}`. Reserving an optional `fcmTokens` map/array ensures that adding FCM push notifications in v1.2 will not break user document security rules.
* **Impact:** Security rules checking `request.resource.data.keys().size() <= 10` on `/users/{userId}` might reject writes in v1.2 if not accounted for.

### Gap 3: Google Play Console Data Safety Form Itemized Answers
* **Location in Checklist:** Section 5 (lines 191–196).
* **Missing in PRD/Addendum:** PRD NFR-8 requires Data Safety alignment, but the itemized answers (Personal info: Name/Email; App activity: Racquet/Session data; App info: Crashlytics/Performance; Encryption in transit: `true`; Deletion mechanism: `true`) are only documented in the checklist.
* **Impact:** Useful operational guidance for store submission that should be preserved for deployment.

### Gap 4: Codebase Cleanup Details (Hackathon Mocks & iOS Entitlements)
* **Location in Checklist:** Section 1 (lines 19, 26, 28).
* **Missing in PRD/Addendum:** Specific tasks to delete hackathon mock buttons (`Create Sample Bag`, `Simulate Workout`), remove local decay notification scheduling, and strip unused iOS HealthKit entitlements/`Info.plist` keys from the Flutter runner.
* **Impact:** Leaving dead mock actions or iOS health entitlements in the codebase creates technical debt and could trigger App Store review questions if iOS builds are ever produced.

---

## 4. Architectural Conflicts & Discrepancies

### Conflict 1: "Lazy Write-Back" of Health Metadata vs. Pure Client-Side Evaluation
* **Checklist Description:** Section 3 (line 87) notes: *"Lazily write back updated health metadata to Firestore on session open or session log if needed—no server cron required."*
* **PRD & Repository Policy:** PRD §1, FR-11, and repo `AGENTS.md` explicitly enforce: *"Compute live string health scores client-side on read using `DecayEngine` + Firestore `.snapshots()` — do not add scheduled Cloud Functions or server cron jobs for decay calculation."*
* **Resolution:** PRD FR-11 is authoritative. Health scores must **never** be written back to Firestore. Writing health scores back creates redundant Firestore write costs, triggers recursive `.snapshots()` events, and violates the zero-write read design. The checklist note should be marked as invalid/rejected.

### Conflict 2: `StringJob` Schema Attributes (`material` & `maxHours` vs `model` & `gauge`)
* **Checklist Description:** Checklist Section 3 lists `currentStringJob: { brand, model, gauge, tensionLbs, strungAt, hoursPlayed, endedAt, endReason }` and rule `isValidStringJob` only requires `['brand', 'tensionLbs', 'strungAt', 'hoursPlayed']`.
* **PRD & Addendum Description:** PRD FR-5 and Addendum §1.1 define:
  - `material`: Enum (`coPoly`, `multifilament`, `syntheticGut`, `naturalGut`) — required to determine `maxCalendarShelfLife`.
  - `maxHours`: Double (e.g. 20.0) — required to evaluate dynamic wear in `DecayEngine`.
  - String gauge is concatenated into `brand` (e.g., `"Luxilon ALU Power 1.25"`).
* **Resolution:** PRD FR-5 and Addendum §1.1 are authoritative because `material` and `maxHours` are mathematically required by `DecayEngine`. The security rule `isValidStringJob` in the checklist should be updated to validate `material` and `maxHours`.

### Conflict 3: Minimum Session Duration Rule Bound
* **Checklist Rule:** `data.durationHours > 0 && data.durationHours <= 24`
* **Addendum §1.4:** `Duration between 0.1 and 24 hours`
* **Resolution:** Harmonize on `durationHours >= 0.1 && durationHours <= 24.0` (or `> 0`) across both specifications to avoid rejecting valid short sessions (e.g., a 15-minute 0.25h hit).

---

## 5. Recommended Updates to PRD Addendum

To ensure Winston (System Architect) and Amelia (Developer) do not drop operational requirements during story decomposition:
1. **Append CI/CD & Cleanup directives** to `addendum.md` §1 (disable Patrol E2E workflows, remove demo UI actions, scrub iOS health entitlements).
2. **Add `/users/{uid}` schema definition** to `addendum.md` §1.1 reserving `fcmTokens` (optional list of strings) and user profile metadata.
3. **Embed the complete `firestore.rules` starter snippet** from checklist Section 4 into `addendum.md` §1.4, updated to include `material` and `maxHours` validation on `currentStringJob`.
4. **Append Google Play Console Data Safety declaration answers** to `addendum.md` §1.5.
