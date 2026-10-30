---
stepsCompleted:
  - "step-01-validate-prerequisites"
  - "step-02-design-epics"
  - "step-03-create-stories"
  - "step-04-final-validation"
inputDocuments:
  - "_bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/prd.md"
  - "_bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/addendum.md"
  - "_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/ARCHITECTURE-SPINE.md"
  - "_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/reviews/review-adversary.md"
  - "_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/reviews/review-currency.md"
  - "_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-23/reviews/review-rubric.md"
  - "_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/DESIGN.md"
  - "_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/EXPERIENCE.md"
  - "_bmad-output/brainstorming/brainstorm-firebase-migration-and-store-launch-2026-10-23/migration-checklist.md"
  - "_bmad-output/implementation-artifacts/deferred-work.md"
---

# string_theory - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for String Theory v1.0 (Firebase, Android + Web), decomposing the requirements from the PRD, the UX Design contract (DESIGN.md + EXPERIENCE.md), and the Firebase v1 Architecture Spine into implementable stories. It replaces the Serverpod hackathon breakdown, which remains in git history.

## Requirements Inventory

### Functional Requirements

- **FR-1 (Google-only auth):** The system authenticates users exclusively via Google Sign-In (`firebase_auth` + `google_sign_in`) on Android and Web. Email/password, anonymous guest mode and local-only unauthenticated state do not exist. Unauthenticated users cannot reach core routes; signing in provisions a verified Firebase Auth UID.
- **FR-2 (Session persistence):** The client persists Firebase Auth state across launches and network interruptions and restores the session and user identity on launch.
- **FR-3 (Sign-out):** The user can sign out from Settings at any time. Sign-out ends the session, clears in-memory caches, and returns to the Google Sign-In screen.
- **FR-4 (Account deletion):** Settings on Android and Web provides `[Delete Account & All Data]`, which calls `FirebaseAuth.instance.currentUser?.delete()`, prompts Google re-authentication when recent login is required, and relies on the `delete-user-data` extension to purge `/users/{uid}` and all subcollections.
- **FR-5 (Add racquet):** The user can add a racquet with Frame Name (required, string), String Material (required, `monofilament` | `multifilament` | `syntheticGut` | `naturalGut`), String brand & model (optional, single string), Stringing Date (required, defaults to today), Installed Tension in lbs (optional), and Max court hours (pre-filled by material: Monofilament 20h, Multifilament 35h, Synthetic Gut 30h, Natural Gut 50h). Creates `/users/{uid}/racquets/{racquetId}` with an embedded `currentStringJob` that appears in the UI immediately.
- **FR-6 (Bag display):** The Virtual Bag displays a scrollable list/grid of all racquets streamed live via `.snapshots()`, showing frame name, string specs, hours played, calendar days elapsed and an animated radial Health Gauge.
- **FR-7 (Edit / delete racquet):** The user can edit the racquet name and notes, or delete a racquet. Deleting removes the document and its embedded string history; sessions logged against it are kept.
- **FR-8 (Primary racquet):** The user can designate one racquet as Primary, which pre-selects it in the quick logger.
- **FR-9 (Composite decay + companion metrics):** HealthScore = max(0, round(100 − (DynamicPenalty + CalendarPenalty))), where DynamicPenalty = hoursPlayed / maxHours × 70 and CalendarPenalty = daysElapsed / shelfLife × 30 (shelf life: monofilament 75 d, multifilament 180 d, syntheticGut 180 d, naturalGut 365 d). Companion metrics: TensionLossLbs = tension × (100 − score) / 100 × 0.25; RemainingHours = max(0, round((score − 40) / 70 × maxHours)).
- **FR-10 (Health tiers):** Scores map to three tiers: Optimal ≥ 70%, Degraded 40–69%, Dead < 40% (UI labels `Optimal`, `Caution`, `Restring`).
- **FR-11 (Client-side evaluation only):** Health is computed in pure Dart on read from `currentStringJob.hoursPlayed` and `now − strungAt`. No scheduled Cloud Functions, cron jobs or health write-backs.
- **FR-12 (Quick logger):** `[+ Log Session]` opens a bottom sheet with duration chips (`30m`, `1h`, `1.5h`, `2h`) and a racquet selector, saving in ≤ 3 taps and under 10 seconds. The v1 UI shows no notes/surface/location fields.
- **FR-13 (Atomic session batch):** Logging a session is one `WriteBatch`: create `/users/{uid}/sessions/{sessionId}` (`racquetId`, `stringJobId` = current job id, `durationHours`, `playedAt`, `createdAt`) and update the racquet with `currentStringJob.hoursPlayed: FieldValue.increment(hours)` and `updatedAt: serverTimestamp()`. Both writes succeed or neither does, and it works offline.
- **FR-14 (Real-time multi-device sync):** Firestore `.snapshots()` streams push updates to every active screen, window and device without manual refresh.
- **FR-15 (Restrung Today):** Each racquet card and detail view offers `[Restrung Today]`, opening a sheet with `[Keep Same & Reset]` (same specs, hours 0, date today) and `[Change Strings]` (edit material, brand & model, tension, max hours, date before resetting).
- **FR-16 (String job archiving):** A restring moves `currentStringJob` into `pastStringJobs` with `endedAt` = client timestamp and the user-selected `endReason` (`dead` | `broken` | `manual_restring`), then sets a fresh `currentStringJob` with 0 hours.
- **FR-17 (Restring history timeline):** Racquet Detail shows past string jobs newest first with dates, string, court hours and calendar duration (e.g. `Aug 1 – Oct 2 • Luxilon ALU Power • 19.2 court hours • 62 days`).
- **FR-18 (Security rules):** All Firestore access is limited to `/users/{uid}/**` with `request.auth.uid == uid`, plus payload validation: types, ≤ 15 keys per racquet, ≤ 12 keys per session, string length bounds and numeric ranges.
- **FR-19 (App Check):** App Check is activated at startup with Play Integrity on Android and reCAPTCHA Enterprise on Web.
- **FR-20 (Hosting + legal page):** The Flutter Web app is served from Firebase Hosting with SPA rewrites to `/index.html`, while static `/privacy.html` (privacy policy + account deletion steps) is served directly.
- **FR-21 (Telemetry):** Crashlytics on Android (uncaught Flutter and platform errors; no web support), Performance Monitoring, and Analytics events `sign_in`, `racquet_created`, `session_logged`, `racquet_restrung`.
- **FR-22 (Remote Config):** Remote Config initializes with defaults `show_ads: false`, `pro_paywall_trigger: false`, `free_racquet_limit: 99` and activates fetched values on launch. Nothing in v1 changes behaviour based on them.

### NonFunctional Requirements

- **NFR-1 (Animation smoothness):** Radial gauge animations render at 60 fps without dropped frames.
- **NFR-2 (Sync latency):** Snapshot updates reach active UI surfaces within 500 ms of network commit.
- **NFR-3 (Cold start):** Cold start to an interactive Virtual Bag in under 1.5 s, using Firestore local persistence.
- **NFR-4 (Offline logging):** Sessions logged without connectivity are cached locally and committed automatically on reconnection.
- **NFR-5 (Atomic mutations):** Session logs and racquet hours are always written through one atomic `WriteBatch`.
- **NFR-6 (Zero sensitive permissions):** The Android manifest declares no health, body-sensor, activity-recognition or fitness permissions.
- **NFR-7 (Rules bounds):** `firestore.rules` rejects writes exceeding key counts (≤ 15 racquet, ≤ 12 session) or string length bounds.
- **NFR-8 (Play Data Safety):** Play Console declarations match actual collection (name and email from Google Sign-In; racquets, string jobs and sessions under `/users/{uid}`; Crashlytics and Performance diagnostics; encryption in transit; a working deletion mechanism), backed by `/privacy.html` and account deletion.
- **NFR-9 (Accessibility):** Android and Web meet WCAG 2.2 AA. Flows 1–4 (log a session, onboard and add a racquet, restring, delete the account) are verified with TalkBack, NVDA + Chrome and VoiceOver + Safari. The behavioural floor is UX-DR26, and contrast follows the DESIGN.md contrast table. (Promoted from the UX spine's upstream note; the PRD does not yet list it.)
- **SM-C1 (Logger tap budget):** The quick logger needs ≤ 3 taps for 90% of sessions; no mandatory metadata fields may be added.
- **SM-C2 (Read amplification):** Loading the Virtual Bag costs exactly one collection query (`/users/{uid}/racquets`) with zero joined reads.

### Additional Requirements

**Starting point (no starter template).** This is a brownfield migration. The existing `string_theory_flutter` app, `CourtMidnightTheme`, widgets and the pure Dart `string_theory_decay_engine` are the base. No project scaffold story is needed; Epic 1 begins with the Firebase foundation and the v1 cleanup.

**Toolchain and dependencies**
- Upgrade Flutter/Dart from 3.44.4 / 3.12.2 to the latest stable (3.47.7 / 3.13.5 at authoring) as a `chore` story.
- Add each stack package (FlutterFire 7.x train: `firebase_core ^5.1.0`, `firebase_auth ^7.0.1`, `cloud_firestore ^7.1.0`, `firebase_app_check ^0.5.1`, `firebase_crashlytics ^6.0.1`, `firebase_performance ^0.12.1`, `firebase_analytics ^13.0.1`, `firebase_remote_config ^7.0.1`; `google_sign_in ^7.2.0`; dev `fake_cloud_firestore ^4.4.0`) in the first story that needs it, after explicit user approval. FlutterFire packages come from the same release, `pubspec.lock` stays committed, and Android `minSdk` stays at 24 or above.
- Workspace-root `dependency_overrides: equatable: ^3.0.0` (approved in AD-13) so `fake_cloud_firestore` resolves; remove it once `fake_firebase_security_rules` / `cel` accept equatable 3.

**Layering and models (AD-1, AD-2, AD-16)**
- Layers: UI → BLoC → repository interfaces (`lib/domain/`) ← Firestore implementations (`lib/data/`). Only `lib/data/` imports `cloud_firestore`, `firebase_auth` or `google_sign_in`. UI never calls a repository.
- `ErrorReporter` and `AnalyticsSink` interfaces live in `lib/domain/` and are implemented in `lib/services/`. Repositories are the only callers of `ErrorReporter`; BLoCs are the only callers of `AnalyticsSink`.
- The engine owns the single 4-value `StringMaterial` enum, `shelfLifeDays`, `defaultMaxHours`, `healthScore`, `tier`, `tensionLossLbs` and `remainingHours`, with `now` a required parameter. `fromEnum(Enum)`, `other`, `coPoly`, `kevlar` and `hybrid` are removed. `monofilament` takes the former co-poly constants (75 d, 20 h).
- `lib/domain/` re-exports the engine and defines immutable `Racquet`, `StringJob`, `SessionLog`, `EndReason` and `failures`. Map ↔ domain conversion happens only in `lib/data/` mappers.
- `RacquetRepository` exposes exactly `watchRacquets()` and `watchRacquet(id)`; `SessionRepository` exposes `watchSessions()` and `logSession(...)` and writes racquet fields only through `lib/data/racquet_fields.dart` constants.
- One BLoC per feature: `auth`, `bag`, `session_log`, `sessions`, `restring`, `settings`. Data BLoCs are created under the auth gate's signed-in subtree. State is immutable with `equatable`.

**Wire contract (AD-3, AD-4)**
- The AD-3 table is the single schema for mappers, `lib/domain/schema_bounds.dart`, `racquet_fields.dart` and `firestore.rules`; the same PR updates all four.
- Optional fields are absent when empty and cleared with `FieldValue.delete()`; the only nulls are `currentStringJob.endedAt` / `endReason`. Numbers travel as `double` (decode with `(v as num).toDouble()`).
- A pending server timestamp (`null` in a local snapshot) decodes to `clock.now()` and is never a decode failure.
- An unknown stored material produces a typed decode failure reported through `ErrorReporter`, and that racquet is left out of the stream.

**Mutations (AD-5, AD-6, AD-14, AD-15)**
- The only writes are `addRacquet`, `updateRacquet`, `deleteRacquet`, `setPrimary` (batch), `logSession` (batch) and `restring` (update with `arrayUnion`); none uses `runTransaction`. Mutations take the domain object the user acted on.
- Mutations complete when the write is accepted into the local cache (not on server acknowledgement). Late rejections go to `ErrorReporter` (except expected permission-denied after sign-out or `unavailable`) and to `RacquetRepository.failures` (`Stream<MutationFailure>`), shown as a bag snackbar. Pending state reaches the domain as `isPendingSync` from `hasPendingWrites`.
- Accepted races: a session syncing after a restring adds to the new job; a session batch against a racquet deleted elsewhere is rejected whole; a second offline restring of the same job is rejected by the `id` check. Readers dedupe `pastStringJobs` by `id`.
- String job construction: `maxHours` never null; forms fill it from `defaultMaxHours` and refill on material change only if untouched; Keep Same copies material, brand, tension, maxHours with `strungAt = clock.now()` and `manual_restring`; Change Strings defaults to `manual_restring` with optional dead/broken; a picked date is stored as that local date at 12:00 local, converted to UTC; every new job gets `collection(...).doc().id`.

**Health and primary (AD-7, AD-8)**
- No document stores any health-derived field. `RacquetHealth.of(StringJob, DateTime now)` is the only producer of health figures.
- BLoCs recompute on every racquet snapshot and on `AppResumed`, sent by one `AppLifecycleListener` in the app shell. "Now" comes from `package:clock`; no timers.
- `resolvePrimary(List<Racquet>)` is the only primary resolver: earliest `createdAt` among flagged racquets (or all if none flagged), ties by lowest document id.

**Auth and account lifecycle (AD-9, AD-10)**
- `AuthRepository` is the only way into auth. Android: `GoogleSignIn.instance.initialize(serverClientId: <flavor web client id>)` once, then `authenticate()` → `idToken` → `GoogleAuthProvider.credential` → `signInWithCredential`; sign-out also calls `GoogleSignIn.instance.signOut()`. Web: `signInWithPopup(GoogleAuthProvider())`. Re-auth follows the same split; `user-mismatch` aborts with a typed failure.
- `ensureUserDoc()` runs on every auth state with a user, before the route gate opens: create with `createdAt` if absent, otherwise update only `email` / `displayName`.
- `delete-user-data` extension configured with path `users/{UID}` and delete mode Recursive; the client never deletes that data itself. Replace it with a self-owned 2nd-gen `onUserDeleted` function calling `recursiveDelete` before **2027-03-31** (Extensions shutdown).
- Repository streams complete without error when the auth uid changes or becomes null; permission-denied errors after the change are dropped. Deletion calls `currentUser.delete()` first, re-authenticates on `requires-recent-login`, and retries; on failure the streams keep running. Sign-out clears in-memory BLoC state only; `clearPersistence()` is never called with pending writes. Rules allow writes only while `/users/{uid}` exists.

**Bootstrap (AD-11)**
- `main()` runs in `runZonedGuarded`, in order: `Firebase.initializeApp(options: <flavor>)` → `FirebaseAppCheck.instance.activate(providerAndroid: AndroidPlayIntegrityProvider() | AndroidDebugProvider(), providerWeb: ReCaptchaEnterpriseProvider(siteKey) | WebDebugProvider())` → Crashlytics hooks on `FlutterError.onError` and `PlatformDispatcher.onError` (Android only) → `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true, webPersistentTabManager: WebPersistentMultipleTabManager())` → Remote Config `setDefaults` + `activate()` with `fetch()` in the background → auth gate.

**Environments and release (AD-12)**
- Two Firebase projects, `dev` and `prod`, with `.firebaserc` aliases of the same names.
- Android `applicationId` `dev.francescoantonioberardi.stringtheory` with Gradle flavors `prod` and `dev` (`applicationIdSuffix ".dev"`); per-flavor `android/app/src/<flavor>/google-services.json` and `lib/firebase_options_<flavor>.dart` from `flutterfire configure`.
- Builds use `--flavor X --dart-define=FLAVOR=X` with no default flavor; `main()` stops if `FLAVOR` is missing or (Android) mismatches `appFlavor`.
- SHA-1/SHA-256 registered per project: debug + upload + Play App Signing for prod; debug for dev.
- App Check runs monitor-only in prod until verified requests reach ≥ 98% (SM-3), then is enforced on Firestore.
- Extension config lives in the repo (`firebase.json` `extensions` + `extensions/*.env`) and is deployed to both projects.
- Release: signed AAB built locally → Play internal track → production.
- Deploy is manual from `main` after green CI, dev then prod: `firebase deploy -P <alias> --only hosting,firestore:rules,firestore:indexes,extensions`.
- Blaze plan is required by the extension, so billing budget alerts and Firestore PITR/backups are set up before prod opens to the public.

**Testing and CI (AD-13, CI convention)**
- BLoCs: `bloc_test` + `mocktail` fakes of repository interfaces. Repositories: `fake_cloud_firestore`; the first repository story adds one emulator test with the network off proving `increment` and `arrayUnion` are queued and applied. Rules: `@firebase/rules-unit-testing` 6.0.0 (Node ≥ 24.12) in `rules_test/`, one positive and one negative test per AD-5 shape. Engine: `dart test`.
- CI jobs: `flutter analyze --fatal-infos`, `dart format`, engine `dart test`, `flutter test`, rules emulator tests, `flutter build web`; all required before merge. Patrol and Serverpod jobs are removed.

**Conventions**
- Errors: repositories convert `FirebaseException` to typed failures in `lib/domain/failures.dart`; BLoCs map failures to states and never inspect Firebase codes.
- Telemetry: snake_case events `sign_in` (with `is_new_user`), `racquet_created`, `session_logged`, `racquet_restrung`; email and display name never appear in telemetry; uid may be the Crashlytics user id.
- Remote Config: one service with typed getters for exactly the three keys.
- Offline: Firestore persistence is the only offline mechanism; `offline_session_queue.dart` is removed.

**v1 cleanup (bound to NFR-6 and PRD non-goals)**
- One cleanup story removes `string_theory_server`, `string_theory_client`, `serverpod_*`, `health`, `shared_preferences`, health services and widgets, the offline queue, the dev/judge controls (`SeedSampleBag`, `FastForwardRacquetAge`, Simulate Workout), Health Connect manifest entries, and the Serverpod/Patrol/health CI jobs. Each removal needs explicit user approval, and AGENTS.md (which currently forbids modifying the Serverpod packages and lists them as workspace members) is updated in the same story.

**Open decisions that gate specific stories**
- Web Analytics consent (EU visitors): banner or Consent Mode must be decided before the web URL is announced publicly. Does not block Android launch.
- Keyboard shortcuts switch storage: browser storage (new dependency) vs a field on `/users/{uid}` (AD-3 change). Until decided, the switch resets to on each visit.

**Store compliance operations**
- Play Console: privacy policy URL → `/privacy.html`; account deletion URL → the hosted web app; Data Safety form per NFR-8.
- Keep `README.md` accurate to what has shipped on `main` (AGENTS.md policy).

**Still-relevant carryovers from deferred-work.md** (all Serverpod-, health- and guest-specific items become obsolete with the cleanup)
- Bag grid uses a fixed `mainAxisExtent`, which overflows at large text scales; card height must be flexible (ties to UX 200% text scaling).
- Racquet Detail stretches to window width on tablet/desktop; constrain its content width.
- Bag/Sessions/Settings destinations are defined twice (`BagBottomNav`, `BagNavigationRail`); use one shared destinations constant.
- Raw exception text reaches users; replace with typed failures and friendly messages (covered by the Errors convention).
- `SessionsPlaceholder` shows stale copy; replace it with the real Sessions screen.
- A future stringing date counts as 0 days elapsed (100% health); the form should reject future dates.

### UX Design Requirements

- **UX-DR1 (Theme tokens):** `CourtMidnightTheme` gains `outline` (`#6B767B`, mapped to `colorScheme.outline`), `on-primary` (`#000000`) and a `focus-ring` spec; `bodySmall` moves from `textTertiary` to `textSecondary`; a `data` text style (JetBrains Mono 12/16) joins `metricHero` as a `ThemeExtension` field. All styling stays in `lib/theme/`.
- **UX-DR2 (Focus ring):** Every focusable element shows a 2px `primary` outline drawn 2px outside the component, following its radius, whenever it has keyboard focus. Hover never replaces focus.
- **UX-DR3 (Radial Health Gauge):** Full round-capped ring on a 6px `surface-border` track, arc colored by tier, center percentage in `metric-hero` above an uppercase `HEALTH` micro-label. 64px on cards, at least 128px on Racquet Detail; the diameter scales with the text scaler so the center never clips. Value and color tween over 750 ms ease-out from the previous value on data change or app resume; static under reduce motion. Semantics label uses the settled value, e.g. `Wilson Blade 98: string health 82 percent, Optimal, 4 hours played, 12 hours remaining until dead zone`, plus `, waiting to sync` when pending; no glyphs.
- **UX-DR4 (Tier Label):** `✓ Optimal`, `~ Caution`, `⚠ Restring` in `body-secondary`, tier-colored, always visible on cards and Racquet Detail.
- **UX-DR5 (Racquet Card):** Gauge and Tier Label on the left; center shows the wrapping (never truncated) name, the string line (brand & model or material, plus `@ {tension} lbs` when set), the usage line `{hours} h played • {days} days`, and the companion line `~{x} lbs tension drop • {n} h left` (tension part omitted without tension; `Restring recommended` at 0 h left). Right side: `[Restrung Today]` (secondary) and `Log` (text button with timer icon) as sibling buttons, never inside the card's tap target. The card body opens Racquet Detail. Critical (< 40%): `health-critical` border on `health-critical-bg`, nothing pulses. Pending: `Waiting to sync` line with cloud-upload icon, no color change. At ≥ 130% text or when content doesn't fit, actions move to a full-width row below. Semantics: one container whose `Open details` label merges name, string line and gauge label, followed by `Log session for {racquet}` and `Restrung today: {racquet}`. Do not copy the mockup's iPhone frame, five tabs, match results, orange 45% card, `Needs Restring!`/`ACTIVE` labels, glowing resting cards, ¾ arc with knob, photos, or missing actions.
- **UX-DR6 (Bag Order):** Primary racquet (per `resolvePrimary`) first, then the rest by `createdAt` ascending; the Quick-Log selector uses the same order.
- **UX-DR7 (Primary Badge):** `Primary` pill (primary text, 1px primary border, transparent) next to the name on Racquet Detail only, shown in place of the Set as Primary action.
- **UX-DR8 (Bag Sync Summary):** One `body-secondary` line under the bag header, `N changes waiting to sync` / `1 change waiting to sync`, visible only while writes are pending. Not tappable, not a live region.
- **UX-DR9 (Log Session FAB):** Add icon + `Log Session` label, extended on medium/expanded widths and icon-only on compact; fixed while the list scrolls; bottom right of the content area (never in the rail/drawer); hidden on an empty bag; tooltip shows the `L` key on web.
- **UX-DR10 (Quick-Log Sheet):** Title `Log Session` + Sheet Close Button; four duration chips with `1h` pre-selected and a check icon on the selected chip; wrapping racquet selector (2px primary border + check on the selected item), pre-selected from the opening card or `resolvePrimary`; full-width `Save Session` pinned to the bottom. Closes as soon as the device accepts the write and shows `1.5h logged • Wilson Blade 98 at 67%`. No other fields. Chips read `30 minutes`, `1 hour`, `1 and a half hours`, `2 hours` as a mutually exclusive group.
- **UX-DR11 (Restrung Today Sheet):** Prompt `Restrung with the same setup ({brand} @ {tension} lbs)?` with fallbacks `({brand})`, `({material} @ {tension} lbs)`, `({material})`, setup in `data` style. `[Keep Same & Reset]` (primary) resets immediately as `manual_restring`. `[Change Strings]` (secondary) expands pre-filled String material, String brand & model, Stringing date, Tension and Max court hours fields plus reason chips `Routine restring` (default, `manual_restring`), `Strings went dead` (`dead`), `Strings broke` (`broken`), with `Save & Reset` pinned. Success closes the sheet with `Fresh stringbed mounted! Restrung to 100% health.`
- **UX-DR12 (Sheet Close Button):** Close icon button labeled `Close`, ≥ 48×48, at the right of every sheet header; equivalent to swipe-down, scrim tap and `Esc`.
- **UX-DR13 (Add Racquet Form):** Sheet on compact/medium, centered dialog on expanded. Fields: Racquet name (required), String material chips (4, required), String brand & model, Stringing date (M3 date picker, defaults to today), Tension (lbs), Max court hours (pre-filled, helper `Suggested for {material}`, cannot be empty, refilled on material change only if untouched). Required labels carry `(required)`. Validation from `schema_bounds` with range-naming messages (`Tension must be between 20 and 80 lbs`); error outline `health-critical` and `text-primary` message after a ⚠ icon; focus moves to the first invalid field on a failed save. `Save Racquet` closes the form; dismissing with input asks `Discard this racquet?`. Opens by itself after sign-in on an empty bag and announces its title; dismissing it returns focus to `[Add Your First Racquet]`. Opened also by `[+ Add Racquet]` and the `N` key.
- **UX-DR14 (Edit Racquet Form):** Same container and styling; Racquet name and Notes only, same validation; `Save` closes; dismissing with edits asks `Discard your changes?`.
- **UX-DR15 (Racquet Detail):** M3 app bar with tooltipped icon actions Edit, Set as Primary (only when not primary) and Delete Racquet. Single column: gauge + Tier Label, usage and companion lines, current setup and stringing date, `[Restrung Today]`, Restring History Timeline. Content width constrained on wide screens. Detail skeleton while loading. Removed elsewhere: return to bag with `{name} was deleted on another device.` After deleting here: return to bag with focus on the bag header; `resolvePrimary` picks the next default silently. Delete dialog copy: `Delete {name}? Its string history is removed. Sessions you logged stay in your history.`
- **UX-DR16 (Restring History Timeline):** Vertical list, newest first, deduped by job id. Row 1: dates in `data` style; row 2: string (or material), hours and days in `body-secondary`. Dead/broken rows add a critical ⚠ icon and `Went dead` / `Broke`. Empty: `No past string jobs yet.` Semantics read in full words (`August 1 to October 2, Luxilon ALU Power, 19.2 court hours, 62 days`).
- **UX-DR17 (Session Feed):** M3 rows (date in `data`, duration, racquet name), newest first, loading more on scroll with a loading row at the end, wrapping `FilterChip` racquet row narrowing to one racquet. Sessions are read-only. A session whose racquet is gone shows `Deleted racquet`. States: progress row on first load, `No sessions yet. Log one from your bag.`, and `No sessions with {racquet} yet.` with chips still visible.
- **UX-DR18 (Skeleton Card):** Three racquet-card-shaped `surface` blocks with `surface-border` bars under one `Loading your bag` label on a first uncached load; shimmer stops after 5 s and is static under reduce motion.
- **UX-DR19 (Destructive Confirmation Dialog):** Title, a body listing exactly what is removed, `Cancel` (text button, initial keyboard focus) and a destructive-fill confirm button named for the action (`Delete Racquet`, `Delete Account`, never `OK`). `Esc` and scrim mean Cancel. Reading order: title, body, Cancel, confirm.
- **UX-DR20 (Settings):** M3 `ListTile`s with `section` group labels: Account (Google name and email), `[Sign Out]`, Keyboard shortcuts switch (web only, on by default, resets each visit until the storage decision), Privacy Policy (opens the browser on Android), `[Delete Account & All Data]` (`text-primary` text, critical delete icon), app version. Sign Out with pending writes asks `{N} changes are still waiting to sync. Sign out anyway?` with `Stay signed in` / `Sign out`; otherwise it signs out at once.
- **UX-DR21 (Welcome / Sign-In):** Wordmark, `display` headline and one `body` line on string health and arm protection; Google Sign-In button (Google dark variant, not restyled) as the only CTA, showing a `Signing in` progress state that keeps focus. Inline polite messages that persist until the next attempt: `Couldn't sign in. Check your connection and try again.`, `Allow pop-ups for this site to sign in with Google.`, and after deletion `Your account and all data were deleted.` (focus to headline). Cancel returns silently.
- **UX-DR22 (Account deletion states):** Dialog body `This permanently deletes your account, all racquets, string history and sessions. Google may ask you to confirm your account. This can't be undone.` Re-auth canceled → dialog closes, persistent `Account not deleted.` Different account → `That's a different Google account. Account not deleted.` Failure → inline under the row plus persistent snackbar with `Retry`: `Couldn't delete your account. Check your connection and try again.`; the bag keeps working.
- **UX-DR23 (Snackbar):** One at a time with a `primary` text action when present. Confirmations auto-dismiss after ~4 s; failures and late rejections persist with `Dismiss` (deletion failure uses `Retry`). Late rejections name the racquet and what was lost, e.g. `Couldn't save your 1.5h session for Wilson Blade 98 — it was deleted on another device.`
- **UX-DR24 (Responsive navigation and layout):** Destinations Bag, Sessions, Settings from one shared definition. Compact (< 600dp): bottom bar, 1-column bag, bottom sheets. Medium (600–1024dp): `NavigationRail`, 2-column grid, bottom sheets. Expanded (> 1024dp): persistent drawer, 3-column grid, centered dialogs. Grid cells size to content (no fixed extent).
- **UX-DR25 (Keyboard and hover, web):** `L` opens the Quick-Log Sheet and `N` the Add Racquet Form, only on the bag, with no sheet/dialog open, no text field focused, and the switch on; FAB and `[+ Add Racquet]` tooltips show the keys; `Esc` closes the top sheet or dialog. Hover uses Level 2 (`surface-elevated` + 12% primary glow, 16px blur).
- **UX-DR26 (Accessibility floor):** WCAG 2.2 AA on Android and Web. Every interactive element ≥ 48×48. Every health color paired with a label; selected chips and selector items show a check. Text scales to 200% without clipping on Racquet Card, gauge, Quick-Log Sheet, Restrung Today Sheet, Destructive Dialog, navigation labels, Snackbar and Timeline; chip rows wrap; sheets scroll with the keyboard inset while keeping the primary action pinned. Reduce motion makes gauge, sheet/dialog transitions, snackbar slide and shimmer static. Screen titles, sheet/dialog titles and settings group labels are headings. No live regions except outcomes announced through snackbars and inline auth messages. Focus returns to the opener when a sheet or dialog closes. Flows 1–4 are verified with TalkBack, NVDA + Chrome and VoiceOver + Safari.
- **UX-DR27 (Web platform):** Flutter semantics enabled at startup, `lang="en"`, and a page title per route (`My Virtual Bag — String Theory`, `{racquet} — String Theory`). Google sign-in uses a pop-up; tabs share one offline cache.
- **UX-DR28 (Bag states and live behavior):** No refresh control or pull-to-refresh; no offline banner. Restored session renders the bag straight from cache with no welcome screen. Empty bag shows an illustration and `[Add Your First Racquet]` with the FAB hidden. A racquet that fails to decode is left out silently and reported.
- **UX-DR29 (Voice and color rules):** Sync copy says what is waiting (`Waiting to sync`), never `Offline` or `Network error`; deletion copy lists exactly what goes. Crimson text only on `background` and `health-critical-bg`; elsewhere error text is `text-primary` after a critical ⚠ icon. Destructive fill only on the confirm button inside the destructive dialog; triggers use `text-primary` text with a critical icon. Any new color pair needs a contrast ratio added to DESIGN.md before shipping.

### FR Coverage Map

- FR-1: Epic 1 - Google-only sign-in on Android and Web
- FR-2: Epic 1 - Session persistence and restore on launch
- FR-3: Epic 1 - Sign-out (basic); Epic 3 - sign-out confirmation while writes are pending
- FR-4: Epic 5 - Account deletion with re-authentication and the `delete-user-data` purge
- FR-5: Epic 2 - Add racquet with embedded `currentStringJob`
- FR-6: Epic 2 - Live Virtual Bag with health gauges
- FR-7: Epic 4 - Edit name/notes and delete racquet
- FR-8: Epic 4 - Set as Primary (Epics 2–3 already resolve a default primary via `resolvePrimary`)
- FR-9: Epic 2 - Engine refactor (4 materials, companion metrics) and `RacquetHealth.of` shown on cards
- FR-10: Epic 2 - Engine tiers, tier colors and labels in the UI
- FR-11: Epic 2 - Health recomputed on snapshot and app resume, never stored
- FR-12: Epic 3 - Quick-Log Sheet (≤ 3 taps)
- FR-13: Epic 3 - Atomic `logSession` WriteBatch
- FR-14: Epic 2 - Live racquet streams; Epic 3 - live session feed
- FR-15: Epic 4 - Restrung Today (Keep Same & Reset, Change Strings)
- FR-16: Epic 4 - Archive to `pastStringJobs` with end reason
- FR-17: Epic 4 - Restring History Timeline
- FR-18: Epic 1 - rules harness and user doc; Epic 2 - racquet create; Epic 3 - `logSession`; Epic 4 - `updateRacquet`, `deleteRacquet`, `setPrimary`, `restring`
- FR-19: Epic 1 - App Check activated (monitor mode); Epic 5 - enforcement in prod
- FR-20: Epic 5 - Firebase Hosting with SPA rewrites and `/privacy.html`
- FR-21: Epic 1 - Crashlytics, Performance, Analytics services and `sign_in`; Epic 2 - `racquet_created`; Epic 3 - `session_logged`; Epic 4 - `racquet_restrung`
- FR-22: Epic 1 - Remote Config defaults and activation

**NFR coverage:** NFR-1 Epic 2 (gauge); NFR-2 Epics 2–3; NFR-3 Epics 1–2 (bootstrap and cached bag); NFR-4, NFR-5, SM-C1 Epic 3; NFR-6 Epic 1 (cleanup), verified in Epic 5; NFR-7 Epics 1–4 (rules per shape); NFR-8 Epic 5; NFR-9 accessibility ACs on every UI story, screen-reader verification in Epic 5; SM-C2 Epic 2.

## Epic List

### Epic 1: Sign in with Google
Users sign in with Google on Android or Web, stay signed in across relaunches, and can sign out from Settings. The app runs on Firebase (dev and prod flavors, App Check in monitor mode, telemetry and Remote Config), the theme carries the v1 tokens and focus ring, and Serverpod, health integrations and demo controls are gone. Between the auth story and Epic 2 the bag shows an empty placeholder; this is accepted because there are no production users.
**FRs covered:** FR-1, FR-2, FR-3 (basic), FR-18 (rules harness, user doc), FR-19 (monitor mode), FR-21 (services, `sign_in`), FR-22
**Implementation notes:** Story order: Flutter upgrade → theme tokens and focus ring → Firebase projects, flavors and bootstrap → telemetry and Remote Config → auth repository with user-doc rules and the rules CI job → Welcome, auth gate and shell (Patrol step removed) → v1 cleanup (explicit approval, Serverpod CI jobs removed, AGENTS.md updated). The engine refactor opens Epic 2 because `string_theory_server` depends on the engine and cannot be modified before the cleanup.

### Epic 2: Build my live Virtual Bag
The decay engine moves to exactly four materials with typed companion metrics. Users add racquets and see each one's live health gauge, tier and companion metrics, computed on the device and synced across devices and tabs, with skeleton, empty and cold-start states.
**FRs covered:** FR-5, FR-6, FR-9, FR-10, FR-11, FR-14, FR-18 (racquet create), FR-21 (`racquet_created`)

### Epic 3: Log sessions in seconds, online or offline
Users log a session in three taps from the FAB or a card, even with no signal; pending writes show `Waiting to sync`, late rejections are reported, sign-out warns about unsynced changes, and the Sessions screen lists history with racquet filters.
**FRs covered:** FR-3 (pending-writes confirmation), FR-12, FR-13, FR-14, FR-18 (`logSession`), FR-21 (`session_logged`)

### Epic 4: Manage racquets and the restring lifecycle
Users open Racquet Detail, edit name and notes, set a primary, delete a racquet, restring with Keep Same or Change Strings (routine, dead or broken), and review the restring history timeline.
**FRs covered:** FR-7, FR-8, FR-15, FR-16, FR-17, FR-18 (`updateRacquet`, `deleteRacquet`, `setPrimary`, `restring`), FR-21 (`racquet_restrung`)

### Epic 5: Account control, store compliance and public launch
Users can delete their account and all data from Android or Web, read a public privacy policy, and install the app from Google Play or use it on Firebase Hosting with App Check enforced. Includes web keyboard shortcuts and page titles, the screen-reader verification pass, Play release, and, as the last story after launch, replacing the deletion extension with a self-owned v2 function before 2027-03-31.
**FRs covered:** FR-4, FR-19 (enforcement), FR-20; NFR-6 (verified), NFR-8, NFR-9 (verification)
**Implementation notes:** Two open decisions gate stories here: keyboard-shortcut storage, and web Analytics consent before the web URL is announced.

## Epic 1: Sign in with Google

Users sign in with Google on Android or Web, stay signed in across relaunches, and can sign out from Settings. The app runs on Firebase with dev and prod flavors, App Check in monitor mode, telemetry and Remote Config. The theme carries the v1 tokens and focus ring, and Serverpod, health integrations and demo controls are removed. Until Epic 2 lands, the signed-in Bag shows an empty placeholder, which is acceptable because there are no production users.

### Story 1.1: Upgrade Flutter and Dart to the latest stable SDK

As a developer,
I want the workspace on the latest stable Flutter and Dart,
So that the FlutterFire 7.x packages added in later stories resolve on a supported SDK.

**Acceptance Criteria:**

**Given** the workspace pins Flutter 3.44.4 / Dart ^3.12.2
**When** the SDK constraints in every workspace `pubspec.yaml` and the `flutter-version` in `analyze.yml`, `format.yml` and `tests.yml` are moved to the latest stable release (3.47.7 / 3.13.5 at authoring, or newer if released)
**Then** `flutter pub get` resolves the whole workspace with no dependency added, upgraded or removed
**And** `flutter analyze --fatal-infos`, `dart format --set-exit-if-changed .`, the engine's `dart test` and `flutter test` all pass locally and in CI
**And** any new lints or deprecations the SDK raises are fixed in this story, not suppressed
**And** AGENTS.md and README.md name the new SDK versions
**And** the commit is a `chore(flutter): ...` Conventional Commit

### Story 1.2: Court Midnight v1 tokens and keyboard focus ring

As a player using a keyboard or a screen reader,
I want every control to show a clear focus ring and readable secondary text,
So that I can see where I am and read all the information in the app.

**Acceptance Criteria:**

**Given** `CourtMidnightTheme` in `lib/theme/court_midnight_theme.dart`
**When** the v1 tokens are added
**Then** it exposes `outline` (`#6B767B`, mapped to `colorScheme.outline`), `onPrimary` (`#000000`) and a focus-ring spec (2px `primary`, 2px offset), and `bodySmall` uses `textSecondary` instead of `textTertiary` (UX-DR1)
**And** a `data` text style (JetBrains Mono 400, 12/16) is added next to `metricHero` as a `ThemeExtension` field (UX-DR1)
**And** text fields, unselected chips and the racquet selector use `outline` for their interactive boundary, never `surfaceBorder` (UX-DR29)

**Given** any focusable M3 control (buttons, chips, text fields, list tiles, navigation items, the FAB)
**When** it receives keyboard focus
**Then** a 2px `primary` ring is drawn 2px outside the component, following its radius, and is visible on `background`, `surface` and `surface-elevated` (UX-DR2)
**And** hover never replaces the focus ring

**Given** the theme is applied
**When** widget tests inspect the resolved `ThemeData`
**Then** every new token and text style is asserted by value
**And** no widget file in `lib/screens/` or `lib/widgets/` hardcodes a color, text style or decoration (AGENTS.md styling rule)

### Story 1.3: Firebase dev and prod projects with flavored Android and Web builds

As the app owner,
I want separate dev and prod Firebase projects selected by an explicit build flavor,
So that development never touches real user data and the app cannot start against the wrong project.

**Acceptance Criteria:**

**Given** the user has created the `dev` and `prod` Firebase projects and registered the Android and Web apps (manual console steps documented in README.md)
**When** this story is implemented
**Then** `.firebaserc` defines the aliases `dev` and `prod`, and `firebase.json` exists at the repo root
**And** `firebase_core`, `firebase_app_check` and `cloud_firestore` are added at the AD-12 stack versions only after explicit user approval, with `pubspec.lock` committed

**Given** the Android app currently uses `com.example.string_theory_flutter`
**When** flavors are configured
**Then** the `applicationId` and namespace become `dev.francescoantonioberardi.stringtheory`, with Gradle `productFlavors` `prod` and `dev` (`applicationIdSuffix ".dev"`), and `minSdk` stays at 24 or above
**And** each flavor has its own `android/app/src/<flavor>/google-services.json` and `lib/firebase_options_<flavor>.dart` generated by `flutterfire configure`, committed as public config (AD-12)
**And** README.md lists the SHA-1/SHA-256 fingerprints each project needs: debug for dev; debug, upload and Play App Signing for prod

**Given** the app is launched
**When** `--dart-define=FLAVOR` is missing, or on Android does not match `appFlavor`
**Then** `main()` stops immediately with a clear error, and there is no default flavor

**Given** a valid flavor
**When** `main()` runs inside `runZonedGuarded`
**Then** it calls `Firebase.initializeApp` with that flavor's options, then `FirebaseAppCheck.instance.activate(providerAndroid: AndroidPlayIntegrityProvider() | AndroidDebugProvider(), providerWeb: ReCaptchaEnterpriseProvider(siteKey) | WebDebugProvider())`, with prod providers in prod and debug providers in dev (AD-11 steps 1–2, FR-19 monitor mode)
**And** it then sets `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true, webPersistentTabManager: WebPersistentMultipleTabManager())` before any other Firestore use (AD-11 step 4)
**And** `flutter run --flavor dev --dart-define=FLAVOR=dev` starts on Android and Web, and README.md documents the run and build commands for both flavors

**Given** Firebase is a newly introduced SDK
**When** the story starts
**Then** the user is asked whether to install Firebase's official MCP server and agent skills, with step-by-step setup instructions if they agree (AGENTS.md tooling policy)

### Story 1.4: Crash reporting, performance, analytics and Remote Config services

As the app owner,
I want crashes, performance and key events reported from day one, and remote flags ready,
So that I can see problems after launch and adjust monetization later without a store release.

**Acceptance Criteria:**

**Given** `firebase_crashlytics`, `firebase_performance`, `firebase_analytics` and `firebase_remote_config` are added at the stack versions after explicit user approval
**When** `main()` bootstraps on Android
**Then** `FlutterError.onError` and `PlatformDispatcher.onError` forward to Crashlytics, right after App Check activation (AD-11 step 3)
**And** on Web no Crashlytics hooks are installed, because Crashlytics has no web support

**Given** the AD-1 layering
**When** the telemetry seams are added
**Then** `ErrorReporter` and `AnalyticsSink` interfaces live in `lib/domain/`, and their Firebase implementations live in `lib/services/`
**And** `AnalyticsSink` accepts only the snake_case events `sign_in` (with `is_new_user`), `racquet_created`, `session_logged` and `racquet_restrung`, and never accepts email or display name as parameters
**And** unit tests use fakes of both interfaces, with no Firebase SDK in the test

**Given** the Remote Config service
**When** the app starts
**Then** `setDefaults` sets exactly `show_ads: false`, `pro_paywall_trigger: false`, `free_racquet_limit: 99`, `activate()` runs, and `fetch()` runs in the background without blocking the first frame (AD-11 step 5, FR-22)
**And** the service exposes one typed getter per key, and nothing in the app changes behaviour based on them
**And** a unit test proves the first frame is not delayed by a slow fetch

**Given** Performance Monitoring is added
**When** the app runs
**Then** automatic traces are collected with no custom trace code required in v1

### Story 1.5: Google account provisioning and user-document security rules

As a player,
I want signing in with Google to create my private account record securely,
So that my data lives under my account and nobody else can read or write it.

**Acceptance Criteria:**

**Given** `firebase_auth` and `google_sign_in` are added at the stack versions after explicit user approval, and Google is the only enabled sign-in provider in both projects
**When** `AuthRepository` (interface in `lib/domain/`, `FirebaseAuthRepository` in `lib/data/`) is implemented
**Then** on Android it calls `GoogleSignIn.instance.initialize(serverClientId: <flavor's web client id>)` exactly once, then `authenticate()`, builds `GoogleAuthProvider.credential` from the `idToken`, and calls `signInWithCredential` (AD-9)
**And** on Web it calls `signInWithPopup(GoogleAuthProvider())`
**And** sign-out calls `FirebaseAuth.signOut()` and, on Android, `GoogleSignIn.instance.signOut()`
**And** it exposes the current user as a stream, plus typed failures for canceled, popup-blocked and network errors (no Firebase error codes leave `lib/data/`)

**Given** an auth state with a user (fresh sign-in or restored session)
**When** `ensureUserDoc()` runs
**Then** it creates `/users/{uid}` with `email`, optional `displayName` and server `createdAt` if the document doesn't exist, and otherwise updates only `email` and `displayName` (AD-9, AD-3)
**And** a repository test with `fake_cloud_firestore` covers create, update and the immutable `createdAt`, using the approved workspace `dependency_overrides: equatable: ^3.0.0`

**Given** `firestore.rules` and `firestore.indexes.json` at the repo root
**When** the user-document rules are written (via the `firestore-rules-author` subagent or the rules skills, per AGENTS.md)
**Then** `/users/{uid}` allows read only to the owner, create with the AD-3 fields and ≤ 10 keys, update of only `email`/`displayName`, and every other path is denied (FR-18)
**And** `rules_test/` (npm, `@firebase/rules-unit-testing` 6.0.0, Node ≥ 24.12) has at least one positive and one negative test per user-document operation, including a different uid and an attempt to change `createdAt`
**And** a CI job runs the rules tests against the Firestore emulator and is required before merge

### Story 1.6: Welcome screen, auth gate, signed-in shell and sign-out

As a player,
I want to sign in with one tap, land in the app, stay signed in on relaunch, and sign out from Settings,
So that my account is the only way into my bag.

**Acceptance Criteria:**

**Given** no signed-in user
**When** the app starts
**Then** the Welcome screen shows the wordmark, a `display` headline, one `body` line about string health and arm protection, and the Google Sign-In button in Google's dark variant as the only call to action (UX-DR21, FR-1)
**And** no core route can be reached without a signed-in user

**Given** the Welcome screen
**When** the user taps the Google button
**Then** the button shows a `Signing in` progress state and keeps focus until sign-in completes
**And** if the user cancels, they return to Welcome silently
**And** on failure, an inline polite message reads `Couldn't sign in. Check your connection and try again.`, and on a blocked web pop-up it reads `Allow pop-ups for this site to sign in with Google.`; each message stays until the next attempt (UX-DR21)

**Given** sign-in succeeds or a session is restored on launch
**When** the auth gate receives the user
**Then** `ensureUserDoc()` completes before the signed-in shell opens (AD-9), and a restored session goes straight to the shell with no Welcome screen (FR-2)
**And** an `AuthBloc` emits signed-in / signed-out states; data BLoCs added later are created under the signed-in subtree
**And** `sign_in` is sent through `AnalyticsSink` with `is_new_user` on a fresh sign-in only

**Given** the signed-in shell
**When** it renders
**Then** the destinations Bag, Sessions and Settings come from one shared definition, shown as a bottom bar under 600dp, a `NavigationRail` from 600 to 1024dp, and a persistent drawer above 1024dp (UX-DR24)
**And** Bag and Sessions show a neutral empty placeholder with no internal planning vocabulary, which Epics 2 and 3 replace

**Given** Settings
**When** it renders
**Then** an Account group shows the Google name and email, and a `[Sign Out]` row signs the user out at once, clears in-memory BLoC state and returns to Welcome (FR-3)
**And** `clearPersistence()` is never called

**Given** this story replaces the guest and email authentication
**When** it merges
**Then** the old `AuthService`, the email sign-in screen and their tests are removed from the app's startup path, and the Patrol E2E step is removed from `tests.yml`, so CI stays green
**And** the Welcome and Settings screens meet the accessibility floor: 48dp targets, headings, semantic labels and 200% text with no clipping (UX-DR26)
**And** web routes set page titles such as `My Virtual Bag — String Theory` and the app enables semantics at startup with `lang="en"` (UX-DR27)

### Story 1.7: Remove Serverpod, health integrations and hackathon controls

As a player installing from Google Play,
I want an app that asks for no health or fitness permissions and carries no demo controls,
So that I can trust what it accesses and the store review passes without a Health Connect declaration.

**Acceptance Criteria:**

**Given** the user has explicitly approved each removal listed below (AGENTS.md dependency policy)
**When** the cleanup is applied
**Then** `string_theory_server/` and `string_theory_client/` are deleted and removed from the workspace `pubspec.yaml`
**And** `serverpod_flutter`, `serverpod_auth_idp_flutter`, `string_theory_client`, `health`, `shared_preferences`, `patrol_finders` and the `flutter_secure_storage` override are removed from `string_theory_flutter/pubspec.yaml`
**And** `lib/client.dart`, `lib/services/health/`, `lib/services/offline_session_queue.dart`, `lib/widgets/health/`, `lib/widgets/workout_assignment/`, `workout_assignment_sheet.dart`, `simulate_workout_badge.dart`, the Serverpod-backed `BagBloc` and every `SeedSampleBag`, `FastForwardRacquetAge` and Simulate Workout path are deleted with their tests
**And** every other file in `lib/` and `test/` that imports `string_theory_client`, `serverpod_*`, `health` or `shared_preferences` (today including the old racquet card, bag list, Racquet Detail, restring sheet, timeline tile, Sessions screen, session card, Add Racquet modal and racquet presets) is either deleted with its tests or stripped of those types; Epics 2–4 rebuild those surfaces on the domain models, reusing pure widgets such as the radial gauge where they carry no Serverpod types
**And** the signed-in shell from Story 1.6 still builds and runs with the Bag and Sessions placeholders

**Given** the Android manifest
**When** it is inspected after the cleanup
**Then** it declares no health, body-sensor, activity-recognition or fitness permissions and no Health Connect activity aliases (NFR-6)
**And** a test or CI check fails if any such permission is reintroduced

**Given** CI
**When** the cleanup merges
**Then** the `server-tests` and `migration-verify` jobs are removed, and the remaining jobs (analyze, format, engine `dart test`, `flutter test`, rules emulator tests, `flutter build web`) pass

**Given** AGENTS.md and README.md
**When** the cleanup merges
**Then** AGENTS.md no longer lists the Serverpod packages as workspace members, drops the rule forbidding changes to them, and drops the Serverpod and Patrol verification notes
**And** README.md describes only what ships on `main`
**And** `flutter analyze --fatal-infos` and `dart format --set-exit-if-changed .` pass from the repo root

## Epic 2: Build my live Virtual Bag

The decay engine moves to exactly four materials with typed companion metrics. Users add racquets and see each one's live health gauge, tier and companion metrics, computed on the device and synced across devices and tabs, with skeleton, empty and cold-start states. Card actions (`Log`, `[Restrung Today]`) and Racquet Detail arrive with the epics that make them work.

### Story 2.1: Decay engine with exactly four string materials and typed companion metrics

As a player,
I want health, tension drop and remaining hours computed the same way everywhere from four clear material types,
So that every screen agrees on how worn my strings are.

**Acceptance Criteria:**

**Given** `string_theory_decay_engine` today has a 7-value `DomainStringMaterialCategory`, `fromEnum(Enum)` and a formatted tension-loss string
**When** the engine is refactored (AD-2, AD-4)
**Then** it exposes one `StringMaterial` enum with exactly `monofilament`, `multifilament`, `syntheticGut` and `naturalGut`, stored by name
**And** each material provides `shelfLifeDays` (75 / 180 / 180 / 365) and `defaultMaxHours` (20 / 35 / 30 / 50)
**And** `coPoly`, `kevlar`, `hybrid`, `other` and `fromEnum(Enum)` are removed

**Given** hours played, max hours, strung date, material and a required `now`
**When** the engine computes health
**Then** `healthScore` = max(0, round(100 − (hours / maxHours × 70 + daysElapsed / shelfLife × 30))) (FR-9)
**And** `tier` returns optimal for ≥ 70, degraded for 40–69 and critical for < 40 (FR-10)
**And** `tensionLossLbs` = tension × (100 − score) / 100 × 0.25 as a `double`, and is absent when no tension is set
**And** `remainingHours` = max(0, round((score − 40) / 70 × maxHours))
**And** a strung date later than `now` counts as 0 days elapsed

**Given** the engine's `dart test` suite
**When** it runs
**Then** it covers every material's constants, the tier boundaries 39/40/69/70, zero and over-limit hours, future dates, and at least these fixtures: monofilament, 0 h, 21 days → 92; monofilament, 19 h of 20, 70 days → 6
**And** the Flutter app compiles against the new API, with call sites in `lib/` updated and no formatting of numbers left inside the engine

### Story 2.2: Racquet domain model and live racquet stream

As a player,
I want my racquets to load from my account in one read and stay live while I use the app,
So that my bag is always current on every device and opens instantly from cache.

**Acceptance Criteria:**

**Given** the AD-2 and AD-3 contracts
**When** the domain layer is added
**Then** `lib/domain/` re-exports the engine and defines immutable `Racquet` (`id`, `name`, `notes?`, `isPrimary`, `currentStringJob`, `pastStringJobs`, `createdAt`, `updatedAt`, `isPendingSync`), `StringJob` (`id`, `material`, `brand?`, `tensionLbs?`, `strungAt`, `hoursPlayed`, `maxHours`, `endedAt?`, `endReason?`), `EndReason` and typed `failures`
**And** `lib/domain/schema_bounds.dart` holds every AD-3 bound and `lib/data/racquet_fields.dart` holds every racquet field path

**Given** a racquet document
**When** the `lib/data/` mapper decodes it
**Then** absent optional fields map to null, numbers decode with `(v as num).toDouble()`, and a pending server timestamp (`null` in a local snapshot) decodes to `clock.now()` without failing
**And** an unknown material or missing required field produces a typed decode failure reported through `ErrorReporter`, and that racquet is left out of the stream (AD-4)
**And** `isPendingSync` reflects the snapshot's `hasPendingWrites`
**And** `pastStringJobs` duplicates are dropped by `id` (AD-6)

**Given** `RacquetRepository` (interface in `lib/domain/`, Firestore implementation in `lib/data/`)
**When** `watchRacquets()` and `watchRacquet(id)` are subscribed
**Then** the bag costs exactly one query on `/users/{uid}/racquets` with no joined reads (SM-C2)
**And** each stream completes without error when the auth uid changes or becomes null, and permission-denied errors after that change are dropped, not reported (AD-10)
**And** repository tests with `fake_cloud_firestore` cover decode, pending timestamps, unknown material and stream completion

**Given** `lib/domain/`
**When** health and primary are derived
**Then** `RacquetHealth.of(StringJob, DateTime now)` is the only producer of score, tier, tension loss and remaining hours (AD-7)
**And** `resolvePrimary(List<Racquet>)` returns the earliest `createdAt` among flagged racquets, or among all racquets when none is flagged, with ties broken by lowest document id, and returns null for an empty list (AD-8)
**And** unit tests cover zero, one and two flagged racquets

**Given** `firestore.rules`
**When** racquet read rules are added
**Then** only the owner can read `/users/{uid}/racquets/**`, with a positive and a negative test in `rules_test/`

### Story 2.3: Live Virtual Bag with health gauges

As a player,
I want to see every racquet with an animated health gauge, tier and wear details,
So that I know at a glance which strings are fresh and which need restringing.

**Acceptance Criteria:**

**Given** a signed-in user
**When** the Bag destination opens
**Then** a `BagBloc` under the signed-in subtree subscribes to `watchRacquets()` and replaces the Epic 1 placeholder
**And** racquets are ordered primary first (per `resolvePrimary`), then by `createdAt` ascending (UX-DR6)
**And** the bag uses 1, 2 or 3 columns below 600dp, 600–1024dp and above 1024dp, with cells sized to their content rather than a fixed extent (UX-DR24)

**Given** a racquet
**When** its card renders
**Then** the left shows the Radial Health Gauge with the Tier Label (`✓ Optimal`, `~ Caution`, `⚠ Restring`) below it (UX-DR3, UX-DR4)
**And** the center shows the wrapping name, the string line (brand & model, or material, plus `@ {tension} lbs` when set), the usage line `{hours} h played • {days} days`, and the companion line `~{x} lbs tension drop • {n} h left` (tension part omitted without tension; `Restring recommended` at 0 h left) (UX-DR5, FR-6)
**And** below 40% the card uses the `health-critical` border on `health-critical-bg` with no pulsing
**And** while `isPendingSync` is true, a `Waiting to sync` line with a cloud-upload icon appears under the usage line, with no color or border change
**And** all figures come from `RacquetHealth.of` with `now` from `package:clock`, and no health value is written to Firestore (FR-11)

**Given** the gauge
**When** the score changes from a snapshot or an app resume
**Then** value and color tween from the previous value over 750 ms ease-out at 60 fps, and change without animation when reduce motion is on (NFR-1)
**And** the gauge is 64px on cards and scales with the text scaler so its center never clips
**And** its semantics label uses the settled value, e.g. `Wilson Blade 98: string health 82 percent, Optimal, 4 hours played, 12 hours remaining until dead zone`, plus `, waiting to sync` when pending, with no glyphs

**Given** the app shell
**When** the app returns to the foreground
**Then** one `AppLifecycleListener` sends `AppResumed` to the `BagBloc`, which recomputes health without any timer (AD-7)

**Given** loading and empty states
**When** the bag has nothing cached on first load
**Then** three Skeleton Cards appear under one `Loading your bag` label, the shimmer stops after 5 s and is static under reduce motion (UX-DR18)
**And** a restored session with cached data renders the bag straight from cache in under 1.5 s from cold start (NFR-3)
**And** an empty bag shows the empty-bag illustration and a short line; there is no refresh control, pull-to-refresh or offline banner (UX-DR28)

**Given** two signed-in devices or browser tabs
**When** a racquet document changes on one
**Then** the other updates without manual refresh, and web tabs share one offline cache (FR-14, NFR-2)
**And** cards meet the accessibility floor: one semantics container per card, 200% text with no clipping, and every health color paired with its label (UX-DR26)

### Story 2.4: Add a racquet with smart string defaults

As a player,
I want to add a racquet with its string setup in a few fields, with sensible defaults,
So that my bag starts tracking string health right away.

**Acceptance Criteria:**

**Given** `RacquetRepository.addRacquet`
**When** a racquet is added
**Then** it `set`s a new document with the AD-3 fields, server `createdAt` and `updatedAt`, `isPrimary: true` only when the bag is empty, and a `currentStringJob` whose `id` comes from `collection(...).doc().id` with `hoursPlayed: 0` and `endedAt`/`endReason` null (AD-5, AD-15)
**And** the method completes when the write is accepted into the local cache, without awaiting the server; a late server rejection is sent to `ErrorReporter` (AD-14)
**And** a test proves a racquet added while offline appears in `watchRacquets()` at once with `isPendingSync` true

**Given** `firestore.rules`
**When** the racquet create rule is added
**Then** it validates the full AD-3 racquet and StringJob shape (types, ≤ 15 racquet keys, ≤ 10 StringJob keys, string lengths, tension 20–80, hours 0–1000, maxHours > 0 and ≤ 200, `updatedAt == request.time`) and only while `/users/{uid}` exists (FR-18, NFR-7)
**And** `rules_test/` has positive and negative tests for create, including too many keys, an out-of-range tension, a wrong owner and a missing user document

**Given** the bag
**When** the user taps `[+ Add Racquet]` or the empty-state `[Add Your First Racquet]`
**Then** the Add Racquet Form opens as a bottom sheet below 1024dp and as a centered dialog above (UX-DR13)
**And** it has Racquet name (required), String material chips (four, required), String brand & model (one field), Stringing date (M3 date picker, defaults to today, future dates rejected), Tension (lbs) and Max court hours, with `(required)` in the required labels

**Given** the user picks a material
**When** Max court hours has not been edited
**Then** it fills with that material's `defaultMaxHours` and shows `Suggested for {material}`; once edited, changing material leaves it alone, and it can never be left empty (AD-15)

**Given** invalid input
**When** the user taps `Save Racquet`
**Then** each invalid field shows a range-naming message from `schema_bounds` (e.g. `Tension must be between 20 and 80 lbs`) with a `health-critical` outline and a ⚠ icon, and focus moves to the first invalid field
**And** a picked stringing date is stored as that local date at 12:00 local time converted to UTC (AD-15)

**Given** valid input
**When** the user saves
**Then** the form closes, the new card appears in the bag with its gauge animating to the computed score, and `racquet_created` is sent through `AnalyticsSink` (FR-5, FR-21)
**And** dismissing a form that has input asks `Discard this racquet?`

**Given** a first sign-in with an empty bag
**When** the bag opens
**Then** the Add Racquet Form opens by itself and announces its title, and dismissing it returns focus to `[Add Your First Racquet]` (UX-DR13)
**And** the form meets the accessibility floor: 48dp targets, chips announced as a mutually exclusive group with a check icon on the selected one, 200% text, and the keyboard inset scrolls the sheet with `Save Racquet` pinned (UX-DR26)

## Epic 3: Log sessions in seconds, online or offline

Users log a session in three taps from the FAB or a card's `Log` action, even with no signal. Pending writes show `Waiting to sync`, writes the server later rejects are reported, sign-out warns about unsynced changes, and the Sessions screen lists history with racquet filters.

### Story 3.1: Atomic session logging that works offline

As a player on a court with no signal,
I want a logged session to add its hours to my racquet in one atomic step,
So that my hours are never half-saved and sync by themselves when I'm back online.

**Acceptance Criteria:**

**Given** the AD-3 session schema
**When** the domain and data layers are extended
**Then** `lib/domain/` defines an immutable `SessionLog` (`id`, `racquetId`, `stringJobId`, `durationHours`, `playedAt`, `createdAt`, optional `notes`/`surface`/`location`), and a `lib/data/` mapper decodes it with the same absent-vs-null, double and pending-timestamp rules as racquets

**Given** `SessionRepository.logSession(Racquet racquet, double hours)`
**When** it is called
**Then** one `WriteBatch` `set`s `/users/{uid}/sessions/{autoId}` with `racquetId`, `stringJobId = racquet.currentStringJob.id`, `durationHours`, `playedAt = clock.now()` and server `createdAt`, and `update`s the racquet with `currentStringJob.hoursPlayed: FieldValue.increment(hours)` and server `updatedAt`, using only `racquet_fields.dart` paths (FR-13, AD-5, AD-16)
**And** no `runTransaction` is used, `hours` is checked against `schema_bounds` (0.1–24) before writing, and the method completes when the batch is accepted into the local cache (AD-14)
**And** a late server rejection is sent to `ErrorReporter`, except permission-denied after sign-out and `unavailable`

**Given** `firestore.rules`
**When** the session and logSession rules are added
**Then** sessions are create-only with the full AD-3 validation (≤ 12 keys, `durationHours` 0.1–24, string bounds, owner only, user document must exist), and owner-only read
**And** a racquet update matches the logSession shape only when `affectedKeys()` is exactly {`currentStringJob`, `updatedAt`}, only `hoursPlayed` changed inside the job, and it increased (AD-5)
**And** `rules_test/` has a positive and a negative test for the session create and for the logSession racquet update, including a decreased `hoursPlayed`, a changed `material`, and a batch against a racquet that no longer exists (rejected as a whole, AD-6)

**Given** the Firestore emulator with the network disabled
**When** a session is logged and the network is re-enabled
**Then** an emulator test proves the batch is queued locally, the racquet shows the new hours immediately, and after reconnecting the server holds both the session and the incremented hours (AD-13, NFR-4, NFR-5)
**And** a repository test with `fake_cloud_firestore` covers the batch contents and the bounds check

### Story 3.2: Three-tap Quick-Log Sheet

As a player walking off court,
I want to log how long I played and on which racquet in three taps,
So that recording a session takes less than ten seconds.

**Acceptance Criteria:**

**Given** a bag with at least one racquet
**When** it renders
**Then** a `Log Session` FAB with an add icon is fixed at the bottom right of the content area, extended with its label on medium and expanded widths, icon-only on compact, and hidden on an empty bag (UX-DR9)
**And** each racquet card gains a `Log` text button with a timer icon as a sibling of the card's tap target, labeled `Log session for {racquet}` for screen readers; at ≥ 130% text, or when content doesn't fit, card actions move to a full-width row below (UX-DR5)

**Given** the user taps the FAB or a card's `Log`
**When** the Quick-Log Sheet opens
**Then** it shows the title `Log Session`, a Sheet Close Button, four duration chips (`30m`, `1h`, `1.5h`, `2h`) with `1h` pre-selected, and a wrapping racquet selector in bag order (UX-DR10, UX-DR12)
**And** the racquet is pre-selected from the card that opened it, or otherwise from `resolvePrimary`
**And** selected chips and selector items show a check icon and a 2px `primary` border on the selected racquet; chips read `30 minutes`, `1 hour`, `1 and a half hours`, `2 hours` as a mutually exclusive group
**And** there are no other fields (SM-C1)

**Given** the user taps `Save Session`
**When** the device accepts the write
**Then** a `session_log` BLoC calls `logSession`, the sheet closes, focus returns to the control that opened it, and a snackbar reads e.g. `1.5h logged • Wilson Blade 98 at 67%` and auto-dismisses after about 4 s (FR-12, UX-DR23)
**And** `session_logged` is sent through `AnalyticsSink` on local acceptance
**And** the card's gauge animates to the new score
**And** a widget test proves the default path (open, keep `1h` and the pre-selected racquet, save) takes at most 3 taps

**Given** the sheet is open
**When** the user swipes down, taps the scrim, taps Close or presses `Esc`
**Then** the sheet closes without saving
**And** the sheet meets the accessibility floor: 48dp targets, 200% text with wrapping chip rows, and `Save Session` pinned while content scrolls (UX-DR26)

### Story 3.3: Pending-sync status and rejected-write feedback

As a player who logs and edits offline,
I want to see what is still waiting to sync and be told when something couldn't be saved,
So that I never lose a session or a racquet without knowing.

**Acceptance Criteria:**

**Given** one or more racquet documents with pending writes (every session batch, add and edit marks its racquet as pending)
**When** the bag renders
**Then** a Bag Sync Summary line under the header reads `N changes waiting to sync`, where N is the number of racquets with pending writes, derived from the existing bag stream with no extra query (SM-C2) (`1 change waiting to sync` for one) and disappears when nothing is pending (UX-DR8)
**And** it is not tappable and not a live region, and no banner, color change or `Offline` wording is used (UX-DR29)

**Given** a write the device accepted is later rejected by the server
**When** the rejection arrives
**Then** the repository publishes a typed `MutationFailure` on `RacquetRepository.failures` (`Stream<MutationFailure>`) naming the racquet and what was lost, and reports it to `ErrorReporter` (AD-14)
**And** the bag shows a persistent snackbar with `Dismiss`, e.g. `Couldn't save your 1.5h session for Wilson Blade 98 — it was deleted on another device.`, while the card shows the server state (UX-DR23)
**And** permission-denied after sign-out and `unavailable` are neither published nor reported
**And** the same mechanism covers `addRacquet` and `logSession` rejections, and BLoC tests use a fake failures stream

**Given** pending writes exist
**When** the user taps `[Sign Out]` in Settings
**Then** a dialog asks `{N} changes are still waiting to sync. Sign out anyway?` with `Stay signed in` and `Sign out` (FR-3, UX-DR20)
**And** with no pending writes, sign-out happens at once as in Story 1.6
**And** signing out never calls `clearPersistence()`, so queued writes survive and sync on the next sign-in

### Story 3.4: Session history with racquet filters

As a player,
I want to scroll through the sessions I've logged and filter them by racquet,
So that I can see how much I've played on each frame.

**Acceptance Criteria:**

**Given** `SessionRepository.watchSessions()`
**When** the Sessions destination opens
**Then** a `sessions` BLoC under the signed-in subtree shows sessions newest first by `playedAt`, live as new sessions are logged on any device (FR-14), replacing the Epic 1 placeholder
**And** older sessions load page by page as the user scrolls, with a loading row at the end; the page size and any composite index for the racquet filter are chosen in this story and committed to `firestore.indexes.json`

**Given** sessions exist
**When** each row renders
**Then** it shows the date in the `data` style, the duration and the racquet name (UX-DR17)
**And** a session whose racquet no longer exists shows `Deleted racquet`
**And** sessions cannot be edited or deleted

**Given** the racquet filter
**When** the user selects a racquet chip in the wrapping `FilterChip` row
**Then** the feed narrows to that racquet, and selecting it again clears the filter
**And** if nothing matches, it shows `No sessions with {racquet} yet.` with the chips still visible

**Given** loading and empty states
**When** the first page is loading
**Then** a progress row appears
**And** with no sessions at all it shows `No sessions yet. Log one from your bag.`
**And** the screen meets the accessibility floor: headings, 48dp chips with selected state announced, and 200% text with no clipping (UX-DR26)

## Epic 4: Manage racquets and the restring lifecycle

Users open Racquet Detail, edit name and notes, set a primary, delete a racquet, restring with Keep Same or Change Strings (routine, dead or broken), and review the restring history timeline.

### Story 4.1: Racquet Detail with restring history timeline

As a player,
I want to open a racquet and see its full health picture and string history,
So that I can understand how this frame's setups have lasted.

**Acceptance Criteria:**

**Given** a racquet card
**When** the user taps the card body
**Then** Racquet Detail opens for that racquet, and the card's semantics expose an `Open details` action whose label merges the name, string line and gauge label (UX-DR5)
**And** on web the route sets the page title `{racquet} — String Theory` (UX-DR27)

**Given** Racquet Detail
**When** it renders from `watchRacquet(id)`
**Then** a single column shows the gauge (at least 128px) with its Tier Label, the usage and companion lines, the current setup and stringing date, then the Restring History Timeline (UX-DR15)
**And** content width is constrained on wide screens instead of stretching to the window
**And** a detail-shaped skeleton shows until the racquet arrives
**And** health recomputes on every snapshot and on `AppResumed` (AD-7)

**Given** `pastStringJobs`
**When** the timeline renders
**Then** entries are newest first and deduplicated by job id (AD-6), each reading e.g. `Aug 1 – Oct 2 • Luxilon ALU Power • 19.2 court hours • 62 days`, with the material in place of a missing brand & model and the archived `hoursPlayed` as the hours (FR-17, UX-DR16)
**And** dead and broken jobs add a critical ⚠ icon and `Went dead` or `Broke`
**And** an empty history reads `No past string jobs yet.`
**And** each entry's semantics read in full words, e.g. `August 1 to October 2, Luxilon ALU Power, 19.2 court hours, 62 days`

**Given** the racquet is deleted on another device while Detail is open
**When** its stream reports it gone
**Then** the app returns to the bag and a snackbar reads `{racquet} was deleted on another device.`
**And** the screen meets the accessibility floor: headings, 200% text on the timeline with no clipping, focus order following reading order (UX-DR26)

### Story 4.2: Edit a racquet's name and notes

As a player,
I want to rename a racquet or add notes about it,
So that my bag reflects how I tell my frames apart.

**Acceptance Criteria:**

**Given** `RacquetRepository.updateRacquet`
**When** it is called with a new name and/or notes
**Then** it `update`s only `name` and/or `notes`, uses `FieldValue.delete()` when notes are cleared, and sets server `updatedAt`; it completes on local acceptance and late rejections reach the failures stream (AD-5, AD-14)

**Given** `firestore.rules`
**When** the update rule is added
**Then** the update shape is accepted only when `affectedKeys()` ⊆ {`name`, `notes`, `updatedAt`} with AD-3 bounds (name 1–100, notes 1–500)
**And** `rules_test/` has a positive test and negative tests for an out-of-bounds name and an attempt to change `isPrimary` in the same update

**Given** Racquet Detail
**When** the user taps the `Edit` app-bar action (with tooltip)
**Then** the Edit Racquet Form opens in the same container as the Add form, with only Racquet name and Notes, pre-filled and validated from `schema_bounds` (UX-DR14, FR-7)
**And** `Save` closes it and the new name appears on Detail and the bag card
**And** dismissing it with unsaved edits asks `Discard your changes?`
**And** focus returns to the Edit action when the form closes (UX-DR26)

### Story 4.3: Set a racquet as Primary

As a player,
I want to choose which racquet is my primary,
So that the quick logger pre-selects the frame I play with most.

**Acceptance Criteria:**

**Given** `RacquetRepository.setPrimary(Racquet target, List<Racquet> bag)`
**When** it is called
**Then** one `WriteBatch` sets the target's `isPrimary: true` and every racquet currently flagged to `false`, each write including server `updatedAt` (AD-5, AD-8)
**And** it completes on local acceptance, and a test covers the bag having zero, one and two flagged racquets beforehand

**Given** `firestore.rules`
**When** the setPrimary rule is added
**Then** an update is accepted only when `affectedKeys()` is exactly {`isPrimary`, `updatedAt`}, with a positive and a negative test in `rules_test/`

**Given** Racquet Detail of a racquet that is not primary
**When** the user taps `Set as Primary` (app-bar action with tooltip)
**Then** the racquet becomes primary, moves to the front of the bag and becomes the Quick-Log default (FR-8, UX-DR6)
**And** on Detail the action is replaced by the `Primary` badge next to the name (UX-DR7)

### Story 4.4: Delete a racquet

As a player retiring an old frame,
I want to delete its racquet from my bag,
So that my bag only shows the frames I still use, while my session history stays intact.

**Acceptance Criteria:**

**Given** `RacquetRepository.deleteRacquet`
**When** it is called
**Then** it deletes only the racquet document (its embedded string history goes with it) and leaves its sessions in place (AD-5, FR-7)
**And** `firestore.rules` allow delete to the owner only, with a positive and a negative test

**Given** Racquet Detail
**When** the user taps `Delete Racquet` (app-bar action with tooltip)
**Then** a Destructive Confirmation Dialog reads `Delete {racquet}? Its string history is removed. Sessions you logged stay in your history.` with `Cancel` (initial focus) and a destructive-fill `Delete Racquet` button; `Esc` and the scrim mean Cancel (UX-DR19)
**And** the trigger uses `text-primary` with a critical icon, never a destructive fill (UX-DR29)

**Given** the user confirms
**When** the deletion is accepted locally
**Then** the app returns to the bag with focus on the bag header and the card gone
**And** if the deleted racquet was primary, `resolvePrimary` picks the next default with no prompt
**And** its sessions still appear in Sessions, labeled `Deleted racquet`

### Story 4.5: Restrung Today — Keep Same & Reset

As a player who just picked up a freshly strung racquet,
I want to reset its health with one tap, keeping the same setup,
So that tracking restarts at 100% and the old string job is kept in history.

**Acceptance Criteria:**

**Given** `RacquetRepository.restring(Racquet racquet, StringJob newJob, EndReason reason)`
**When** it is called
**Then** one `update` sets `pastStringJobs: FieldValue.arrayUnion([archived])` where `archived` is the racquet's `currentStringJob` with `endedAt = Timestamp.now()` (client clock) and `endReason = reason`, sets `currentStringJob = newJob`, and sets server `updatedAt` (FR-16, AD-5)
**And** it completes on local acceptance, and late rejections reach the failures stream (AD-14)

**Given** `firestore.rules`
**When** the restring rule is added
**Then** an update is accepted only when `affectedKeys()` is exactly {`pastStringJobs`, `currentStringJob`, `updatedAt`}, the new list is the old list plus one, the new last element passes StringJob validation, and its `id` equals the old `currentStringJob.id`
**And** `rules_test/` has a positive test and negative tests for removing a past job, appending two, and a second restring of the same job (AD-6)

**Given** the Firestore emulator with the network disabled
**When** a racquet is restrung and the network is re-enabled
**Then** an emulator test proves the `arrayUnion` is queued, applied locally at once, and present on the server after reconnecting (AD-13)

**Given** a racquet card or Racquet Detail
**When** the user taps `[Restrung Today]` (secondary button, labeled `Restrung today: {racquet}` for screen readers)
**Then** the Restrung Today Sheet opens with a Sheet Close Button and the prompt `Restrung with the same setup ({brand} @ {tension} lbs)?`, falling back to `({brand})`, `({material} @ {tension} lbs)` or `({material})`, with the setup in the `data` style (UX-DR11, FR-15)
**And** the card's `[Restrung Today]` sits next to `Log` as a sibling of the card's tap target (UX-DR5)

**Given** the sheet
**When** the user taps `[Keep Same & Reset]`
**Then** a `restring` BLoC builds the new job copying `material`, `brand`, `tensionLbs` and `maxHours`, with `strungAt = clock.now()`, `hoursPlayed: 0` and a new `id`, and restrings with `manual_restring` (AD-15)
**And** the sheet closes, the gauge animates to 100% `Optimal`, any critical treatment lifts, and a snackbar reads `Fresh stringbed mounted! Restrung to 100% health.`
**And** `racquet_restrung` is sent through `AnalyticsSink` on local acceptance (FR-21)
**And** the archived job appears at the top of the timeline on Racquet Detail

### Story 4.6: Restrung Today — Change Strings

As a player who switched strings or whose strings broke,
I want to record the new setup and why the old one ended,
So that my history shows which setups died, broke or were routinely replaced.

**Acceptance Criteria:**

**Given** the Restrung Today Sheet
**When** the user taps `[Change Strings]`
**Then** it expands inline into String material, String brand & model, Stringing date, Tension and Max court hours, pre-filled from the current job, with the same validation as the Add Racquet Form (UX-DR11)
**And** below the fields a chip row offers `Routine restring` (selected by default), `Strings went dead` and `Strings broke`
**And** `Save & Reset` is pinned to the bottom and the sheet scrolls with the keyboard inset (UX-DR26)

**Given** the user changes the material
**When** Max court hours has not been edited in this sheet
**Then** it refills with the new material's `defaultMaxHours`; otherwise it keeps the user's value (AD-15)

**Given** valid input
**When** the user taps `Save & Reset`
**Then** the new job gets a new `id`, `hoursPlayed: 0` and the entered fields, a picked date is stored as that local date at 12:00 local time converted to UTC, and the old job is archived with `manual_restring`, `dead` or `broken` according to the chip (AD-15, FR-15, FR-16)
**And** the success path matches Story 4.5: sheet closes, gauge resets, success snackbar, `racquet_restrung`
**And** a dead or broken job shows `Went dead` or `Broke` with a critical ⚠ icon in the timeline
**And** if the same job was already restrung on another device, the persistent rejection snackbar says this restring wasn't saved and the card shows the other device's restring (AD-6)

## Epic 5: Account control, store compliance and public launch

Users can delete their account and all data from Android or Web, read a public privacy policy, and install the app from Google Play or use it on Firebase Hosting with App Check enforced. Includes web keyboard shortcuts, the screen-reader verification pass, Play release, and, as the last story after launch, replacing the deletion extension with a self-owned v2 function before 2027-03-31.

### Story 5.1: Server-side purge of a deleted user's data

As a player who deletes their account,
I want every racquet, string job and session removed from the server automatically,
So that nothing I stored survives my account.

**Acceptance Criteria:**

**Given** both Firebase projects are on the Blaze plan (required by extensions)
**When** the `firebase/delete-user-data` extension (0.1.30) is configured
**Then** its configuration lives in the repo as `firebase.json` `extensions` plus `extensions/*.env`, with Firestore paths `users/{UID}` and delete mode **Recursive** (AD-10, AD-12)
**And** `firebase deploy -P dev --only extensions` installs it in the dev project, and README.md documents the command

**Given** a test account with racquets, past string jobs and sessions in the dev project
**When** that Firebase Auth user is deleted
**Then** `/users/{uid}` and all its subcollections are gone, which is verified and recorded in the story's verification notes
**And** the client never deletes user data itself

**Given** the purge has run
**When** another signed-in device of that user still tries to write
**Then** the write is rejected because `/users/{uid}` no longer exists (AD-3, AD-10), with a rules test proving writes fail without the user document

### Story 5.2: Delete my account and all data

As a player or a Play reviewer,
I want to delete my account and all my data from Settings on Android or Web,
So that I'm in control of my data and the app meets Play's deletion requirement.

**Acceptance Criteria:**

**Given** Settings
**When** it renders
**Then** a `[Delete Account & All Data]` row uses `text-primary` text with a `health-critical` delete icon (UX-DR20, UX-DR29)

**Given** the user taps the row
**When** the Destructive Confirmation Dialog opens
**Then** it reads `This permanently deletes your account, all racquets, string history and sessions. Google may ask you to confirm your account. This can't be undone.` with `Cancel` (initial focus) and a destructive-fill `Delete Account` button; `Esc` and the scrim mean Cancel (UX-DR19, UX-DR22)

**Given** the user confirms
**When** a `settings` BLoC calls `AuthRepository.deleteAccount()`
**Then** it calls `currentUser.delete()` first; on `requires-recent-login` it re-authenticates through the same Android/Web Google flow and retries (FR-4, AD-9, AD-10)
**And** a re-authentication that returns a different account aborts with a typed `user-mismatch` failure
**And** repository streams complete on the uid change and late permission-denied errors are dropped, not reported

**Given** the outcome
**When** deletion succeeds
**Then** the user lands on Welcome, which shows and announces `Your account and all data were deleted.` for that visit, with focus on the headline (UX-DR21)
**And** when re-authentication is canceled, the dialog closes, the user stays signed in and a persistent snackbar reads `Account not deleted.`
**And** when a different account is chosen, the persistent snackbar reads `That's a different Google account. Account not deleted.`
**And** when deletion fails, an inline message under the row and a persistent snackbar with `Retry` read `Couldn't delete your account. Check your connection and try again.`, and the bag keeps working (UX-DR22)
**And** BLoC tests cover each outcome with a fake `AuthRepository`

### Story 5.3: Public web app and privacy policy on Firebase Hosting

As a visitor or Play reviewer,
I want the web app and a privacy policy reachable at a public URL,
So that I can read how my data is handled and delete my account without installing the Android app.

**Acceptance Criteria:**

**Given** `firebase.json`
**When** hosting is configured
**Then** it serves `string_theory_flutter/build/web` with an SPA rewrite to `/index.html`, while `/privacy.html` is served directly as a static file (FR-20)

**Given** `string_theory_flutter/web/privacy.html`
**When** it is written
**Then** it states what is collected (name and email from Google Sign-In; racquets, string jobs and sessions under the account; crash and performance diagnostics), that data is encrypted in transit, and the exact steps to delete an account in the app or the web app (NFR-8)
**And** it links to the web app, uses accessible static HTML (`lang="en"`, headings, readable contrast), and claims nothing the app doesn't do

**Given** Settings
**When** it renders
**Then** a Privacy Policy row opens `/privacy.html` (in the browser on Android) and an app version row shows the build version (UX-DR20)

**Given** the dev project
**When** `firebase deploy -P dev --only hosting` runs after a successful `flutter build web --dart-define=FLAVOR=dev`
**Then** the web app and `https://<dev-project>.web.app/privacy.html` both load, deep links resolve through the rewrite, and README.md documents the build and deploy steps

### Story 5.4: Web keyboard shortcuts and hover

As a player using String Theory in a desktop browser,
I want keyboard shortcuts for the two most common actions,
So that I can log sessions and add racquets without reaching for the mouse.

**Acceptance Criteria:**

**Given** the open decision on where the Keyboard shortcuts setting is stored
**When** this story starts
**Then** the user decides between browser storage (a new dependency needing approval) and a field on `/users/{uid}` (an AD-3 change updating mappers, rules and tests); until a decision is recorded, the switch resets to on with every visit (UX open question)

**Given** the bag on web, with no sheet or dialog open, no text field focused and the switch on
**When** the user presses `L` or `N`
**Then** `L` opens the Quick-Log Sheet and `N` opens the Add Racquet Form (UX-DR25)
**And** the shortcuts do nothing on other screens, while a sheet or dialog is open, while a text field has focus, or when the switch is off
**And** the FAB and `[+ Add Racquet]` tooltips show the keys
**And** `Esc` closes the topmost sheet or dialog and returns focus to its opener

**Given** Settings on web
**When** it renders
**Then** a Keyboard shortcuts switch tile appears (on by default) and is absent on Android (UX-DR20)

**Given** a pointer hovering a card or button on web
**When** hover applies
**Then** it uses the Level 2 treatment (`surface-elevated` with a 12% `primary` glow, 16px blur) and never replaces the focus ring (UX-DR25)

### Story 5.5: Web Analytics consent decision

As a visitor from the EU,
I want analytics on the web app to respect consent rules,
So that the public web URL can be announced without a privacy compliance gap.

**Acceptance Criteria:**

**Given** the open architecture question on web Analytics consent
**When** this story starts
**Then** the user decides between a consent banner, Consent Mode defaults, or documented reasons none is needed, and the decision is recorded in the architecture spine's Open Questions (as a `docs(architecture): ...` commit)

**Given** a decision requiring consent handling
**When** it is implemented
**Then** Analytics on web collects only as the decision allows, Android behaviour is unchanged, and any new UI surface follows DESIGN.md tokens and the accessibility floor (UX-DR26)
**And** `/privacy.html` describes the web analytics behaviour accurately

**Given** this story is not done
**When** the launch checklist is reviewed
**Then** the web URL is not announced publicly; the Android launch is not blocked

### Story 5.6: Screen-reader and accessibility verification pass

As a player who relies on assistive technology,
I want the core flows verified with real screen readers,
So that I can log, add, restring and delete my account without barriers.

**Acceptance Criteria:**

**Given** Flows 1–4 from EXPERIENCE.md (log a session, onboard and add a racquet, restring, delete the account)
**When** they are run with TalkBack on Android, NVDA + Chrome and VoiceOver + Safari on web
**Then** every step can be completed, every control has a meaningful label, and reading order, focus return and announcements match EXPERIENCE.md → Accessibility Floor (NFR-9, UX-DR26)
**And** results are recorded per flow and per screen reader in the story's verification notes

**Given** the app at 200% text scale and with reduce motion on
**When** the surfaces listed in UX-DR26 are inspected
**Then** no text clips, chip rows wrap, sheets keep their primary action pinned, and gauge, sheet, snackbar and shimmer motion is static

**Given** the DESIGN.md contrast table
**When** shipped color pairs are audited
**Then** every pair in use is listed with a passing ratio, and any new pair found is either added with its ratio or replaced (UX-DR29)
**And** every defect found is fixed in this story or filed as a story before launch

### Story 5.7: Production readiness and App Check enforcement

As the app owner,
I want the prod project protected against abuse and runaway costs before the public arrives,
So that a bot or a bug can't inflate the bill or reach user data.

**Acceptance Criteria:**

**Given** the prod project
**When** it is prepared for launch
**Then** billing budget alerts are configured, Firestore point-in-time recovery or scheduled backups are enabled, and both are recorded in README.md's operations section
**And** `firebase deploy -P prod --only hosting,firestore:rules,firestore:indexes,extensions` runs from `main` after green CI, with dev deployed first (Deploy convention)

**Given** App Check in monitor-only mode in prod
**When** the console shows verified requests at or above 98%
**Then** App Check enforcement is turned on for Firestore, and the date and percentage are recorded (AD-12, FR-19, SM-3)
**And** until that threshold is met, enforcement stays off and the launch checklist says so

**Given** a release build of the prod flavor
**When** its merged Android manifest is inspected
**Then** it declares no health, body-sensor, activity-recognition or fitness permissions (NFR-6)

### Story 5.8: Release on Google Play

As a player,
I want to install String Theory from Google Play,
So that I can track my strings on my Android phone or tablet.

**Acceptance Criteria:**

**Given** the upload keystore and signing passwords
**When** release signing is configured
**Then** they live only in untracked local files or GitHub secrets, never in the repo, and the prod SHA-1/SHA-256 of the upload key and Play App Signing key are registered in the prod project (AD-12, AGENTS.md secrets rule)

**Given** a signed AAB built locally with `flutter build appbundle --flavor prod --dart-define=FLAVOR=prod`
**When** it is uploaded to the Play internal track
**Then** Google sign-in, logging, restringing and account deletion work on a real device installed from that track

**Given** the Play Console listing
**When** it is completed
**Then** the privacy policy URL is `/privacy.html` on the prod hosting domain and the account deletion URL is the hosted web app (PRD OQ-3)
**And** the Data Safety form declares exactly: name and email for account management; racquets, string jobs and sessions as app activity; crash and performance diagnostics; encryption in transit; and a working deletion mechanism (NFR-8)

**Given** the internal-track build passes review
**When** it is promoted to production
**Then** README.md records the released version and how to install it, describing only what has shipped

### Story 5.9: Replace the deletion extension with a self-owned function (post-launch, due before 2027-03-31)

As a player who deletes their account after the Firebase Extensions shutdown,
I want my data still purged,
So that account deletion keeps working once the extension can no longer be maintained.

**Acceptance Criteria:**

**Given** the Firebase Extensions service shuts down on 2027-03-31
**When** this story is done, before that date
**Then** a 2nd-gen `onUserDeleted` Cloud Function calls `recursiveDelete` on `users/{uid}` in both projects, replacing the extension (AD-10)
**And** any new npm or Functions dependency is approved by the user first, and the extension's configuration is exported before uninstalling it

**Given** a test account with racquets, past string jobs and sessions
**When** the Auth user is deleted in dev, and then in prod with a dedicated test account
**Then** `/users/{uid}` and all subcollections are gone, matching the behaviour verified in Story 5.1
**And** an automated test of the function runs in CI against the emulator

**Given** the switchover
**When** it merges
**Then** `firebase.json` and `extensions/` no longer reference the extension, the architecture spine's AD-10 and Deferred list are updated in a `docs(architecture): ...` commit, and README.md documents the function deploy
