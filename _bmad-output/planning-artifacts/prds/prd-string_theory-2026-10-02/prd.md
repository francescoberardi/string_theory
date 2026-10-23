---
title: "PRD: String Theory"
status: final
created: 2026-10-02
updated: 2026-10-23
---

# PRD: String Theory
*Intelligent Tennis Gear Decay & String Health Monitoring*

## 0. Document Purpose

This Product Requirements Document (PRD) establishes the functional, architectural, and quality specifications for **String Theory v1.0**, targeting a public release on the **Google Play Store (Android)** and **Firebase Hosting (Flutter Web)**. It serves as the single source of truth for the System Architect (Winston) and Developer (Amelia). It supersedes the Serverpod hackathon prototype specifications, transitioning the platform to a serverless Firebase architecture with strict Google Play store compliance, Day-1 security/billing protection via App Check, and built-in telemetry + Remote Config sensors ready for future monetization.

---

## 1. Vision

Modern tennis strings—particularly co-polyester—lose elasticity rapidly through court impacts and passive static relaxation while resting in a tennis bag. When strings go "dead," their ball-pocketing capability collapses, and high-frequency shock vibration bypasses the ball, transferring directly into the player's wrist, forearm, and elbow. This is a primary mechanical cause of lateral epicondylitis ("tennis elbow"). Recreational and club players routinely keep strings in their racquets for 6 to 12 months, unaware of the degradation until chronic pain develops or their control vanishes.

**String Theory** is an intelligent, low-friction virtual gear bag that actively monitors string degradation through a composite **Health Score (0–100%)**. Powered by a pure Dart client-side **Decay Engine** (70% active court hours + 30% calendar shelf-life), String Theory calculates live equipment elasticity dynamically upon read, eliminating server cron overhead.

Backed by **Firebase** (Google Sign-In, Cloud Firestore real-time `.snapshots()`, App Check, Crashlytics, and Hosting) and **Flutter**, String Theory delivers an effortless, ultra-fast sub-10-second manual session logging flow, atomic gear updates, and full Google Play store compliance (including in-app and web-accessible account deletion) from Day 1.

---

## 2. Target User

### 2.1 Jobs To Be Done (JTBD)
* **Functional:** Know exactly how many court hours and calendar days are on each of my racquets without notes or mental math.
* **Health & Safety:** Protect my elbow and shoulder by receiving clear visual warnings before dead strings transmit destructive shock.
* **Effortless Capture:** Log my post-match tennis sessions in under 10 seconds with a streamlined 3-tap quick logger.
* **Equipment Maintenance:** Keep a clean history of string models, tensions, and stringing dates to discover which setups perform best and last longest.
* **Trust & Privacy:** Sign in securely with Google and delete my account and data at any time with 1 click in-app or via the web. [ASSUMPTION: §2.1] (Google Sign-In will not significantly depress conversion compared to guest mode, while permanently eliminating guest-to-cloud data migration issues).

### 2.2 Non-Users (v1)
* **Touring Professionals:** Players who restring every 1–2 days and track tension with on-site tournament stringers using ERT 300 / Babolat RDC machines.
* **Multi-Sport Generalists (v1):** Players seeking an all-in-one tracker for squash, badminton, golf, and running. v1 is intentionally laser-focused on tennis strings and racquets.
* **Unauthenticated / Anonymous Guests:** Users refusing to sign in. v1 requires Google cloud authentication to ensure persistent cloud state, multi-device sync, and zero-friction store compliance.

### 2.3 Key User Journeys

#### UJ-1: Marco Logs Playtime in 5 Seconds After a Match
* **Persona & Context:** Marco (34), intermediate club player. Just finished a 90-minute doubles match.
* **Entry State:** Authenticated via Google Sign-In; phone in his tennis bag.
* **Path:**
  1. Marco opens String Theory on his phone and lands on his Virtual Bag dashboard.
  2. He taps the persistent floating action button `[+ Log Session]`.
  3. A quick-logger bottom sheet opens with pre-selected duration chips (`30m`, `1h`, `1.5h`, `2h`) and his racquets.
  4. Marco taps `[1.5h]` (or leaves it if default), confirms his primary racquet `[Wilson Blade 98]` is highlighted, and taps `[Save Session]`.
* **Climax:** An atomic Firestore `WriteBatch` records the session document and increments the Wilson Blade's hours played. The health gauge smoothly animates downward from 76% (Green) to 67% (Amber), displaying: *"~1.4 lbs tension drop. 11 court hours remaining before dead zone."*
* **Resolution:** Marco pockets his phone. The entire interaction took less than 5 seconds.

#### UJ-2: Elena Onboards and Adds Her First Racquet
* **Persona & Context:** Elena (28), recreational player recovering from mild wrist soreness. Downloaded String Theory on recommendation from her coach.
* **Entry State:** First launch of the Flutter app on Android or Web.
* **Path:**
  1. Elena sees a clean, branded welcome screen explaining string health and arm protection, featuring a prominent `[Sign in with Google]` button.
  2. Elena taps `[Sign in with Google]`. Authentication completes in 1 tap via Google Play Services (or Web OAuth popup).
  3. Elena is guided directly into `[Add Your First Racquet]`.
  4. She types "Babolat Pure Drive", selects String Material Category `[Monofilament]`, enters "Babolat RPM Blast 1.25", and sets Stringing Date (defaults to today; she picks 3 weeks ago). The app pre-populates Manufacturer Max Hours to 20h.
  5. Elena taps `[Save Racquet]`.
* **Climax:** Her Virtual Bag appears with the Babolat Pure Drive card showing an initial calculated Health Score of 88% based on 3 weeks of calendar shelf-life.
* **Resolution:** Her gear bag is live, saved securely to `/users/{uid}/racquets`, and automatically synchronized across devices.

#### UJ-3: David Gets Restrung and Resets the Gauge
* **Persona & Context:** David (42), weekend warrior. His Head Radical racquet has 19 hours of play and 70 days elapsed; its gauge sits at 34% (Red: Dead String Alert).
* **Entry State:** David opens the app before heading to his match.
* **Path:**
  1. David has just picked up his racquet from the local pro shop strung with fresh Head Lynx strings.
  2. He opens String Theory and navigates to the Head Radical card in his Virtual Bag.
  3. He taps the prominent button: `[Restrung Today]`.
  4. A confirmation sheet asks: *"Restrung with the same setup (Head Lynx 1.25 @ 52 lbs)?"*
  5. David taps `[Keep Same & Reset]`.
* **Climax:** The current string job is moved to `pastStringJobs` on the racquet document with retirement timestamp and stats, and a fresh active string job is set with 0 hours played. The gauge instantly resets to 100% (Solid Green).
* **Resolution:** David closes the app, confident his equipment is fresh and his history is preserved.

#### UJ-4: Play Store User Exercises Mandatory Account Deletion
* **Persona & Context:** App user or Google Play reviewer testing GDPR and store compliance.
* **Entry State:** User signed into String Theory on Android or visiting the hosted Web app.
* **Path:**
  1. User navigates to `[Settings]` (or visits the web URL declared in the Play Console Data Safety section).
  2. User taps `[Delete Account & All Data]`.
  3. A high-contrast confirmation modal appears warning that all racquets, string history, and sessions will be permanently purged.
  4. User confirms. The app invokes `FirebaseAuth.instance.currentUser.delete()`.
* **Climax:** Firebase Authentication deletes the user account. The server-side Firebase `delete-user-data` extension triggers immediately, recursively deleting `/users/{uid}` and all subcollections (`racquets`, `sessions`).
* **Resolution:** The user is signed out and redirected to the welcome screen. Google Play store compliance requirements for account deletion are completely fulfilled.

---

## 3. Glossary

* **Racquet:** Parent tennis frame owned by the user (e.g., Wilson Blade 98 v8), represented as a document at `/users/{uid}/racquets/{racquetId}`.
* **StringJob:** A specific string installation characterized by brand, model, material category, stringing date, tension in lbs, and hours played.
* **currentStringJob:** The active string job embedded directly inside the `Racquet` document.
* **pastStringJobs:** An array of archived historical string jobs embedded on the `Racquet` document, recording total court hours, days elapsed, and retirement reasons (`dead`, `broken`, `manual_restring`).
* **StringMaterialCategory:** Enum representing string construction type, exactly four values: `monofilament` (co-polyester and other polyester monos), `multifilament`, `syntheticGut`, `naturalGut`. Drives decay rates and calendar shelf-life.
* **HealthScore:** Normalized integer percentage (0–100%) computed client-side upon read using the pure Dart `DecayEngine`.
* **SessionLog:** Dedicated document at `/users/{uid}/sessions/{sessionId}` capturing playing duration, played timestamp, racquet ID, and optional court notes/surface.
* **WriteBatch:** An atomic Firestore write operation combining the creation of a `SessionLog` document with the numerical increment of `currentStringJob.hoursPlayed` on the corresponding `Racquet`.
* **App Check:** Firebase abuse prevention verifying app authenticity via Play Integrity on Android and reCAPTCHA Enterprise on Web.

---

## 4. Features & Functional Requirements

```mermaid
flowchart TD
    A[User Opens App] --> B{Authenticated?}
    B -->|No| C[Google Sign-In 1-Tap]
    C --> D[Firebase Auth Verified]
    B -->|Yes| E[Load /users/{uid}/racquets Stream]
    D --> E
    E --> F[Client-Side DecayEngine Evaluates Health Scores]
    F --> G[Render Virtual Bag & Animated Gauges]
    G --> H{User Action}
    H -->|Add Racquet| I[Create Racquet with Embedded currentStringJob]
    H -->|Quick Log Session| J[Atomic Firestore WriteBatch]
    J --> K[Create SessionLog Document]
    J --> L[Increment currentStringJob.hoursPlayed]
    K & L --> M[Firestore .snapshots() Emits Updated State]
    M --> F
    H -->|Restrung Today| N[Archive currentStringJob to pastStringJobs & Reset]
    N --> M
    H -->|Delete Account| O[FirebaseAuth delete + delete-user-data Extension]
```

### 4.1 Authentication & User Lifecycle
**Description:** Secure, verified cloud authentication using Google Sign-In only. Ensures continuous cloud persistence, real-time sync, and effortless store compliance. Realizes UJ-2, UJ-4.

* **FR-1: Google-Only Authentication**  
  The system must authenticate users exclusively via Google Sign-In (`firebase_auth` and `google_sign_in`) across Android and Web. Email/password authentication, anonymous guest mode, and local-only unauthenticated state are strictly omitted.  
  *Consequences (testable):* Unauthenticated users cannot access core routes; signing in provisions a verified Firebase Auth UID.
* **FR-2: Cloud Session Persistence & Auto-Rehydration**  
  The client must persist the Firebase Authentication state across app launches and network interruptions, automatically restoring the session and user identity on launch.
* **FR-3: Sign-Out & Account Switching**  
  The user can sign out from the Settings screen at any time. Signing out terminates the active session, clears local memory caches, and returns the user to the Google Sign-In screen.
* **FR-4: GDPR & Play Store Account Deletion**  
  The app must provide a prominent `[Delete Account & Data]` flow in Settings on both Android and Web:
  - Invokes `FirebaseAuth.instance.currentUser?.delete()`.
  - Prompts Google re-authentication if the session requires recent login.
  - Relies on the server-side Firebase `delete-user-data` extension to purge `/users/{uid}` and all nested subcollections (`racquets`, `sessions`) upon user deletion.

---

### 4.2 Virtual Bag & Multi-Racquet Management
**Description:** The core equipment inventory dashboard. Backed by user-scoped Firestore subcollections with real-time stream sync. Realizes UJ-1, UJ-2, UJ-3.

* **FR-5: Add Racquet with Embedded String Setup**  
  The user can add a racquet by specifying:
  - Frame Name / Model (Required, string, e.g., "Wilson Blade 98").
  - String Material Category (Required, Enum: `monofilament`, `multifilament`, `syntheticGut`, `naturalGut`).
  - String Brand & Model (Optional, string, e.g., "Luxilon ALU Power 1.25").
  - Stringing Date (Required, DateTime; defaults to today).
  - Installed Tension (Optional, double; in lbs).
  - Manufacturer Max Hours (Optional, double; pre-filled with category defaults: Monofilament = 20h, Multifilament = 35h, Synthetic Gut = 30h, Natural Gut = 50h).  
  *Consequences (testable):* Creates `/users/{uid}/racquets/{racquetId}` with embedded `currentStringJob`; appears immediately in the UI.
* **FR-6: Multi-Racquet Inventory Display**  
  The Virtual Bag screen must display a scrollable list/grid of all registered racquets streamed live via `.snapshots()`, showing frame name, string specs, hours played, calendar days elapsed, and an animated radial Health Gauge.
* **FR-7: Racquet Editing & Deletion**  
  The user can edit frame nicknames/notes or delete a racquet document. Deleting a racquet removes the document and its embedded string history.
* **FR-8: Primary Racquet Designation**  
  The user can designate one racquet as "Primary in Bag", causing it to be pre-selected by default in the session quick-logger.

---

### 4.3 Pure Client-Side Composite Decay Engine
**Description:** Evaluates active court wear and passive calendar tension relaxation client-side upon read with zero server cron dependencies. Realizes UJ-1, UJ-3.

* **FR-9: Composite Decay Calculation & Secondary Companion Metrics**  
  The system must calculate `HealthScore` on the client using the composite formula:
  $$\text{HealthScore} = \max\left(0, \operatorname{round}\left(100 - \left(\text{DynamicPenalty} + \text{CalendarPenalty}\right)\right)\right)$$
  Where:
  * $\text{DynamicPenalty} = \left(\frac{\text{HoursPlayed}}{\text{MaxRatedHours}}\right) \times 70$
  * $\text{CalendarPenalty} = \left(\frac{\text{DaysElapsed}}{\text{MaxCalendarShelfLife}}\right) \times 30$
  * `MaxCalendarShelfLife`: `monofilament` = 75 days, `multifilament` = 180 days, `syntheticGut` = 180 days, `naturalGut` = 365 days.
  * **Secondary Metric Derivations**:
    - **Estimated Tension Loss**: $\text{TensionLossLbs} = \text{InstalledTensionLbs} \times \left(\frac{100 - \text{HealthScore}}{100}\right) \times 0.25$ (modeling tension relaxation capped at ~25% total loss).
    - **Remaining Court Hours to Dead Zone**: $\text{RemainingHours} = \max\left(0, \operatorname{round}\left(\frac{\text{HealthScore} - 40}{70} \times \text{MaxRatedHours}\right)\right)$ (displaying remaining play hours before crossing into Red $< 40\%$).
  [ASSUMPTION: §4.3 / FR-9] (Client-side decay calculation on read is sufficiently fast and avoids the complexity/cost of scheduled Cloud Functions or server cron jobs).
* **FR-10: Health Status Tiers & Color Coding**  
  The UI must categorize Health Scores into three distinct states:
  * **Green (Optimal):** $\ge 70\%$. Normal playability and elasticity.
  * **Amber (Degraded):** $40\% \le \text{Score} < 70\%$. Noticeable tension drop; control reducing.
  * **Red (Dead / High Risk):** $< 40\%$. High shock transfer; restringing recommended to protect arm.
* **FR-11: Dynamic Client-Side Evaluation (No Server Cron or Write-Backs)**  
  Health scores must be evaluated dynamically in pure Dart upon reading `currentStringJob.hoursPlayed` and `DateTime.now().difference(currentStringJob.strungAt)`. No scheduled Cloud Functions, server cron jobs, or lazy database write-backs are performed, completely eliminating unnecessary Firestore write costs.

---

### 4.4 Session Logging & Atomic Batching
**Description:** High-speed manual playing session capture executing atomic batch commits across sessions and racquets. Realizes UJ-1.

* **FR-12: Sub-10-Second Manual Quick Logger**  
  Tapping `[+ Log Session]` opens a bottom sheet allowing the user to select duration chips (`30m`, `1h`, `1.5h`, `2h`), select a racquet, and save in under 10 seconds (typically $\le 3$ taps). While the underlying Firestore schema permits optional metadata (`notes`, `surface`, `location`), the v1.0 quick-logger UI strictly omits these fields to satisfy the sub-10s logging threshold and SM-C1.  
  [ASSUMPTION: §4.4 / FR-12] (Eliminating smartwatch auto-detection in v1 is an acceptable trade-off to bypass Google Play Health Connect policy bottlenecks for immediate public launch).
* **FR-13: Atomic WriteBatch Session Logging**  
  Logging a session must execute as a single Firestore `WriteBatch`:
  1. Creates `/users/{uid}/sessions/{sessionId}` with `racquetId`, `stringJobId` (the `id` of the racquet's `currentStringJob` at logging time), `durationHours`, `playedAt`, and `createdAt`.
  2. Updates `/users/{uid}/racquets/{racquetId}` with `currentStringJob.hoursPlayed = FieldValue.increment(durationHours)` and `updatedAt = FieldValue.serverTimestamp()`.  
  *Consequences (testable):* Either both writes succeed or neither does; works seamlessly offline via Firestore local persistence.
* **FR-14: Real-Time Multi-Device Sync**  
  Firestore document and collection streams (`.snapshots()`) must push updates automatically to all active screens and across multi-window/multi-device sessions without manual pull-to-refresh.

---

### 4.5 Restringing Lifecycle & Historical Archive
**Description:** Restringing racquets, resetting the health gauge, and archiving lifecycle stats. Realizes UJ-3.

* **FR-15: 1-Tap "Restrung Today" Action**  
  Each racquet card and detail view must provide a `[Restrung Today]` action opening a quick confirmation sheet:
  * `[Keep Same & Reset]`: Retains identical string specs, resets hours to 0, and sets stringing date to today.
  * `[Change Strings]`: Allows updating brand, model, material, tension, or date before resetting.
* **FR-16: Historical String Job Archiving**  
  Executing restringing moves the active `currentStringJob` into the `pastStringJobs` array on the `Racquet` document, populating `endedAt` with the client timestamp (`Timestamp.now()`; Firestore does not allow server timestamps inside arrays) and the specific user-selected `endReason` (`"dead"`, `"broken"`, or `"manual_restring"`), and initializes the fresh active `currentStringJob` with 0 hours played. This structured history ensures clean dataset capture for future String Lab longevity analytics.
* **FR-17: Restring History Timeline UI**  
  The Racquet Detail view must display a chronological timeline of past string jobs with court hours played and calendar duration (e.g., *"Aug 1 – Oct 2 • Luxilon ALU Power • 19.2 court hours • 62 days"*).

---

### 4.6 Store Compliance, Security & Platform Infrastructure
**Description:** Hardening the public deployment against unauthorized billing, abuse, and store rejections. Realizes UJ-4.

* **FR-18: Firestore Security Rules Enforcement**  
  All Firestore documents must be guarded by path-based ownership (`/users/{uid}/**` accessible only when `request.auth.uid == uid`) and payload schema validation enforcing attribute types, key limits ($\le 15$ keys per racquet, $\le 12$ keys per session), string length bounds, and positive numeric ranges.
* **FR-19: Firebase App Check Protection**  
  Firebase App Check must be activated on startup using **Play Integrity** on Android and **reCAPTCHA Enterprise** on Web to protect Firestore from unauthorized scripts, scrapers, and billing abuse.  
  [ASSUMPTION: §4.6 / FR-19] (Firebase App Check provides sufficient protection against bot abuse and billing inflation).
* **FR-20: Firebase Hosting & Static Legal Pages**  
  The Flutter Web app must be hosted on Firebase Hosting with SPA rewrites to `/index.html` while serving static `/privacy.html` (Privacy Policy & Account Deletion instructions) directly for Google Play Store compliance.
* **FR-21: Day-1 Telemetry & Crash Reporting**  
  The app must integrate Firebase Crashlytics on Android (catching uncaught Flutter and platform errors; Crashlytics has no Flutter Web support), Firebase Performance Monitoring, and Firebase Analytics (logging `sign_in`, `racquet_created`, `session_logged`, and `racquet_restrung`).
* **FR-22: Remote Config Feature Flags & Monetization Sensors**  
  The app must initialize Firebase Remote Config with default flags (`show_ads: false`, `pro_paywall_trigger: false`, `free_racquet_limit: 99`) and activate fetched parameters on launch to enable zero-code remote adjustments post-launch.

---

## 5. Non-Goals (Explicit for v1.0)

* **[Non-Goal] Serverpod & Custom Server Infrastructure:** No custom backend server, PostgreSQL database, or custom WebSockets.
* **[Non-Goal] Apple Health & Health Connect:** No smartwatch or OS health workout auto-detection in v1.0 to eliminate sensitive permission review friction on Google Play.
* **[Non-Goal] Hackathon Demo Actions:** "Create Sample Bag" and "Simulate Workout" demo-only actions are purged from the UI and state management layer.
* **[Non-Goal] Local Notifications in v1:** Local scheduled decay notifications are stripped in favor of clean client-side in-app badges (deferred until FCM push in v1.2+).
* **[Non-Goal] Patrol E2E in CI:** Patrol E2E automated test runs in CI are paused for v1.0 to accelerate build cycles, while retaining unit and widget test coverage.
* **[Non-Goal] Unauthenticated Guest Mode:** No local-only guest accounts or complex local-to-cloud migration logic.
* **[Non-Goal] Ads & In-App Purchases:** No AdMob banners or Google Play Billing paywalls in the v1.0 store submission (deferred to v1.1).
* **[Non-Goal] Server-Side Decay Cron / Cloud Functions:** No scheduled Cloud Functions or server cron jobs for decay math in v1.0.
* **[Non-Goal] Acoustic String-Tension Plucking:** Microphone-based frequency vibration analysis (FFT) is out of scope.
* **[Non-Goal] Social Feeds & Match Point Tracking:** No point-by-point scoring, match results, or social feeds.

---

## 6. MVP Scope Boundary (MoSCoW)

| MoSCoW | Scope Items | Rationale |
|---|---|---|
| **Must Have (v1.0)** | • Google-Only Firebase Auth (`FR-1`, `FR-2`, `FR-3`)<br>• Account Deletion & GDPR Flow (`FR-4`)<br>• Denormalized `Racquet` + `currentStringJob` (`FR-5`, `FR-6`)<br>• Racquet Editing, Deletion & Primary Designation (`FR-7`, `FR-8`)<br>• Client-Side `DecayEngine` & Health Tiers (`FR-9`, `FR-10`, `FR-11`)<br>• Sub-10s Quick Logger + Atomic `WriteBatch` (`FR-12`, `FR-13`)<br>• Real-Time Multi-Device Stream Sync (`FR-14`)<br>• "Restrung Today" 1-tap reset + `pastStringJobs` archive (`FR-15`, `FR-16`, `FR-17`)<br>• Production `firestore.rules` + Firebase App Check (`FR-18`, `FR-19`)<br>• Firebase Hosting & Static `/privacy.html` (`FR-20`)<br>• Telemetry & Remote Config Flags (`FR-21`, `FR-22`) | Minimum viable scope required to deliver the core string tracking promise and pass Google Play Store review without friction. |
| **Should Have (v1.1)** | • AdMob integration & Paid Pro tier (in-app subscription)<br>• Paywall triggers activated via Remote Config<br>• Enriched `SessionLog` metadata (court surface, location, notes) | Monetization and secondary session details immediately following store approval. |
| **Could Have (v1.2+)** | • **String Lab Pro Insights**: Longevity analytics across brands/materials from archived string jobs<br>• Firebase Cloud Messaging (FCM) background push notifications<br>• Web landing "String Health Calculator" widget for conversion | Differentiating Pro value and engagement drivers. |
| **Won't Have (v1.0)** | • Serverpod backend, PostgreSQL, or custom server cron<br>• Health Connect / Apple Health permissions<br>• Unauthenticated guest mode<br>• Ads or IAP in initial store submission | Explicitly pruned to minimize operational overhead and store review hurdles. |

---

## 7. Success Metrics & Counter-Metrics

### Primary Metrics
* **SM-1 (Sub-10s Logging Speed):** $> 90\%$ of manual session logs completed in $\le 10$ seconds. *Validates FR-12.*
* **SM-2 (Day-1 Crash-Free Rate):** $> 99.5\%$ crash-free sessions on Android reported via Firebase Crashlytics (Crashlytics does not support Flutter Web; web errors are not covered by this metric). *Validates FR-21.*
* **SM-3 (App Check Verification):** $> 98\%$ of incoming Firestore operations verified with valid App Check tokens. *Validates FR-19.*
* **SM-4 (Multi-Racquet Adoption):** Average of $\ge 1.8$ racquets registered per active user bag. *Validates FR-5, FR-6.*
* **SM-5 (Restring Lifecycle Completion):** $\ge 75\%$ of racquets reaching $<40\%$ health execute a "Restrung Today" action. *Validates FR-15, FR-16.*

### Counter-Metrics (Do Not Optimize)
* **SM-C1 (Field Clutter):** Manual quick-logger modal must require $\le 3$ taps for 90% of sessions. Do not add mandatory metadata fields.
* **SM-C2 (Firestore Read Amplification):** Loading the Virtual Bag must cost exactly 1 collection query (`/users/{uid}/racquets`) with zero joined document reads. *Validates denormalized data design.*

---

## 8. Cross-Cutting Non-Functional Requirements (NFRs)

### 8.1 Performance & Responsiveness
* **NFR-1 (UI Responsiveness):** Radial gauge animations must render smoothly at 60 fps without dropped frames.
* **NFR-2 (Real-Time Sync Latency):** Firestore `.snapshots()` updates must reflect across active UI surfaces within $< 500\text{ ms}$ of network commit.
* **NFR-3 (Cold Start to Interactive Bag):** App cold start to interactive Virtual Bag screen must be $< 1.5\text{ seconds}$ leveraging Firestore local disk persistence.

### 8.2 Reliability & Offline Resilience
* **NFR-4 (Offline Logging Resilience):** Players logging sessions on courts without cellular coverage must have writes cached locally by Firestore and committed automatically upon reconnection.
* **NFR-5 (Atomic Gear & Session Mutations):** Session logs and racquet hours played must always be written via atomic `WriteBatch` to guarantee consistency.

### 8.3 Security, Privacy & Store Governance
* **NFR-6 (Zero Sensitive Health Permissions):** `AndroidManifest.xml` must declare zero health, body sensor, or background fitness permissions, guaranteeing zero Health Connect review friction.
* **NFR-7 (Public Security Rules Bounds):** `firestore.rules` must reject any write exceeding schema key counts ($\le 15$ for racquets, $\le 12$ for sessions) or payload string lengths to prevent billing/storage abuse.
* **NFR-8 (Google Play Data Safety Compliance):** All data collection declared in Google Play Console must align exactly with Firebase Auth and Firestore usage, backed by static `/privacy.html` and the account deletion mechanism:
  - Personal Info: Name & Email collected via Google Sign-In for account identification.
  - App Activity & Fitness Equipment: Racquets, StringJobs, and SessionLogs stored under `/users/{uid}`.
  - App Info & Performance: Firebase Crashlytics crash traces and Performance diagnostics.
  - Security Practices: Data encrypted in transit; verified account and data deletion mechanism provided.

---

## 9. Open Questions & Resolutions

1. **[RESOLVED] OQ-1 (Tension Loss Modeling):** Display Health Score (0–100%) as the primary hero metric, accompanied by secondary estimated tension loss text (e.g. *"~1.4 lbs tension drop"*) for player clarity.
2. **[RESOLVED] OQ-2 (Hybrid Stringing Setups):** For v1, hybrid setups are categorized by the dominant stringbed material (e.g., Monofilament). Dual main/cross separate spec inputs are deferred to v1.1.
3. **[RESOLVED] OQ-3 (Account Deletion Mechanism):** Satisfy Google Play store mandatory web account deletion by pointing the Play Console Data Safety URL to the hosted Flutter Web app, which executes the identical Firebase Auth deletion and `delete-user-data` purge.
4. **[RESOLVED] OQ-4 (Offline Multi-Device Batch Resolution):** Multi-device and offline session logging adheres to Firestore's standard last-write-wins commit ordering. Increments to `hoursPlayed` utilize `FieldValue.increment()`, guaranteeing that session court hours accumulate atomically on the server regardless of offline write queuing order.

---

## 10. Assumptions Index

* **[ASSUMPTION: §2.1]** Requiring Google Sign-In at first launch will not significantly depress conversion compared to guest mode, while permanently eliminating guest-to-cloud data migration issues.
* **[ASSUMPTION: §4.3 / FR-9]** Client-side decay calculation on read is sufficiently fast and avoids the complexity/cost of scheduled Cloud Functions or server cron jobs.
* **[ASSUMPTION: §4.4 / FR-12]** Eliminating smartwatch auto-detection in v1 is an acceptable trade-off to bypass Google Play Health Connect policy bottlenecks for immediate public launch.
* **[ASSUMPTION: §4.6 / FR-19]** Firebase App Check (Play Integrity on Android + reCAPTCHA Enterprise on Web) provides sufficient protection against bot abuse and billing inflation.
