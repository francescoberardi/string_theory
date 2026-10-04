---
title: 'Story 3.3: HealthSyncService Strategy Pattern & Judge Simulation Generator'
type: 'feature'
created: '2026-10-04'
status: 'done'
baseline_commit: '2b8da211a9428b4ef1bbdbb01198758f8e098be6'
route: 'dispatch'
review_loop_iteration: 1
context:
  - '_bmad-output/implementation-artifacts/epic-3-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The app has no way to ingest workouts: there is no health-data abstraction, so mobile players cannot pull tennis workouts from Apple Health / Health Connect, and judges on web/desktop have no hardware-free way to produce one.

**Approach:** Add an abstract `HealthSyncService` exposing a stream of detected `DetectedWorkout`s plus a `syncWorkouts()` pull. A platform resolver binds `NativeHealthSyncService` on iOS/Android and `SimulatedHealthSyncService` on Web/Desktop. A floating `[🧪 Simulate Workout]` badge on the bag screen asks the bound service to emit a 90-minute tennis workout immediately; the detection is surfaced in-app so Story 3.4's assignment sheet can consume it.

## Boundaries & Constraints

**Always:**
- UI and blocs depend only on `HealthSyncService`; no widget or bloc imports a health plugin.
- `DetectedWorkout` carries only what `SessionLog` needs: `externalWorkoutId` (unique per workout; simulated ids prefixed `sim-`), `startTime` (UTC), `durationMinutes`, `source` (`'healthkit'`, `'health_connect'`, or `'simulated'`). Raw health records never leave the device (NFR-7).
- Simulated workout: 90 minutes, `startTime = now − 90 min`, fresh id on every tap.
- Native sync queries completed tennis workouts in a window starting a fixed 24h overlap before the last sync timestamp (first sync of a launch looks back 7 days; both kept in memory for this story), skips any `externalWorkoutId` already seen, and maps each new one to a `DetectedWorkout`; permission denial or plugin errors yield an empty result plus a `debugPrint`, never a crash.
- The Flutter web build compiles and runs with no plugin `MissingPluginException` (the native plugin is never invoked off-mobile).

**Decisions (human, 2026-10-04):**
- Native: real `health` plugin (13.3.2) — add the dependency, iOS HealthKit capability (`Runner.entitlements` + `NSHealthShareUsageDescription`), Android Health Connect `READ_EXERCISE` permission + `minSdk 26`.
- Android (2026-10-04, review loop 1): also declare and request `READ_DISTANCE`, `READ_TOTAL_CALORIES_BURNED`, `READ_STEPS` — the plugin reads those records for every workout and silently returns nothing without them. Their values are discarded on-device; only the four `DetectedWorkout` fields are kept.
- Sync window (2026-10-04, review loop 1): overlapping window as above, so matches in progress during a sync or saved late are still detected.
- Detection UX: one in-app SnackBar per batch of detections — a single workout reads "1h 30m Tennis Match Detected", several read "N Tennis Matches Detected" (review loop 1). Workouts stay in the service's in-memory `pendingWorkouts` for Story 3.4. No gauge change in this story.
- Badge: shown only when the bound service `supportsSimulation` (web/desktop); never on mobile.

**Never:**
- No server, model, or migration changes; no call to `SessionEndpoint.logSession` from this story's code paths.
- No assignment bottom sheet, quick logger, or offline queue (Stories 3.4, 3.5).
- No background/periodic HealthKit observers or push notifications.
- Never edit generated code or the `string_theory_client` package.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Platform binding | Web / macOS / Windows / Linux | Resolver returns `SimulatedHealthSyncService` | N/A |
| Platform binding | iOS / Android | Resolver returns `NativeHealthSyncService` | N/A |
| Simulate tap | Badge tapped on bag screen | Service stream emits one `DetectedWorkout(durationMinutes: 90, source: 'simulated')`; detection surfaced in-app | N/A |
| Repeated simulate | Badge tapped twice | Two workouts with distinct `externalWorkoutId`s | N/A |
| Native mapping | Plugin returns 1 tennis + 1 running workout | One `DetectedWorkout` (tennis only) with platform source and plugin UUID as id | N/A |
| Straddling workout | Sync at 17:30 during a 17:00–18:30 match; second sync at 19:00 | Second sync detects it once | N/A |
| Repeat detection | Same workout returned by two overlapping syncs | Emitted once | N/A |
| Batch surfacing | One sync detects 3 workouts | One SnackBar "3 Tennis Matches Detected" | N/A |
| Native permission denied | User denies authorization | `syncWorkouts()` returns empty list | `debugPrint`, no throw |
| Native plugin throws | Plugin call raises | `syncWorkouts()` returns empty list | `debugPrint`, no throw |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/services/health/health_sync_service.dart` -- NEW. Abstract `HealthSyncService { Stream<DetectedWorkout> get workouts; Future<List<DetectedWorkout>> syncWorkouts(); bool get supportsSimulation; List<DetectedWorkout> get pendingWorkouts; Future<void> simulateWorkout(); void dispose(); }` + `DetectedWorkout` (Equatable).
- `string_theory_flutter/lib/services/health/simulated_health_sync_service.dart` -- NEW. Broadcast `StreamController`; injectable `DateTime Function() now` and id generator for tests. Default id generator must be web-safe: no shifts of 32+ bits and no `Random.nextInt` bound above `0x7fffffff` (dart2js folds `1 << 32` to 0 → `RangeError`).
- `string_theory_flutter/lib/services/health/native_health_sync_service.dart` -- NEW. Wraps the plugin behind a small injectable gateway so mapping/error handling is unit-testable without the platform channel. Requested types: `WORKOUT` everywhere, plus `DISTANCE_DELTA`, `TOTAL_CALORIES_BURNED`, `STEPS` (READ) on Android only — fetch still queries `WORKOUT` only. Plugin query semantics: iOS uses `.strictStartDate` (`health-13.3.2/ios/health/Sources/health/HealthDataReader.swift:136`), Android `TimeRangeFilter.between`; test fakes must filter by `dateFrom >= start` so window bugs are visible.
- `string_theory_flutter/lib/services/health/health_sync_resolver.dart` -- NEW. `createHealthSyncService({bool? isWeb, TargetPlatform? platform})` using `kIsWeb` / `defaultTargetPlatform` (no `dart:io`).
- `string_theory_flutter/lib/main.dart` -- Provide the service via `RepositoryProvider<HealthSyncService>` alongside the existing `BlocProvider<BagBloc>`; `MyApp` accepts an optional override like `bagBloc`.
- `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Badge (key `virtual_bag_simulate_workout_badge`) placed so it does not collide with `_buildFab`'s "Add Racquet" FAB (e.g. stacked above it); listens to `workouts`, buffers detections arriving in the same frame, and shows one SnackBar per buffer. Keep a `formatWorkoutDuration` helper (`45m`, `1h`, `1h 30m`, `2h`). Reuse `CourtMidnightTheme` colors and `GoogleFonts` styling already used here.
- `string_theory_flutter/test/virtual_bag_screen_test.dart`, `test/widget_test.dart` -- Existing tests pump `VirtualBagScreen`/`MyApp`; they must supply a fake `HealthSyncService`.
- `string_theory_flutter/pubspec.yaml`, `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements` (NEW, referenced via `CODE_SIGN_ENTITLEMENTS` in `ios/Runner.xcodeproj/project.pbxproj`), `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts` (`minSdk = 26`, currently `flutter.minSdkVersion`) -- native config per the `health` package README.
- `string_theory_flutter/lib/bloc/bag_bloc.dart` -- Do not modify.
- `string_theory_flutter/.gitignore` -- Do not modify (Flutter tooling may try to drop a line; revert it).

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_flutter/test/services/health/*_test.dart` -- write failing tests first (TDD red) for every I/O matrix row: resolver binding, simulated emission/unique ids (including the default generator), native tennis-only mapping, straddling workout across two syncs, overlap dedupe, Android extra permission types requested, permission-denied and throw paths.
- [x] `string_theory_flutter/pubspec.yaml` + iOS/Android native config -- add `health` and platform permissions.
- [x] `string_theory_flutter/lib/services/health/` -- implement interface, simulated, native, resolver.
- [x] `string_theory_flutter/test/virtual_bag_screen_test.dart` -- failing widget test: badge visible only with a simulation-capable service, tap surfaces the detection; a 3-workout batch yields one "3 Tennis Matches Detected" SnackBar; `formatWorkoutDuration` table; existing tests updated with a fake service. `test/widget_test.dart` -- pump `MyApp()` without an injected service under `debugDefaultTargetPlatformOverride = TargetPlatform.macOS` and assert the badge shows (covers the default provider wiring).
- [x] `string_theory_flutter/lib/main.dart`, `lib/screens/virtual_bag_screen.dart` -- wire provider, badge, and detection surface.

**Acceptance Criteria:**
- Given the app built for web (`flutter build web`), when it launches and the badge is tapped, then a 90-minute workout detection appears and no plugin exception is logged.
- Given any detected workout, when inspected, then it maps 1:1 onto a `SessionLog` (`startTime`, `durationMinutes`, `source`, `externalWorkoutId`) without extra health data.

## Implementation Notes

## Spec Change Log

- **Review loop 1 (2026-10-04).** Triggers: triage #2 (Android workout read silently empty), #3 (strict watermark loses straddling/late workouts), #4 (cold-start SnackBar flood); patch findings #1 (web-unsafe sim id) and #5 (default `MyApp` provider untested). Amended: frozen Always/Decisions/Matrix per the human's answers (extra Android read permissions, 24h overlap window with seen-id dedupe, one SnackBar per batch); Code Map and tasks for the web-safe id, range-filtering fakes, and the default-provider test. Known-bad state avoided: web badge throwing `RangeError`; Android sync always empty; workouts lost at the sync boundary; tests whose fake ignores the query window. KEEP: the gateway seam (`HealthPluginGateway` + lazily created `PluginHealthGateway`); resolver signature and `kIsWeb`/`defaultTargetPlatform` use; `MyApp`/`VirtualBagScreen` optional `healthSyncService` override with `RepositoryProvider` (lazy create + dispose); badge stacked above the Add FAB with key `virtual_bag_simulate_workout_badge`; `FakeHealthSyncService` test helper; native config set (entitlements via `CODE_SIGN_ENTITLEMENTS` in all three Runner configs, `Info.plist` string, Health Connect rationale intent-filter, `ViewPermissionUsageActivity` alias, `<queries>` package entry, `minSdk = 26`, `MainActivity` as `FlutterFragmentActivity` per the plugin README). Previous code saved as a patch outside the repo for reference.

## Review Triage Log

| # | Finding (source) | Verdict | Evidence | Route |
|---|---|---|---|---|
| 1 | `_defaultId` uses `nextInt(1 << 32)`; on dart2js the shift yields 0 → `RangeError` on every web badge tap (blind, edge) | high | Web int semantics truncate shifts to 32 bits; VM-only tests cannot see it; breaks AC-1 | patch |
| 2 | Android `WORKOUT` read silently returns empty without Distance/Calories/Steps read permissions (edge) | high | `health-13.3.2` `HealthDataReader.kt:581-640` reads those records per session; `SecurityException` is caught at `:128` → `result.success(emptyList)`; frozen decision grants only `READ_EXERCISE` | intent_gap |
| 3 | Sync watermark `_lastSync = end` permanently drops workouts in progress or saved late (blind, verification-gap, edge) | medium | iOS predicate `.strictStartDate` (`HealthDataReader.swift:136-137`); Watch saves HKWorkout at end with an earlier start; fake gateway ignores range so tests cannot see it; frozen "since the last sync timestamp" forbids an overlap window | intent_gap |
| 4 | Every cold start replays 7-day lookback, one SnackBar per workout (blind, verification-gap, edge) | medium | In-memory state is a human decision, but per-workout SnackBar queueing + 7-day lookback are unsettled by the spec | intent_gap |
| 5 | `MyApp()` default `RepositoryProvider` path untested (verification-gap) | medium | Pre-verified: both `MyApp` tests inject `.value`; production wiring unguarded | patch |
| 6 | `formatWorkoutDuration` branches unpinned (verification-gap) | low | Pre-verified; only `1h 30m` exercised; filed disposition defer | defer |
| 7 | Badge `onTap` discards `simulateWorkout()` Future (blind) | low | Only throws via #1 or on native, where badge is hidden; rejected | reject |
| 8 | No test asserts the `debugPrint` on failure paths (blind) | low | Real gap, unlikely to regress silently in practice; rejected | reject |
| 9 | Mapper branches (`minutes <= 0`, non-WORKOUT type, in-batch dup uuid) untested (blind) | low | Real but cosmetic coverage; rejected | reject |
| 10 | Screen rebind/dispose/loading-state badge untested (blind) | low | Coverage only; rejected | reject |
| 11 | Badge under 48dp, emoji read literally by screen readers (blind) | low | Dev/judge-only control on web/desktop; rejected | reject |
| 12 | `requestAuthorization` on every sync (blind, edge) | low | Sync fires once per service bind (`identical` guard); iOS does not re-prompt; rejected | reject |
| 13 | Concurrent `syncWorkouts()` race (blind, edge) | false | `_bindHealthSyncService` returns early on an identical service, so one sync per bind | reject |
| 14 | `context.read` misses provider replacement (edge) | false | Provider is created once per `MyApp`; never replaced at runtime | reject |
| 15 | `inMinutes` truncation under-reports (edge) | low | Sub-minute loss; rejected | reject |
| 16 | `health` plugin compiled into web/desktop bundles (blind) | low | `flutter build web` passes; never invoked off-mobile per spec; conditional import adds complexity; rejected | reject |
| 17 | Spec vs sprint-status status mismatch (blind) | false | Workflow sets sprint status at step boundaries; transient by design | reject |
| 18 | Spec notes empty while tasks ticked (blind) | false | Finding's fix edits this build's spec; rejected | reject |
| 19 | Sync runs once per service bind; no resume trigger, so a match finished while the app is backgrounded is not detected until a cold start; the 24h overlap never runs in-app (blind, edge — review loop 2) | medium | `_bindHealthSyncService` `identical` guard + no `WidgetsBindingObserver` in `lib/`; spec never says when sync fires; several readings (resume, timer, HealthKit observer/background delivery, pull-to-refresh); a resume trigger also makes concurrent syncs (#13) reachable. Human (2026-10-04): keep launch-only sync for this story | defer |
| 20 | `NSHealthUpdateUsageDescription` missing from `Info.plist` (blind) | medium | `health-13.3.2/README.md:32-35` lists both Share and Update keys; Code Map says native config per the README; App Store upload can be rejected for a missing purpose string | patch |
| 21 | Repeated badge taps queue one 4s SnackBar per tap (edge) | low | `_flushDetections` calls `showSnackBar` without hiding the current one; judges tapping several times is plausible; fix is one `hideCurrentSnackBar()` call | patch |
| 22 | `main.dart` comment credits lazy `RepositoryProvider` with keeping the plugin untouched off-mobile (blind) | low | `VirtualBagScreen.didChangeDependencies` reads the provider on first build, so creation is not deferred; the resolver + lazy `PluginHealthGateway` do the protecting | patch |
| 23 | Native `startTime.toUtc()` unpinned: all native fixtures are already UTC (verification-gap) | low | Pre-verified; plugin builds local `DateTime`s (`health_data_point.dart:126-127`); needs a local-time fixture test | patch |
| 24 | Web-only invariants (dart2js-safe id, web compile) not in CI (verification-gap) | medium | Pre-verified; `.github/workflows/tests.yml` `flutter-tests` runs VM `flutter test` only; add Chrome run of the simulated test + `flutter build web` | patch |
| 25 | Android manifest permissions vs `authorizationTypesFor` / `FlutterFragmentActivity` unchecked (verification-gap) | medium | Pre-verified; needs Patrol/device testing, not set up in repo; filed disposition defer | defer |
| 26 | No Health Connect availability check; denied/unavailable access is silent to the user (blind) | medium | Frozen intent chose empty result + `debugPrint`; user-facing status is outside this story's intent | defer |
| 27 | Cold start re-detects the last 7 days, including workouts already in `SessionLog` (blind, edge) | medium | Frozen decision keeps seen ids / last sync in memory "for this story"; Story 3.4 must reconcile against logged `externalWorkoutId`s | defer |
| 28 | Health Connect rationale intent / permission-usage alias open the bag screen, not a privacy rationale (blind) | low | Matters for Play review only; needs a new screen; rejected | reject |
| 29 | Same match recorded by two apps yields two detections (blind) | low | Different UUIDs per source; niche setup; user chooses in Story 3.4; overlap-dedupe heuristics add complexity; rejected | reject |
| 30 | No upper bound on workout duration (blind) | low | Forgotten-running watch workouts are rare; Story 3.4 assignment is user-confirmed; rejected | reject |
| 31 | `pendingWorkouts` has no clear/dismiss or change stream (blind) | low | Story 3.4 will add what it needs; speculative API now; rejected | reject |
| 32 | SnackBar batching relies on frame timing (blind) | false | Spec Code Map prescribes same-frame buffering; one sync's broadcast events are delivered as microtasks before the next frame | reject |
| 33 | Simulate badge visible in production web/desktop builds (blind) | false | Frozen decision: badge shown whenever `supportsSimulation` (web/desktop) | reject |
| 34 | `source` is a plain string, not an enum shared with the server (blind) | low | Frozen intent defines string values; no divergence today; rejected | reject |
| 35 | Plugin uuid may be null → empty `externalWorkoutId` (edge) | false | iOS sets `"uuid": sample.uuid` (`HealthDataReader.swift:185`…), Android `session.metadata.id` (`HealthDataReader.kt:364`); never null | reject |
| 36 | Concurrent `syncWorkouts()` race (edge) | low | carried #13 — still one sync per bind today; becomes reachable if #19 adds a resume trigger | reject |
| 37 | `requestAuthorization` on every sync (edge) | low | carried #12 | reject |
| 38 | No `RepositoryProvider` ancestor → `ProviderNotFoundException` (edge) | false | Only production mount is `main.dart:163`, under `MyApp`'s provider; loud failure elsewhere is correct | reject |
| 39 | `formatWorkoutDuration` mis-formats zero/negative minutes (edge) | false | Mapper drops `minutes <= 0`; simulated is always 90; unreachable | reject |

## Design Notes

Keep the resolver free of `dart:io` (`Platform.isIOS` breaks web); `defaultTargetPlatform` is web-safe and overridable via `debugDefaultTargetPlatformOverride` in tests. Construct `NativeHealthSyncService` lazily so the plugin is never touched on web.

## Verification

**Commands:**
- `dart analyze` in the repo root -- expected: No issues found
- `dart format --set-exit-if-changed .` in `string_theory_flutter` -- expected: no changes
- `flutter test` in `string_theory_flutter` -- expected: all tests pass
- `flutter build web` in `string_theory_flutter` -- expected: build succeeds

**Manual checks:**
- With `serverpod start` running, open the web app, tap `[🧪 Simulate Workout]`, confirm the detection appears.
