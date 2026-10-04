---
title: 'Story 3.3: HealthSyncService Strategy Pattern & Judge Simulation Generator'
type: 'feature'
created: '2026-10-04'
status: 'ready-for-dev'
route: 'dispatch'
review_loop_iteration: 0
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
- Native sync queries only completed tennis workouts since the last sync timestamp (kept in memory for this story) and maps each to a `DetectedWorkout`; permission denial or plugin errors yield an empty result plus a `debugPrint`, never a crash.
- The Flutter web build compiles and runs with no plugin `MissingPluginException` (the native plugin is never invoked off-mobile).

**Decisions (human, 2026-10-04):**
- Native: real `health` plugin (13.3.2) — add the dependency, iOS HealthKit capability (`Runner.entitlements` + `NSHealthShareUsageDescription`), Android Health Connect `READ_EXERCISE` permission + `minSdk 26`.
- Detection UX: in-app SnackBar "1h 30m Tennis Match Detected"; the workout stays in the service's in-memory `pendingWorkouts` for Story 3.4. No gauge change in this story.
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
| Native permission denied | User denies authorization | `syncWorkouts()` returns empty list | `debugPrint`, no throw |
| Native plugin throws | Plugin call raises | `syncWorkouts()` returns empty list | `debugPrint`, no throw |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/services/health/health_sync_service.dart` -- NEW. Abstract `HealthSyncService { Stream<DetectedWorkout> get workouts; Future<List<DetectedWorkout>> syncWorkouts(); bool get supportsSimulation; List<DetectedWorkout> get pendingWorkouts; Future<void> simulateWorkout(); void dispose(); }` + `DetectedWorkout` (Equatable).
- `string_theory_flutter/lib/services/health/simulated_health_sync_service.dart` -- NEW. Broadcast `StreamController`; injectable `DateTime Function() now` and id generator for tests.
- `string_theory_flutter/lib/services/health/native_health_sync_service.dart` -- NEW. Wraps the plugin behind a small injectable gateway so mapping/error handling is unit-testable without the platform channel.
- `string_theory_flutter/lib/services/health/health_sync_resolver.dart` -- NEW. `createHealthSyncService({bool? isWeb, TargetPlatform? platform})` using `kIsWeb` / `defaultTargetPlatform` (no `dart:io`).
- `string_theory_flutter/lib/main.dart` -- Provide the service via `RepositoryProvider<HealthSyncService>` alongside the existing `BlocProvider<BagBloc>`; `MyApp` accepts an optional override like `bagBloc`.
- `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Badge (key `virtual_bag_simulate_workout_badge`) placed so it does not collide with `_buildFab`'s "Add Racquet" FAB (e.g. stacked above it); listens to `workouts` and surfaces detections. Reuse `CourtMidnightTheme` colors and `GoogleFonts` styling already used here.
- `string_theory_flutter/test/virtual_bag_screen_test.dart`, `test/widget_test.dart` -- Existing tests pump `VirtualBagScreen`/`MyApp`; they must supply a fake `HealthSyncService`.
- `string_theory_flutter/pubspec.yaml`, `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements` (NEW, referenced via `CODE_SIGN_ENTITLEMENTS` in `ios/Runner.xcodeproj/project.pbxproj`), `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts` (`minSdk = 26`, currently `flutter.minSdkVersion`) -- native config per the `health` package README.
- `string_theory_flutter/lib/bloc/bag_bloc.dart` -- Do not modify.

## Tasks & Acceptance

**Execution:**
- [ ] `string_theory_flutter/test/services/health/*_test.dart` -- write failing tests first (TDD red) for every I/O matrix row: resolver binding, simulated emission/unique ids, native tennis-only mapping, permission-denied and throw paths.
- [ ] `string_theory_flutter/pubspec.yaml` + iOS/Android native config -- add `health` and platform permissions.
- [ ] `string_theory_flutter/lib/services/health/` -- implement interface, simulated, native, resolver.
- [ ] `string_theory_flutter/test/virtual_bag_screen_test.dart` -- failing widget test: badge visible only with a simulation-capable service, tap surfaces the detection; existing tests updated with a fake service.
- [ ] `string_theory_flutter/lib/main.dart`, `lib/screens/virtual_bag_screen.dart` -- wire provider, badge, and detection surface.

**Acceptance Criteria:**
- Given the app built for web (`flutter build web`), when it launches and the badge is tapped, then a 90-minute workout detection appears and no plugin exception is logged.
- Given any detected workout, when inspected, then it maps 1:1 onto a `SessionLog` (`startTime`, `durationMinutes`, `source`, `externalWorkoutId`) without extra health data.

## Implementation Notes

## Spec Change Log

## Review Triage Log

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
