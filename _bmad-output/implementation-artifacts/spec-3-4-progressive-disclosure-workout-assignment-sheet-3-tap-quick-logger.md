---
title: 'Story 3.4: Progressive Disclosure Workout Assignment Sheet & 3-Tap Quick Logger'
type: 'feature'
created: '2026-10-04'
status: 'done'
baseline_commit: '8b3a08144e0ee413c8e40ce5bbf199f9ed9aabf4'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '_bmad-output/implementation-artifacts/epic-3-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** When tennis workouts are detected from Apple Health, Health Connect, or the judge simulation generator, players have no UI to attribute that court time to a specific racquet in their virtual bag. Furthermore, players without smartwatches lack a rapid manual logging flow to capture court playtime in under 10 seconds.

**Approach:** Build a progressive disclosure `WorkoutAssignmentSheet` bottom sheet and integrate a `[+ Log Session]` FAB on the bag screen. The sheet pre-selects the primary racquet for a $\le 2$-tap confirmation, offers an expandable `[+ Advanced Options]` accordion for court surface and notes, and provides quick duration chips (`30m`, `1h`, `1.5h`, `2h`) for manual logging, dispatching a new `LogSession` event to `BagBloc`.

## Boundaries & Constraints

**Always:**
- Pre-select the primary racquet (`isPrimary == true`); fallback to the first racquet if no primary is designated.
- Quick logging for detected workouts must complete in $\le 2$ taps (1 tap on `[Confirm]` with pre-selected primary; 2 taps if switching racquets then `[Confirm]`).
- Manual quick-logger accessible via `[+ Log Session]` FAB (key `virtual_bag_fab_log_session`) on `VirtualBagScreen` when racquets exist.
- Manual duration chips: `30m` (30 min), `1h` (60 min), `1.5h` (90 min), `2h` (120 min), default selected `1h`.
- Progressive disclosure accordion starts collapsed with button `+ Advanced Options` (key `workout_assignment_advanced_toggle`); expanding reveals court surface chips (`Hard`, `Clay`, `Grass`, `Carpet`) and a session notes text area.
- Tapping `[Confirm]` dispatches `LogSession` on `BagBloc`, which calls `client.session.logSession(SessionLog(...))`, refreshes the bag, and dismisses the workout from `HealthSyncService.pendingWorkouts`.
- Surface chips and notes are optional (default to null when omitted).
- Maintain Court Midnight design tokens (`#121516` background, `#1A1E20` surface, `#C6F10E` primary volt, Inter body, Barlow Condensed headers) and minimum $48\times 48$ dp touch targets.

**Never:**
- No database migrations, server endpoint modifications, or protocol changes (Story 3.1 & 3.2 already established `SessionLog` and `SessionEndpoint`).
- Never edit generated files under `lib/src/generated/` or the `string_theory_client` package.
- No offline local caching queue in this story (Story 3.5).
- Do not transmit unneeded health data; only `SessionLog` properties (`startTime`, `durationMinutes`, `courtSurface`, `notes`, `source`, `externalWorkoutId`).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Detected workout assignment | Detected workout received; bottom sheet opened | Primary racquet pre-selected; duration displayed; 1-tap `[Confirm]` logs session with workout metadata | SnackBar on server error |
| Racquet switch | User taps secondary racquet in sheet | Selection shifts to secondary racquet; `[Confirm]` logs session to secondary racquet | N/A |
| Advanced options expansion | User taps `[+ Advanced Options]` | Accordion expands smoothly; surface chips (`Hard`, `Clay`, `Grass`, `Carpet`) and notes field visible | N/A |
| Advanced options selection | User selects `Clay` chip and enters note "Heavy baseline rally" | Session logged with `courtSurface: 'Clay'` and `notes: 'Heavy baseline rally'` | N/A |
| Manual quick-logger open | User taps `[+ Log Session]` FAB | Bottom sheet opens in manual mode with duration chips (`30m`, `1h`, `1.5h`, `2h`), primary racquet selected | N/A |
| Manual quick-logger save | User selects `1.5h` chip and taps `[Confirm]` | Session logged with `durationMinutes: 90`, `source: 'manual'`, `startTime: now` | SnackBar on server error |
| Single detection trigger | Workout emitted by `HealthSyncService` on bag screen | SnackBar shown with `[Assign]` action, and sheet opens automatically if bag is loaded with racquets | Safe no-op if unmounted |
| Workouts pending cleanup | Workout confirmed in assignment sheet | Workout removed from `HealthSyncService.pendingWorkouts` | N/A |
| Empty bag attempt | Bag has 0 racquets; user triggers log | Informational message/toast prompts user to add a racquet first | Sheet disabled or shows empty CTA |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/bloc/bag_event.dart` -- Add `LogSession` event carrying `racquetId`, `startTime`, `durationMinutes`, `courtSurface`, `notes`, `source`, `externalWorkoutId`.
- `string_theory_flutter/lib/bloc/bag_bloc.dart` -- Handle `LogSession`: calls `client.session.logSession(SessionLog(...))`, fetches updated virtual bag, and emits `BagLoaded`.
- `string_theory_flutter/lib/services/health/health_sync_service.dart` -- Add `void dismissPendingWorkout(String externalWorkoutId)` to `HealthSyncService` interface.
- `string_theory_flutter/lib/services/health/simulated_health_sync_service.dart` -- Implement `dismissPendingWorkout` by removing matching workout from `_pending`.
- `string_theory_flutter/lib/services/health/native_health_sync_service.dart` -- Implement `dismissPendingWorkout` by removing matching workout from `_pending`.
- `string_theory_flutter/test/helpers/fake_health_sync_service.dart` -- Implement `dismissPendingWorkout` on test fake.
- `string_theory_flutter/lib/widgets/workout_assignment_sheet.dart` -- NEW. Progressive disclosure bottom sheet widget with duration header, horizontal racquet selector carousel, expandable accordion with surface chips & notes, and `[Confirm]` CTA. Exposes static `showForDetected(...)` and `showForManual(...)`.
- `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Add `[+ Log Session]` FAB (key `virtual_bag_fab_log_session`) stacked with simulate badge and add racquet FAB; wire up detection listener to open assignment sheet and offer `[Assign]` action on SnackBar.
- `string_theory_flutter/test/widgets/workout_assignment_sheet_test.dart` -- NEW. Widget tests covering pre-selection of primary racquet, 1-tap confirmation, racquet switching, accordion expansion, surface selection, and manual duration chips.
- `string_theory_flutter/test/bloc/bag_bloc_test.dart` -- Test `LogSession` event handling, calling `client.session.logSession` and updating state.
- `string_theory_flutter/test/virtual_bag_screen_test.dart` -- Update tests for new `[+ Log Session]` FAB and assignment sheet invocation.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_flutter/test/bloc/bag_bloc_test.dart` -- Add unit test for `LogSession` event handling on `BagBloc` verifying `client.session.logSession` invocation and state update.
- [x] `string_theory_flutter/lib/bloc/bag_event.dart` & `lib/bloc/bag_bloc.dart` -- Implement `LogSession` event and handler.
- [x] `string_theory_flutter/lib/services/health/health_sync_service.dart`, `simulated_health_sync_service.dart`, `native_health_sync_service.dart`, & `test/helpers/fake_health_sync_service.dart` -- Add and implement `dismissPendingWorkout`.
- [x] `string_theory_flutter/test/widgets/workout_assignment_sheet_test.dart` -- Write comprehensive widget tests verifying:
  - Pre-selected primary racquet in detected mode.
  - $\le 2$-tap confirmation with `[Confirm]` button.
  - Selecting an alternate racquet from the horizontal carousel.
  - Expanding `[+ Advanced Options]` reveals court surface chips (`Hard`, `Clay`, `Grass`, `Carpet`) and notes text field.
  - Manual mode displays duration chips (`30m`, `1h`, `1.5h`, `2h`) and dispatches `source: 'manual'`.
- [x] `string_theory_flutter/lib/widgets/workout_assignment_sheet.dart` -- Implement `WorkoutAssignmentSheet` widget and `.show()` helpers.
- [x] `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Add `[+ Log Session]` FAB (key `virtual_bag_fab_log_session`) and connect detected workout listener to assignment sheet.
- [x] `string_theory_flutter/test/virtual_bag_screen_test.dart` -- Verify `virtual_bag_fab_log_session` presence, coexistence with other controls, and assignment launch.

**Acceptance Criteria:**
- Given a detected or simulated tennis workout, when the bottom sheet opens, then the primary racquet is pre-selected and tapping `[Confirm]` logs the session in $\le 2$ taps.
- Given the bottom sheet is open, when tapping `[+ Advanced Options]`, then the accordion expands to reveal court surface chips (`Hard`, `Clay`, `Grass`) and session notes.
- Given the virtual bag screen with racquets, when tapping the FAB `[+ Log Session]`, then the quick logger opens with duration chips (`30m`, `1h`, `1.5h`, `2h`) that saves in $<10$ seconds.

## Implementation Notes

## Spec Change Log

## Review Triage Log

- `low` (Blind Hunter): Missing workout start time in header (`workout_assignment_sheet.dart`). Design Notes state top bar displays start time. -> patch
- `low` (Blind Hunter): Advanced options toggle touch target is ~36 dp instead of 48 dp. -> patch
- `medium` (Blind Hunter, Edge Case Hunter, Verification Gap): Duplicate sheet invocation via SnackBar `Assign` action and SnackBar lingering after sheet confirmation. -> patch
- `false` (Blind Hunter, Edge Case Hunter): Multi-workout batch drops subsequent workouts. Refuted: workouts remain safely stored in `HealthSyncService.pendingWorkouts`.
- `low` (Blind Hunter, Edge Case Hunter, Verification Gap): Workout dismissed from pendingWorkouts upon Confirm tap before RPC completes. Spec specifically required this behavior.
- `medium` (Blind Hunter, Edge Case Hunter): Emitting `BagError` on `LogSession` replaces entire virtual bag view with fatal error screen instead of displaying non-blocking SnackBar. -> patch
- `medium` (Blind Hunter, Edge Case Hunter): Unstrung racquets without active string jobs are selectable in `WorkoutAssignmentSheet`, causing backend 400 rejection. -> patch
- `false` (Blind Hunter): Hardcoded `userId: 0` in client `SessionLog`. Refuted: standard Serverpod ORM client convention, server stamps `authenticatedUserId`.
- `false` (Blind Hunter): Potential double bottom view inset. Refuted: standard Flutter pattern for modal bottom sheet keyboard avoidance.
- `low` (Blind Hunter): Missing test for sheet dismissal keeping pending workouts intact. -> patch
- `medium` (Edge Case Hunter): Rapid double-tap on Confirm button dispatches duplicate `LogSession` events. -> patch
- `medium` (Verification Gap): Default 1h duration in manual quick-logger confirmed without changing presets is unverified in tests. -> patch
- `medium` (Verification Gap): SnackBar 'Assign' action callback on detected workout is never executed in tests. -> patch
- `medium` (Verification Gap): Empty-bag validation in `WorkoutAssignmentSheet.showForDetected` and `showForManual` is unverified in tests. -> patch


## Design Notes

The `WorkoutAssignmentSheet` uses `CourtMidnightTheme` styling:
- Top bar displays duration pill (`[1h 30m]` or selected duration chip) and start time.
- Racquet selector renders a horizontal scrollable row of compact racquet tiles with racquet name, string model, and a distinct volt border for the selected item.
- Accordion uses an `AnimatedCrossFade` or `AnimatedSize` toggled by an `InkWell` / `TextButton` labeled `+ Advanced Options` / `- Fewer Options`.
- Confirm button is a full-width `ElevatedButton` in `CourtMidnightTheme.primaryVolt` with black bold text.

## Verification

**Commands:**
- `dart analyze` in repo root -- expected: No issues found
- `dart format --set-exit-if-changed .` in `string_theory_flutter` -- expected: no formatting diffs
- `flutter test` in `string_theory_flutter` -- expected: all unit and widget tests pass
- `flutter build web` in `string_theory_flutter` -- expected: web build succeeds
