---
title: 'Epic 3 retro item 3: Decompose VirtualBagScreen and WorkoutAssignmentSheet'
type: 'refactor'
created: '2026-10-05'
status: 'done'
baseline_commit: '678e877f08a999928b7d64bc9f2ef6c28a5d11db'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-3-retro-2026-10-04.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `virtual_bag_screen.dart` (868 lines) and `workout_assignment_sheet.dart` (861 lines) are god-classes: nav, FABs, banners, empty/error states, snackbars, duration chips, racquet carousel and the advanced accordion are all inline `_build*` methods or one deeply nested `build`. Epic 4/5 add more UI to both files.

**Approach:** Extract those pieces into dedicated widget files, leaving each file with only its state, subscriptions and orchestration. Behavior, visuals, keys and public API stay identical (retro action: "extract accordion panels, detection banners, and duration selectors into dedicated widget files").

## Boundaries & Constraints

**Always:**
- Existing tests pass unmodified: `test/virtual_bag_screen_test.dart`, `test/widgets/workout_assignment_sheet_test.dart`, `test/widget_test.dart`, `test/bag_bloc_test.dart`.
- Public API unchanged: every `VirtualBagScreen.key*` and `WorkoutAssignmentSheet.key*` constant, `WorkoutAssignmentSheet.showForDetected/showForManual`, `VirtualBagScreen.formatWorkoutDuration`, and the `export '../widgets/racquet_card.dart'`. Each key is defined once, in the extracted widget, and the old static aliases it.
- Extracted widgets are stateless where possible, take data and callbacks via constructor, and never read `BagBloc` themselves unless the original did.
- Stateful logic stays put: health-sync subscription, detection buffering, `_isAssignmentSheetOpen` and `_onConfirm`.
- Match surrounding style: `GoogleFonts`, `CourtMidnightTheme` tokens, single quotes, `dart format`.

**Never:**
- No behavior, layout, copy or key-value changes. No bloc, endpoint or model changes.
- No edits to `lib/generated`, `string_theory_client` or existing tests (new tests may be added).
- No new dependencies; no state-management changes.

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- screen; keep state, health-sync binding, detection buffer/flush, sheet-open guards, `build` orchestration.
- `string_theory_flutter/lib/widgets/workout_assignment_sheet.dart` -- sheet; keep widget fields, `showFor*`, `_explainIfUnloggable`, selection state, `_onConfirm`.
- `string_theory_flutter/lib/widgets/racquet_card.dart` -- precedent for a standalone extracted widget; do not change.
- `string_theory_flutter/lib/main.dart`, `test/virtual_bag_screen_test.dart`, `test/widget_test.dart`, `test/widgets/workout_assignment_sheet_test.dart` -- only consumers of the two files; use only the API listed above.
- Duplicate helper: `VirtualBagScreen.formatWorkoutDuration` and `_WorkoutAssignmentSheetState._formatDuration` are identical.

## Tasks & Acceptance

**Execution:**
- [x] `lib/domain/workout_formatting.dart` -- add `formatWorkoutDuration(int)` and `formatWorkoutStartTime(DateTime, {DateTime? now})`, moved verbatim from the two files -- dedupes helper, makes it unit-testable
- [x] `test/domain/workout_formatting_test.dart` -- cover `1h 30m`/`2h`/`45m`, today vs other-date start time, 12am/12pm -- guards the moved logic
- [x] `lib/widgets/bag/` -- extract `BagBottomNav`, `BagNavigationRail`, `BagLoadingIndicator`, `BagErrorView`, `PendingSyncBanner`, `BagEmptyState`, `SessionsPlaceholder`, `BagRacquetList` (list on mobile, grid on wider), `SimulateWorkoutBadge`, `LogSessionFab`, `AddRacquetFab` -- one file each, owning their keys
- [x] `lib/widgets/bag/bag_snack_bars.dart` -- extract detection, info and error SnackBar builders -- the "detection banners"
- [x] `lib/screens/virtual_bag_screen.dart` -- replace `_build*` methods with the extracted widgets; alias keys; delegate `formatWorkoutDuration` -- target under ~350 lines
- [x] `lib/widgets/workout_assignment/` -- extract `AssignmentSheetFrame` (container, drag pill, inset padding), `DetectedWorkoutHeader`, `ManualLogHeader`, `DurationSelector`, `RacquetSelector` (tile included), `AdvancedOptionsToggle`, `AdvancedOptionsPanel` (`CourtSurfaceSelector` + notes field), `ConfirmButton`
- [x] `lib/widgets/workout_assignment_sheet.dart` -- compose the extracted widgets; alias keys -- target under ~250 lines
- [x] `_bmad-output/implementation-artifacts/sprint-status.yaml` -- set `epic-3-retro-item-3-decompose-virtualbagscreen-and-assignmentsheet` to `done`, bump `last_updated`

**Acceptance Criteria:**
- Given the refactor is applied, when the full Flutter suite runs, then all pre-existing tests pass unmodified.
- Given the app, when the bag screen and the detected and manual sheets render at mobile and tablet widths, then output matches the pre-refactor behavior (keys, copy, layout).
- Given `dart analyze` over the workspace, then no new warnings.
- Given the two original files, then each is substantially smaller and holds no `_build*` widget-returning helpers except thin composition.

## Implementation Notes

## Spec Change Log

## Review Triage Log

## Design Notes

Alias keys without a circular import: `static const keyEmptyState = BagEmptyState.keyEmptyState;` on `VirtualBagScreen`. The new widget files must not import `virtual_bag_screen.dart`.

Order of work: baseline test run, then extract bottom-up (leaf widgets first), running the suite after each file group. Commit per target file: `refactor(flutter): decompose virtual bag screen` and `refactor(flutter): decompose workout assignment sheet`.

## Verification

**Commands:**
- `cd string_theory_flutter && flutter test` -- expected: all pass, same count as baseline plus the new formatter tests
- `dart analyze` (repo root) -- expected: no new issues
- `dart format --set-exit-if-changed string_theory_flutter/lib string_theory_flutter/test` -- expected: exit 0
- `wc -l string_theory_flutter/lib/screens/virtual_bag_screen.dart string_theory_flutter/lib/widgets/workout_assignment_sheet.dart` -- expected: both well under the original ~865 lines
