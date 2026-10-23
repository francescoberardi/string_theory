# Reconciliation Report: `brainstorm-intent.md` vs. PRD & Addendum

**Reconciliation Date:** 2026-10-23  
**Input Document:** `_bmad-output/brainstorming/brainstorm-firebase-migration-and-store-launch-2026-10-23/brainstorm-intent.md`  
**Target Specifications:**
- PRD: `_bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/prd.md`
- Addendum: `_bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/addendum.md`

---

## 1. Executive Summary

The updated **PRD (`prd.md`)** and **Addendum (`addendum.md`)** achieve an exceptionally high degree of fidelity with the strategic intent articulated in `brainstorm-intent.md`. The pivot from the legacy Serverpod hackathon prototype to a serverless, store-ready Firebase architecture on Google Play (Android) and Firebase Hosting (Flutter Web) is comprehensively captured across architecture, data models, store compliance, telemetry, and phased monetization.

A few minor gaps, dropped cleanup requirements, and architectural refinements were identified—most notably the omission of explicit hackathon demo action removal and local notification pruning (M8), plus the divergence between dynamic decay calculation on read versus lazy score write-back.

---

## 2. Detailed Alignment Matrix

| Category | `brainstorm-intent.md` Intent | PRD / Addendum Implementation | Status | Notes |
|---|---|---|---|---|
| **Strategic Pivot** | Move from Serverpod prototype to public release on Google Play & Firebase Hosting | PRD §0, §1 | **Fully Aligned** | Clearly framed as serverless migration for launch speed & low ops overhead. |
| **Auth Strategy** | Google Sign-In only via Firebase Auth; eliminate email/password & guest mode | PRD §2.2, §4.1 (FR-1, FR-2, FR-3), §5 Non-Goals | **Fully Aligned** | Mandatory Google Auth eliminates guest sync logic and simplifies store compliance. |
| **Store Deletion Compliance** | Unified mobile + web account deletion via `FirebaseAuth.delete()` + `delete-user-data` extension | PRD §4.1 (FR-4), §4.6 (FR-20), §9 (OQ-3), Addendum §1.5 | **Fully Aligned** | Web app URL declared in Google Play Console Data Safety section. |
| **Permission Pruning** | Remove Apple Health / Health Connect to bypass sensitive permission review | PRD §2.2, §5 Non-Goals, §8.3 (NFR-6), §10 | **Fully Aligned** | Declares 0 health/body sensor permissions in `AndroidManifest.xml`. |
| **Decay Calculation** | Client-side pure Dart composite calculation on read; no Cloud Functions/cron | PRD §1, §4.3 (FR-9, FR-10, FR-11), Addendum §1.3 | **Refined** | PRD computes 100% on read dynamically; drops brainstorm's "lazy write-back to Firestore on session open" to prevent write amplification. |
| **Real-Time Sync** | Replace Serverpod WebSockets with Firestore `.snapshots()` | PRD §4.4 (FR-14), §8.1 (NFR-2) | **Fully Aligned** | Sub-500ms sync across active screens and multi-window/device sessions. |
| **Racquet Model** | Denormalized active `StringJob` embedded on `Racquet` document | PRD §3, §4.2 (FR-5, FR-6), Addendum §1.1 | **Fully Aligned** | Single collection read (`/users/{uid}/racquets`), zero joins. |
| **String Lifecycle** | Unified `stringHistory` / `pastStringJobs` array on `Racquet` | PRD §3, §4.5 (FR-15, FR-16, FR-17), Addendum §1.1 | **Mostly Aligned** | Formalized as `pastStringJobs` array. Nuance: reason taxonomy slightly truncated in FR-16. |
| **Session Model** | Dedicated `/users/{uid}/sessions` collection; atomic `WriteBatch` | PRD §3, §4.4 (FR-12, FR-13), Addendum §1.1, §1.2 | **Fully Aligned** | Single commit writes session document and increments `hoursPlayed`. |
| **Security & App Check** | Firestore rules (`/users/{uid}/**`) + App Check (Play Integrity & reCAPTCHA Enterprise) | PRD §4.6 (FR-18, FR-19), §8.3 (NFR-7), Addendum §1.4 | **Fully Aligned** | Day-1 anti-abuse and payload boundary validation ($\le 15$ keys racquet, $\le 12$ session). |
| **Telemetry & Remote Config** | Day-1 Crashlytics, Performance Monitoring, Analytics + Remote Config sensor flags | PRD §4.6 (FR-21, FR-22), §6, Addendum §2.1 | **Fully Aligned** | Initialized on launch with flags: `show_ads`, `pro_paywall_trigger`, `free_racquet_limit`. |
| **Phased Monetization** | v1.1 Ads & Pro tier; v1.2+ String Lab Pro Insights & FCM push notifications | PRD §6 (MoSCoW), Addendum §2.1, §2.2 | **Fully Aligned** | Clear roadmap boundaries preserving v1.0 zero-review-friction scope. |
| **Codebase & CI Cleanup (M8)** | Remove demo actions, skip local notifications, disable Patrol in CI | PRD §5 Non-Goals, §6 MoSCoW, Addendum | **Gap** | Omitted hackathon demo action removal, local notification deprecation, and Patrol CI notes. |

---

## 3. Detailed Gaps, Omissions & Dropped Nuances

### Gap 1: Hackathon Demo Actions Cleanup (M8 Omission)
- **Source:** `brainstorm-intent.md` §2 & §6 (M8): *"remove hackathon demo-only fake actions ('Create Sample Bag', 'Simulate Workout')"*.
- **Current State in PRD/Addendum:** Omitted. Neither `prd.md` nor `addendum.md` explicitly lists removing the legacy demo buttons and mock generator logic.
- **Impact:** Low risk of rejection, but moderate risk of technical debt or confusing UI artifacts remaining visible to real store users if not explicitly captured in implementation stories.
- **Recommendation:** Add an explicit requirement in the developer sprint backlog to purge the mock data generators and hackathon demo action bars from the Flutter UI.

### Gap 2: Local Decay Notification Deprecation / Pruning (M8 Omission)
- **Source:** `brainstorm-intent.md` §2 & §6 (M8): *"Skip local decay notifications in v1 (defer until Firebase Cloud Messaging push notifications in v1.2+)"*.
- **Current State in PRD/Addendum:** PRD §6 and Addendum §2.2 place FCM push notifications in `Could Have (v1.2+)`, but neither document explicitly notes that local notification libraries (e.g. `flutter_local_notifications`) should be pruned or skipped for v1.
- **Impact:** Ambient confusion for the developer regarding whether to maintain hackathon local scheduled alerts or remove them completely.
- **Recommendation:** Explicitly document in architecture notes that local notification scheduling is decommissioned for v1.0 to avoid background execution permission friction on Android 13+.

### Gap 3: Restring End Reason Granularity & Future String Lab Dataset
- **Source:** `brainstorm-intent.md` §3: *"archives the active StringJob into a stringHistory / pastStringJobs array... with an endedAt timestamp and reason (e.g., dead, broken, manual)"*.
- **Current State in PRD/Addendum:** PRD Glossary (§3) lists `endReason: ('dead', 'broken', 'manual_restring')`, but FR-16 hardcodes `endReason: "restrung"`, and UJ-3 / FR-15 only provide `[Keep Same & Reset]` and `[Change Strings]` without capturing *why* the string was replaced.
- **Impact:** If the app records all historical retirements as generic `"restrung"`, the future v1.2+ **String Lab Pro Insights** feature cannot accurately calculate "hours to snap" vs. "hours to dead string" curves.
- **Recommendation:** In FR-15/FR-16 and Addendum §1.1, ensure the restring dialog includes a lightweight optional reason toggle (e.g., "Felt Dead" vs. "Snapped/Broke" vs. "Routine/Pre-Match").

### Gap 4: Architectural Divergence — Dynamic Read vs. Lazy Firestore Write-Back
- **Source:** `brainstorm-intent.md` §2: *"Compute string decay purely on the client upon read using the pure Dart DecayEngine, lazily writing updated scores back to Firestore on session open."*
- **Current State in PRD/Addendum:** PRD FR-9, FR-11 and Addendum §1.1 / §1.3 define `HealthScore` as a purely computed client-side runtime value. It is **not** stored as a field in the Firestore `Racquet` document, nor is it lazily written back.
- **Impact:** **Positive divergence.** Calculating `HealthScore` purely on read avoids unnecessary Firestore write operations and potential write-amplification on app open.
- **Recommendation:** Keep the PRD approach (100% computed on read), but explicitly document in the architecture specification that omitting lazy write-back was an intentional architectural improvement.

### Gap 5: Patrol E2E Testing Strategy (Documented in AGENTS.md, missing in PRD)
- **Source:** `brainstorm-intent.md` §2 & §6 (M8): *"Temporarily disable Patrol E2E tests in CI/CD to accelerate initial launch builds and deployment."*
- **Current State in PRD/Addendum:** Covered in repo policy (`AGENTS.md`), but omitted from the PRD and Addendum test architecture section.
- **Recommendation:** No change needed in PRD since CI/CD test harness details belong in repository instructions and architecture planning.

---

## 4. Alignment Conclusion

The PRD and Addendum are **ready for technical architecture and sprint execution**. The core strategic pivot is sound and complete. Incorporating the 3 actionable recommendations (cleaning demo actions, clarifying local notification pruning, and adding reason options to the restring flow) will fully close the remaining gap between intent and implementation.
