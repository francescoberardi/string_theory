---
reviewer: rubric-walker
target: ../ARCHITECTURE-SPINE.md
inputs: ARCHITECTURE-SPINE.md, .memlog.md, prd-string_theory-2026-10-02/prd.md, AGENTS.md, string_theory_flutter/lib, string_theory_decay_engine/lib, .github/workflows/tests.yml, android/app (manifest, build.gradle.kts), migration-checklist.md
date: 2026-10-23
---

# Rubric Review — Architecture Spine, String Theory v1 (Firebase)

## Verdict

The data, write-path and layering decisions are a solid base: AD-3, AD-5, AD-6, AD-8 and AD-10 close the hardest Firestore divergence points, and they are backed by verified constraints. The spine is **not ready for epics yet**, for three reasons. The Android side of the operational envelope (app identity, flavors, signing, release) is missing, and as written it can't be built. Offline write-completion semantics are undecided, and that is the most likely place for two stories to diverge in a Firestore app. The material-enum rule doesn't account for how the decay engine actually resolves materials today. All three can be fixed with targeted additions. None needs a redesign.

## Checklist walk

| # | Criterion | Result | Notes |
| --- | --- | --- | --- |
| 1 | Fixes the real divergence points for epics/stories, misses none | **Partial** | Strong on schema, write shapes, primary, auth split, deletion and bootstrap. Missing: offline commit semantics (F2), enum ownership in the engine (F3), session/cache teardown on sign-out and delete (F5), rules validation of array elements (F6), and who owns the remaining-hours formula (F3). |
| 2 | Every AD Rule is enforceable and prevents its divergence | **Partial** | AD-3 can't be enforced for `pastStringJobs[]` elements as worded (F6). AD-4 doesn't stop the engine's silent `other` fallback (F3). AD-10 names an outcome ("cancels every Firestore subscription") with no mechanism, which clashes with the BLoC isolation convention (F5). AD-12's `--dart-define=FLAVOR` can't select Android Firebase config (F1). AD-1 is enforceable, but only by review. An import-boundary check would make it mechanical (low). |
| 3 | Nothing under Deferred lets two units diverge | **Mostly pass** | One problem: removing `health` sits under Deferred, but NFR-6 is a v1 Must and the manifest declares Health Connect permissions today (F4). "Session paging and indexes" is fine because only one story owns it. "Billing / backups" is fine but needs a launch-checklist owner. |
| 4 | Ratifies the brownfield codebase rather than contradicting it | **Partial** | Correctly calls out the Serverpod-typed `BagBloc` and removes `offline_session_queue.dart`. Doesn't address: the engine's `Enum`-polymorphic API (`StringCategoryDefaults.*(Enum)`, `DomainStringMaterialCategory.fromEnum` → `other`), `calculateHealth(now: DateTime.now())` defaulting, the UI's own remaining-hours formula in `racquet_detail_screen.dart:218`, `lib/domain/decay_engine.dart` and `racquet_preset.dart` importing `string_theory_client`, the flat `lib/bloc/bag_*.dart` files versus `lib/bloc/<feature>/`, and `lib/services/auth_service.dart` moving to `lib/data/`. |
| 5 | Covers every PRD FR/NFR | **Partial** | FR-1..FR-22 are all mapped. FR-3 "clears local memory caches" is undecided (F5). FR-9's secondary metrics have no owner (F3). Of the NFRs: NFR-6 has no mapping (F4), NFR-2 has no binding (acceptable, since it comes from the platform), and NFR-1 is bound only nominally through AD-7. SM-2 can't be measured on web because AD-11 skips Crashlytics there (F7). |
| 6 | Every owned dimension is decided, deferred, or open, especially the operational envelope | **Fail on Android ops** | Web hosting, rules and index deploys are decided. Environments are decided but infeasible on Android (F1). Not decided, deferred or raised as open: the Android applicationId, flavors, signing, Play App Signing SHA registration, the release track flow, extension configuration as code, CI job composition, App Check enforcement rollout, and web Analytics consent (GDPR). There is no Open Questions section. |

## Findings

### F1 — HIGH — Android environment and release mechanics are missing, and the current form can't be built

**Evidence.** `android/app/build.gradle.kts` uses `applicationId = "com.example.string_theory_flutter"`, and Play Console rejects `com.example.*` packages. AD-12 picks the Firebase project with `--dart-define=FLAVOR`. On Android, though, `google-services.json` is resolved by the Gradle plugin per source set, not by a Dart define. Crashlytics and the `google_sign_in` 7.x `serverClientId` (web client ID) differ per project. Google also requires each Android OAuth client's (package name, SHA-1) pair to be unique across GCP projects, so `dev` and `prod` can't both register the same package with the same debug key. Nothing in the spine says who builds or signs the AAB, where the upload key lives in practice, which SHA-1/SHA-256 fingerprints (debug, upload, Play App Signing) get registered in which project, or how a release moves through Play tracks. The migration checklist (§2) lists the SHA step, but the spine doesn't carry it forward. The `delete-user-data` extension is "latest official" and configured by hand in two consoles, so dev and prod can drift (for example, Recursive mode set in one project only).

**Divergence risk.** The auth story, the App Check story and the release story each invent their own flavor mechanism. Google Sign-In fails with `DEVELOPER_ERROR` in one environment.

**Fix.** Add an AD, "Android app identity, flavors and release":
- Final `applicationId` (for example `com.<owner>.stringtheory`), with a `dev` flavor using `applicationIdSuffix ".dev"`.
- Gradle `productFlavors { dev, prod }` with `src/<flavor>/google-services.json`. Build with `flutter build appbundle --flavor prod --dart-define=FLAVOR=prod`. The Dart define selects `firebase_options_<flavor>.dart` and the `serverClientId`.
- A table of SHA fingerprints per project: dev debug key in dev, and upload key plus Play App Signing key in prod.
- Release = manual signed AAB from `main` to the Play internal track, then production. The upload keystore stays local or in GH secrets.
- The extension is pinned and kept as code (`firebase.json` `extensions` plus `extensions/delete-user-data.env`, deployed with `--only extensions`).

Add these to the Deploy convention row.

### F2 — HIGH — Offline write completion and rejection semantics are undecided

**Evidence.** The Errors convention says repositories catch `FirebaseException` and throw typed failures, which implies BLoCs await the write. Offline, `WriteBatch.commit()` and `update()` futures don't complete until the server acknowledges, so a BLoC that awaits `logSession` leaves the quick logger spinning on court. That breaks UJ-1 and NFR-4 in practice. Writes that the server later rejects (session batch on a racquet deleted from another device, `hoursPlayed` over 1000, `pastStringJobs` over 100) are dropped silently after sync. AD-5 says it prevents "offline writes that can never commit" but only removes transactions. AD-6 accepts the restring race but says nothing about the delete-racquet race. In that case the batch `update` fails NOT_FOUND and **the session is lost too**, because the batch is atomic.

**Divergence risk.** One story awaits commits and shows a spinner. Another fires and forgets with no error path. Crash and analytics reporting of rejected writes becomes inconsistent.

**Fix.** Add a convention or AD:
- Mutating repository methods return once the write is queued locally. They never await server acknowledgement on the UI path.
- The commit future is observed in the background. Failures map to a typed failure on a repository-level `Stream<WriteFailure>` and go to Crashlytics.
- The UI relies on latency-compensated snapshots (optionally `hasPendingWrites` for a "pending sync" badge, which exists today as `pending_sync_banner.dart`).
- State explicitly that a session logged offline against a racquet deleted elsewhere is lost, and that this is accepted, mirroring AD-6. Alternatively, split the session `set` from the increment, which needs a decision.

### F3 — HIGH — Material enum ownership contradicts the existing engine, and FR-9 secondary metrics have no owner

**Evidence.** `string_theory_decay_engine/lib/src/string_category_defaults.dart` defines `DomainStringMaterialCategory` with 7 values: `coPoly, multifilament, syntheticGut, naturalGut, kevlar, hybrid, other`. Every API takes a polymorphic `Enum` and resolves it **by name** through `fromEnum`, which **falls back to `other`** (180 days, 20h).

AD-2 puts a separate `StringMaterial` in `lib/domain/`, and AD-4 says shelf life comes "from `string_theory_decay_engine` only". Together that gives two enums joined by name matching. AD-4 removes `kevlar, hybrid, coPoly` but never mentions `other`, and doesn't ban name-based fallback. If the engine story lags the app story, `monofilament` silently resolves to `other` and gets 180 days instead of 75. That is exactly the silent default AD-4 forbids, just one layer down.

`calculateHealth(now:)` defaults to `DateTime.now()`, which bypasses AD-7's `package:clock` rule unless every caller passes `now`. Separately, FR-9's "Remaining Court Hours" isn't in the engine. `racquet_detail_screen.dart:218` computes `maxRatedHours - totalCourtHours`, while the PRD formula is `(Health-40)/70 × MaxRatedHours`. Tension loss returns a formatted `"kg / lbs"` string with a hard-coded 52 lb fallback, although FR-5 makes tension optional.

**Fix.** Rewrite the AD-4 and AD-2 rule:
- The engine owns the single `StringMaterial` enum (exactly 4 values, no `other`), and `lib/domain` re-exports it.
- Delete `fromEnum(Enum)` and the `Enum`-typed `StringCategoryDefaults` / `DecayEngine` parameters.
- `calculateHealth` takes the typed enum and a **required** `now`.
- The engine exposes `remainingHours(...)` (the PRD formula) and `tensionLossLbs(...)` as numbers, returning null or hidden when tension is absent. Formatting stays in the UI.
- Optionally rename the engine parameters to `strungAt` / `maxHours`, which settles the open memlog question.

### F4 — MEDIUM — NFR-6 and the non-goal teardown are unmapped, and the health removal is filed as Deferred

**Evidence.** `AndroidManifest.xml` declares `health.READ_EXERCISE/DISTANCE/TOTAL_CALORIES_BURNED/STEPS` plus a Health Connect rationale activity. `lib/services/health/*`, `simulate_workout_badge.dart` and `racquet_preset.dart` (sample bag) are still present. `.github/workflows/tests.yml` still runs Serverpod backend tests, the UUID migration check, the Patrol E2E job and a health-service Chrome test. The spine lists removing `health` under **Deferred**, and the capability map has no row for NFR-6 or for the PRD §5 non-goal purges (demo actions, notifications, health).

**Divergence risk.** Launch-blocking removals end up with no epic owner. Or several stories each delete part of it, while CI keeps failing on Serverpod jobs.

**Fix.** Move the teardown from Deferred into the capability map as a v1 Must row: "NFR-6 + PRD §5 teardown: manifest, `services/health`, demo actions, `offline_session_queue`, `string_theory_client` imports". Note that it needs dependency approval under AGENTS.md. Add a CI convention: `tests.yml` = decay-engine `dart test` + `flutter test` + `rules_test` emulator job + `flutter build web`, with the Serverpod, UUID-migration and Patrol jobs removed. Say explicitly that the rules tests gate PRs.

### F5 — MEDIUM — Teardown of subscriptions and cache on sign-out and delete has no mechanism

**Evidence.** AD-10 says the client "cancels every Firestore subscription" before `delete()`. The BLoC-state convention forbids one BLoC touching another, so the auth/settings BLoC has no sanctioned way to stop the bag, session and restring subscriptions. FR-3 requires sign-out to "clear local memory caches", and the spine doesn't decide whether that means `FirebaseFirestore.terminate()` + `clearPersistence()`. That matters on shared web browsers, where AD-11 turns on persistent multi-tab cache.

**Fix.** Add a rule:
- All data BLoCs are created beneath an auth-scoped subtree keyed by uid, owned by the auth gate. The gate disposes that subtree, which closes the BLoCs and their subscriptions, before it calls `signOut()` or `delete()`.
- Sign-out and post-delete run `terminate()` + `clearPersistence()` on web, or the spine explicitly accepts keeping the cache. Either way the choice is recorded.

### F6 — MEDIUM — AD-3 can't be enforced for `pastStringJobs[]` elements, and session delete is half-specified

**Evidence.** Firestore rules have no loops, so "rules implement exactly this table" can't be checked per element of a 100-item list. AD-3 and the table say sessions are "create/delete only", yet AD-5 has no `deleteSession`, and the memlog says sessions are deleted only by the extension, which bypasses rules anyway. A future "delete session" story would also need to decrement `hoursPlayed`, and no shape is defined for that.

**Fix.** Make the restring rule append-only: `new.size() == old.size() + 1 && new.hasAll(old) && isValidStringJob(new[new.size()-1])`. Otherwise the list may only stay unchanged. Make sessions **create-only** in rules for v1, with no client delete.

### F7 — LOW — Upstream documents need updates (decisions are not in question)

The spine intentionally diverges in several places, and the source documents need to catch up. Add a "Required upstream updates" list to the spine so a `docs(...)` story owns them.

- **PRD**
  - Glossary, FR-5, FR-9 and UJ-2 still say `coPoly` / "Co-Polyester". They need `monofilament` and the 4-value set.
  - FR-16 sets `endedAt: FieldValue.serverTimestamp()`. It needs the client timestamp, because server timestamps are illegal in arrays.
  - FR-13 needs the session field `stringJobId`.
  - FR-7 doesn't say that sessions survive racquet deletion.
  - FR-21 and SM-2 assume Crashlytics on web, which isn't supported. Either restate SM-2 as Android-only, or decide on a web error sink, for example an Analytics `app_exception` event.
  - FR-5's separate "Brand & Model" field becomes the single `brand` string.
- **AGENTS.md**
  - `stringHistory` → `pastStringJobs`.
  - The secrets rule needs to say that `firebase_options*.dart` and `google-services.json` are public and committed (AD-12).
  - The workspace members change once Serverpod is removed.

Smaller gaps worth one line each:
- (a) AD-9's `set(merge: true)` "after first sign-in" needs a first-sign-in test (`additionalUserInfo.isNewUser`), or the write must leave `createdAt` out on later sign-ins. Otherwise `createdAt` is rewritten on every sign-in.
- (b) Web Firebase Analytics sets cookies, and EU consent isn't addressed. Add it as an Open Question.
- (c) Prod App Check is "enforced" from day one, while PRD SM-3 implies monitor-then-enforce. State the rollout order.
- (d) The `delete-user-data` extension needs the Blaze plan. That makes the deferred budget alerts a hard prerequisite for launch, not just a nice-to-have.
- (e) The spine has no Open Questions section. Add one, even if it's short.

## What is strong (keep as is)

- AD-3 as a single wire contract shared by mappers and rules, including the null-vs-absent rule.
- AD-5's method-to-write-shape table with no transactions, and AD-6 making the restring race explicit through `stringJobId`.
- AD-8's conflict-tolerant primary resolution, which keeps SM-C2 at one query.
- AD-10's recursive-mode invariant, backed by verified extension behaviour.
- AD-11's bootstrap order with Remote Config fetch kept off the first-frame path.
- AD-13's per-layer test strategy, which is consistent with AGENTS.md's TDD and no-Patrol policy.
