# String Theory — v1 Firebase Migration & Store Launch Checklist

Practical, step-by-step technical execution checklist derived from the post-hackathon brainstorming session (`2026-10-23`). Designed to execute the Serverpod-to-Firebase migration and ship v1 to **Firebase Hosting (Web)** and the **Google Play Store (Android)** with minimal Play Console review friction.

---

## 1. Codebase Cuts & Cleanup

Strip out hackathon-specific scaffolding, Serverpod infrastructure, and high-friction platform permissions before wiring Firebase.

- [ ] **Remove Serverpod Backend & Client Packages**
  - [ ] Delete the `string_theory_server` and `string_theory_client` packages/directories from the repository.
  - [ ] Remove `serverpod_flutter`, `serverpod_auth_shared_flutter`, and `string_theory_client` dependencies from `string_theory_flutter/pubspec.yaml`.
  - [ ] Delete Serverpod `docker-compose.yaml`, migrations, and `FutureCall` daily cron scheduling logic.
  - [ ] Strip custom Serverpod WebSocket stream listeners from Flutter BLoCs/repositories (to be replaced by Firestore `.snapshots()`).
- [ ] **Remove Apple Health & Health Connect Integrations**
  - [ ] Remove health plugin dependencies from `pubspec.yaml`.
  - [ ] Remove Android Health Connect permissions and activity aliases from `android/app/src/main/AndroidManifest.xml` (eliminates Google Play Health Connect declaration bottlenecks for v1 launch).
  - [ ] Remove iOS HealthKit entitlements and `Info.plist` usage descriptions.
  - [ ] Delete workout ingestion UI, permissions prompts, and background health polling services.
- [ ] **Remove Guest Mode & Email/Password Auth**
  - [ ] Delete email/password sign-in, registration, and verification screens/flows.
  - [ ] Delete unauthenticated "Guest Mode", local-only racquet/session storage, and local-to-cloud sync/migration logic.
  - [ ] Require authenticated cloud state for all core app routes; rely on Firestore's built-in offline persistence for offline support.
- [ ] **Remove Hackathon Demo Actions & Local Notifications**
  - [ ] Delete fake demo actions (`Create Sample Bag` and `Simulate Workout`) from the UI and state layer.
  - [ ] Remove `RestringEvent` as a separate model/entity across the codebase.
  - [ ] Skip/remove local decay notification scheduling in v1 (deferred until real FCM push notifications in v1.2+).
- [ ] **Update CI/CD Pipeline (Pause Patrol E2E)**
  - [ ] Disable/comment out Patrol E2E test jobs in GitHub Actions workflows to accelerate build and deployment times for the initial v1 launch.
  - [ ] Retain fast `dart analyze`, `dart format`, and unit/widget test steps on `main`.

---

## 2. Firebase Project & FlutterFire Setup

Provision the serverless backend, telemetry, and abuse protection from Day 1.

- [ ] **Initialize Firebase & FlutterFire**
  - [ ] Create the Firebase project and register **Android** and **Web** apps.
  - [ ] Run `flutterfire configure` to generate `lib/firebase_options.dart`.
  - [ ] Initialize `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` in `main.dart`.
- [ ] **Firebase Authentication (Google Sign-In Only)**
  - [ ] Enable **Google** as the sole Sign-In provider in the Firebase Console (disable Email/Password and Anonymous auth).
  - [ ] Configure Android SHA-1 / SHA-256 signing certificates (debug, upload key, and Play App Signing key) in Project Settings.
  - [ ] Configure Web OAuth client ID and authorized domains.
  - [ ] Add `firebase_auth` and `google_sign_in` packages and wire 1-tap Google Sign-In on mobile and web.
- [ ] **Cloud Firestore**
  - [ ] Provision the Cloud Firestore database in production mode.
  - [ ] Add `cloud_firestore` and verify built-in offline persistence is enabled for mobile and web.
- [ ] **Telemetry (Crashlytics, Performance, Analytics)**
  - [ ] Add `firebase_crashlytics`, `firebase_performance`, and `firebase_analytics`.
  - [ ] Wire `FlutterError.onError` and `PlatformDispatcher.instance.onError` to `FirebaseCrashlytics.instance` in `main.dart`.
  - [ ] Log baseline conversion and engagement events (`sign_in`, `racquet_created`, `session_logged`, `racquet_restrung`).
- [ ] **Firebase Remote Config (v1 Feature Flags & Sensors)**
  - [ ] Add `firebase_remote_config` and configure sensible in-app defaults (`show_ads: false`, `pro_paywall_trigger: false`, `free_racquet_limit: 99`).
  - [ ] Fetch and activate Remote Config on startup so monetization thresholds can be toggled in v1.1 without waiting for Play Store review.
- [ ] **Firebase App Check (Day-1 Billing & Abuse Protection)**
  - [ ] Add `firebase_app_check` and activate immediately after `Firebase.initializeApp()`.
  - [ ] Configure **Play Integrity** provider for Android and **reCAPTCHA Enterprise** provider for Web.
  - [ ] Enforce App Check on Cloud Firestore in the Firebase Console once verified.
- [ ] **Firebase Hosting**
  - [ ] Initialize Firebase Hosting (`firebase init hosting`) targeting `build/web`.
  - [ ] Configure SPA URL rewrites to `/index.html` while allowing static files like `/privacy.html` to be served directly.

---

## 3. Domain Model Refactor

Migrate from relational SQL tables to user-scoped Firestore subcollections (`/users/{uid}/...`) with denormalized reads and atomic batch writes.

- [ ] **Unified `Racquet` + `StringJob` Model (`/users/{uid}/racquets/{racquetId}`)**
  - [ ] Eliminate the separate `RestringEvent` entity; unify string lifecycle tracking into `StringJob`.
  - [ ] Embed the active `currentStringJob` directly inside the `Racquet` document so loading the user's gear bag requires a single collection query with zero joins:
    - `currentStringJob`: `{ brand, model, gauge, tensionLbs, strungAt, hoursPlayed, endedAt: null, endReason: null }`
  - [ ] Store historical string jobs in a `pastStringJobs` array (or subcollection) on the `Racquet` with `endedAt` timestamp and `endReason` (e.g., `dead`, `broken`, `manual_restring`).
  - [ ] Stream the gear bag directly into the UI via `.collection('users').doc(uid).collection('racquets').snapshots()`.
- [ ] **Dedicated `SessionLog` Collection & Atomic `WriteBatch` (`/users/{uid}/sessions/{sessionId}`)**
  - [ ] Keep `SessionLog` as a dedicated subcollection (`/users/{uid}/sessions`) so users can browse their playing session history and attach metadata.
  - [ ] Implement `logSession()` using a Firestore `WriteBatch` so two operations execute atomically in a single network call (and work offline):
    1. `batch.set(sessionRef, sessionData)` — creates the new `SessionLog` document.
    2. `batch.update(racquetRef, {'currentStringJob.hoursPlayed': FieldValue.increment(durationHours), 'updatedAt': FieldValue.serverTimestamp()})` — increments court hours on the racquet's active `StringJob`.
  - [ ] Implement `restringRacquet()` to move `currentStringJob` (with `endedAt` and `endReason` populated) into `pastStringJobs` and set the fresh `currentStringJob` with `hoursPlayed: 0`.
- [ ] **Client-Side `DecayEngine` (Zero Cloud Functions in v1)**
  - [ ] Keep the pure Dart `DecayEngine` (70% court hours + 30% calendar shelf-life) on the client.
  - [ ] Compute dynamic Health Scores (`0–100%`, Green `>=70%`, Amber `40–69%`, Red `<40%`) purely on client read from `currentStringJob.hoursPlayed` and `DateTime.now().difference(currentStringJob.strungAt)`.
  - [ ] Lazily write back updated health metadata to Firestore on session open or session log if needed—no server cron required.

---

## 4. Production `firestore.rules` Starter Snippet

Enforce strict user ownership under `/users/{userId}/**` along with schema and payload size validation to prevent malformed writes or billing abuse.

- [ ] Create and deploy `firestore.rules` (`firebase deploy --only firestore:rules`):

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    function isValidString(val, minLen, maxLen) {
      return val is string && val.size() >= minLen && val.size() <= maxLen;
    }

    function isValidStringJob(job) {
      return job is map
        && job.keys().hasAll(['brand', 'tensionLbs', 'strungAt', 'hoursPlayed'])
        && job.keys().size() <= 10
        && isValidString(job.brand, 1, 80)
        && (job.tensionLbs is int || job.tensionLbs is float)
        && job.tensionLbs >= 20 && job.tensionLbs <= 80
        && job.strungAt is timestamp
        && (job.hoursPlayed is int || job.hoursPlayed is float)
        && job.hoursPlayed >= 0 && job.hoursPlayed <= 1000;
    }

    function isValidRacquet(data) {
      return data.keys().hasAll(['name', 'currentStringJob', 'updatedAt'])
        && data.keys().size() <= 15
        && isValidString(data.name, 1, 100)
        && isValidStringJob(data.currentStringJob)
        && (!('pastStringJobs' in data) || (data.pastStringJobs is list && data.pastStringJobs.size() <= 100))
        && data.updatedAt is timestamp;
    }

    function isValidSessionLog(data) {
      return data.keys().hasAll(['racquetId', 'durationHours', 'playedAt', 'createdAt'])
        && data.keys().size() <= 12
        && isValidString(data.racquetId, 1, 64)
        && (data.durationHours is int || data.durationHours is float)
        && data.durationHours > 0 && data.durationHours <= 24
        && data.playedAt is timestamp
        && data.createdAt is timestamp
        && (!('notes' in data) || isValidString(data.notes, 0, 500))
        && (!('location' in data) || isValidString(data.location, 0, 120))
        && (!('surface' in data) || isValidString(data.surface, 0, 40));
    }

    match /users/{userId} {
      allow read, delete: if isOwner(userId);
      allow create, update: if isOwner(userId) && request.resource.data.keys().size() <= 10;

      match /racquets/{racquetId} {
        allow read, delete: if isOwner(userId);
        allow create, update: if isOwner(userId) && isValidRacquet(request.resource.data);
      }

      match /sessions/{sessionId} {
        allow read, delete: if isOwner(userId);
        allow create, update: if isOwner(userId) && isValidSessionLog(request.resource.data);
      }
    }

    // Default deny all other paths
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 5. GDPR & Google Play Store Compliance Setup

Satisfy Google Play's mandatory Data Safety, Privacy Policy, and in-app + web Account Deletion requirements using out-of-the-box Firebase features.

- [ ] **Install Firebase `delete-user-data` Extension**
  - [ ] Install the official **Delete User Data** (`firebase/delete-user-data`) extension in the Firebase Console.
  - [ ] Configure the extension to recursively delete `/users/{UID}` (including `/users/{UID}/racquets` and `/users/{UID}/sessions`) whenever a user is deleted from Firebase Authentication.
- [ ] **In-App & Web "Delete Account" Button**
  - [ ] Add a `Delete Account & Data` action with a confirmation dialog in the Flutter app Settings/Profile screen (works identically on Android and the Firebase-hosted Web app).
  - [ ] Call `await FirebaseAuth.instance.currentUser?.delete()` (handling `requires-recent-login` by prompting Google re-authentication if needed).
- [ ] **Host Static `/privacy.html` on Firebase Hosting**
  - [ ] Add `web/privacy.html` (Privacy Policy & Terms of Service, including clear instructions on deleting an account in-app or via the Web app).
  - [ ] Deploy to Firebase Hosting (`firebase deploy --only hosting`) and verify `https://<project-id>.web.app/privacy.html` resolves publicly.
- [ ] **Google Play Console Declarations**
  - [ ] Set the **Privacy Policy URL** to `https://<project-id>.web.app/privacy.html`.
  - [ ] Set the **Account Deletion URL** in the Data Safety section to the hosted Web app URL (or `/privacy.html#delete-account`), allowing users to sign in with Google on the web and delete their account with 1 click without reinstalling the Android app.
  - [ ] Complete the **Data Safety Form** declaring:
    - Personal info (Name/Email via Google Sign-In for account management).
    - App activity & fitness/equipment logs (`Racquet`, `StringJob`, `SessionLog` stored in Firestore).
    - App info and performance (Crashlytics & Performance diagnostics).
    - Encryption in transit (`true`) and user data deletion mechanism (`true`).

---

## 6. v1.1+ Iteration Prep (Post-Launch Hooks)

Keep v1 lean to pass Play Store review immediately, while laying clean hooks for fast v1.1 and v1.2 upgrades.

- [ ] **Monetization Hooks (v1.1 — Ads & Pro Upgrade)**
  - [ ] Gate ad banner slots and racquet count limits behind the Remote Config flags shipped in v1 (`show_ads`, `pro_paywall_trigger`, `free_racquet_limit`).
  - [ ] Prepare Analytics custom definitions to measure conversion triggers (e.g., hitting the free racquet limit or viewing string history) before enabling ads/paywalls.
- [ ] **Richer Session Metadata & String Lab Pro Insights (v1.1 / v1.2)**
  - [ ] Keep optional `surface`, `location`, and `notes` fields supported in `SessionLog` serialization and `firestore.rules` so UI fields can be enabled in v1.1 without a schema migration.
  - [ ] Ensure `restringRacquet()` consistently records `hoursPlayed`, `strungAt`, `endedAt`, and `endReason` on `pastStringJobs` so v1 doesn't lose historical data needed for v1.2 **String Lab Pro** longevity analytics (average hours before dead/broken per string brand).
- [ ] **FCM Push Notifications Hook (v1.2+)**
  - [ ] Reserve an optional `fcmTokens` field on `/users/{uid}` so when Cloud Messaging (`firebase_messaging`) is added in v1.2, background string-decay alerts can be delivered without changing the core racquet/session schema.
  - [ ] **Web Funnel Idea (v1.2+)**: Add an unauthenticated interactive "String Health Calculator" landing widget on Web with a `"Save my racquet with Google"` CTA to convert web visitors into authenticated users.
