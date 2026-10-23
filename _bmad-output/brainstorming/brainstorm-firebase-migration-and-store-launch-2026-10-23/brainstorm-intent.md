# String Theory: Firebase Migration & Public Store Launch — Intent

## 1. Problem & Strategic Pivot
- **Context**: Transitioning String Theory from a Serverpod Hackathon prototype (PostgreSQL ORM, custom WebSockets, `FutureCall` cron, demo actions) to a public production release on **Google Play Store** and **Firebase Hosting (Flutter Web)**.
- **Goal**: Ship v1 rapidly with near-zero backend operational overhead, minimal Play Store review friction, strict public security/billing protection, and built-in telemetry + data structures ready for v1.1 monetization.
- **Core Strategic Insights**:
  1. **Unified Web + Mobile Compliance**: Requiring Google Sign-In (no guest mode) and deploying the Flutter Web app on Firebase Hosting satisfies Google Play's mandatory web-accessible account deletion URL for free using the same codebase.
  2. **Zero-Friction Store Review**: Stripping Health Connect / Apple Health permissions and deferring Ads/IAP to v1.1 eliminates the two primary Google Play review bottlenecks (sensitive health permissions and billing declarations) for an immediate v1 launch.
  3. **Analytics-Ready Denormalization**: Merging `StringJob` and `RestringEvent` onto the `Racquet` while keeping `SessionLog` separate minimizes Firestore read costs in v1 and natively builds the dataset for v1.1+ Pro "String Lab" longevity insights.

---

## 2. Core Architectural Decisions
- **Authentication**: **Google Sign-In only** via Firebase Auth (`firebase_auth`, `google_sign_in`). Remove email/password auth.
- **No Guest or Local-Only Mode**: Require authenticated cloud state from the start. Rely on Firestore's built-in offline persistence rather than custom local-to-cloud sync or migration logic.
- **Pure Client-Side `DecayEngine` (No Cloud Functions / Cron in v1)**: Drop Serverpod's daily scheduled `FutureCall`. Compute string decay purely on the client upon read using the pure Dart `DecayEngine`, lazily writing updated scores back to Firestore on session open.
- **Real-Time Multi-Device Sync**: Replace custom Serverpod WebSocket streams with Firestore real-time document/collection streams (`.snapshots()`).
- **Hackathon & Scope Pruning**:
  - Remove Apple Health and Health Connect integrations completely.
  - Remove hackathon demo-only fake actions ("Create Sample Bag", "Simulate Workout").
  - Skip local decay notifications in v1 (defer until Firebase Cloud Messaging push notifications in v1.2+).
  - Temporarily disable Patrol E2E tests in CI/CD to accelerate initial launch builds and deployment.

---

## 3. Firestore Data Model
All user data lives under user-scoped subcollections: `/users/{uid}/...`

### `Racquet` Document (`/users/{uid}/racquets/{racquetId}`)
- **Denormalized Active `StringJob`**: Embed the current active `StringJob` directly inside the `Racquet` document so loading the gear bag requires a single collection read with zero joins.
- **Unified String Lifecycle (`stringHistory` replaces `RestringEvent`)**: Eliminate `RestringEvent` as a separate entity. "Restringing" archives the active `StringJob` into a `stringHistory` / `pastStringJobs` array (or subcollection) on the `Racquet` with an `endedAt` timestamp and reason (e.g., dead, broken, manual), and sets the new active `StringJob`.

### `SessionLog` Collection (`/users/{uid}/sessions/{sessionId}`)
- **Dedicated Entity Retained**: Keep `SessionLog` as its own collection so users can browse session history and attach richer metadata (court location, surface, notes) in future iterations.
- **Atomic Updates via `WriteBatch`**: Logging a playing session uses a Firestore `WriteBatch` to atomically create the `SessionLog` document and increment `hoursPlayed` on the parent `Racquet`'s active `StringJob` in a single network commit.

---

## 4. Security, Privacy & Store Compliance
- **Firestore Security Rules**: Enforce strict path-based ownership (`/users/{uid}/**` accessible only when `request.auth != null && request.auth.uid == uid`) combined with schema and payload size validation to prevent malformed or oversized writes.
- **Firebase App Check (Day 1)**: Enforce App Check using **Play Integrity** on Android and **reCAPTCHA Enterprise** on Web to block unauthorized scripts from abusing Firestore reads/writes and inflating billing.
- **GDPR & Google Play Account Deletion**:
  - Install the official Firebase Extension **`delete-user-data`** configured to purge `/users/{uid}` upon Auth user deletion.
  - Wire an in-app "Delete Account" action calling `FirebaseAuth.instance.currentUser.delete()` on both Android and Web.
  - Point Google Play Console's mandatory Web Account Deletion URL to the hosted Flutter Web app.
- **Static Legal Pages**: Host `/privacy.html` (Privacy Policy & Terms of Service) directly as a static asset in the Flutter Web `web/` directory deployed on Firebase Hosting.

---

## 5. Telemetry & Phased Monetization Strategy
- **Day-1 Telemetry (v1.0)**: Ship with **Firebase Crashlytics**, **Firebase Performance Monitoring**, and **Firebase Analytics** active from launch to establish stability and usage baselines before introducing paywalls.
- **Remote Config Sensors**: Include **Firebase Remote Config** flags (`show_ads`, `pro_paywall_trigger`, `free_racquet_limit`) alongside Analytics events so monetization thresholds can be tested and toggled remotely without awaiting Play Store review.
- **Phased Monetization (v1.1+)**:
  - **Free Tier with Ads**: Ad-supported experience with configurable racquet/bag limits.
  - **Paid Pro Upgrade**: Ad removal, unlimited racquets, and **String Lab Pro Insights** (personal string longevity analytics computing average hours before strings go dead or break per string brand/model from unified `StringJob` history).

---

## 6. MoSCoW Scope

### Must Have (v1.0 Public Launch)
- **M1**: Google-only Firebase Auth (strip email/password and guest/local mode).
- **M2**: Firestore `Racquet` model with embedded active `StringJob` and unified `stringHistory` (replacing `RestringEvent`).
- **M3**: Dedicated `SessionLog` Firestore collection updated atomically alongside `Racquet.activeStringJob.hoursPlayed` via `WriteBatch`.
- **M4**: Client-side `DecayEngine` evaluation on read + Firestore `.snapshots()` real-time sync (no Cloud Functions/cron).
- **M5**: Day-1 telemetry: Firebase Crashlytics, Performance Monitoring, and Analytics.
- **M6**: Public security hardening: Firestore Security Rules (`/users/{uid}/**` + schema/size validation) and Firebase App Check (Play Integrity + reCAPTCHA Enterprise).
- **M7**: Store & GDPR compliance: Firebase `delete-user-data` extension, in-app + web account deletion flow, and static `/privacy.html` on Firebase Hosting.
- **M8**: Codebase & CI cleanup: strip Health Connect / Apple Health, remove hackathon demo actions ("Create Sample Bag", "Simulate Workout"), skip local notifications, and disable Patrol E2E in CI.

### Should Have (v1.1 Fast Follow)
- **S1**: Monetization activation: Ads integration + Paid Pro tier (in-app purchases / subscriptions).
- **S2**: Firebase Remote Config feature flags and monetization threshold triggers (`show_ads`, `pro_paywall_trigger`, `free_racquet_limit`).
- **S3**: Enriched `SessionLog` metadata (court surface, location, session notes).

### Could Have (v1.2+ Growth & Pro Value)
- **C1**: **String Lab Pro Insights**: Personal string longevity analytics derived from archived `StringJob` lifecycle logs.
- **C2**: Server-driven push notifications via Firebase Cloud Messaging (FCM) for string decay alerts.
- **C3**: Interactive "String Health Calculator" landing widget on Flutter Web before sign-in to drive top-of-funnel Google Auth conversion.

### Won't Have (v1.0 Out of Scope)
- **W1**: Serverpod backend, PostgreSQL, custom WebSockets, or scheduled server cron jobs.
- **W2**: Apple Health / Health Connect integrations.
- **W3**: Unauthenticated guest mode or custom local-to-cloud state migration.
- **W4**: Ads or In-App Purchases in the initial v1.0 store submission.
