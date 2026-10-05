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

### Review Findings

- [x] [Review][Patch] Pull-to-refresh dispatch of `LoadBag` is untested (mobile list and tablet grid) [string_theory_flutter/lib/widgets/bag/bag_racquet_list.dart:24] — `_onRefresh` moved out of the screen and now uses a constructor-supplied bloc; no test drags the list or grid, so an empty `_onRefresh` would pass every test. Add a fling test at mobile and 900px widths in `test/virtual_bag_screen_test.dart` asserting `LoadBag`. (verification-gap, medium)
- [x] [Review][Patch] Tablet `BagNavigationRail` tap wiring and the Sessions placeholder are unverified [string_theory_flutter/lib/widgets/bag/bag_navigation_rail.dart:25] — rail tests only check the rail's presence; nothing taps Sessions/Account at width >= 600 or asserts `COURT SESSIONS`. Rail ignoring `onDestinationSelected` or hard-coding `selectedIndex` would pass. (verification-gap, medium)
- [x] [Review][Patch] Add Racquet FAB tap is never verified to open `AddRacquetModal` [string_theory_flutter/lib/widgets/bag/add_racquet_fab.dart:12] — the key `virtual_bag_fab_add` is only checked for existence (`test/virtual_bag_screen_test.dart:409`, `:525`); the FAB `onPressed` closure was rewritten in `_buildFab`. Add a tap test with a populated bag. (verification-gap, medium)
- [x] [Review][Patch] Surface chip toggle-off (and advanced-options collapse) has no assertion [string_theory_flutter/lib/widgets/workout_assignment/court_surface_selector.dart] — nothing taps a selected chip twice and confirms `courtSurface` is null, so `onChanged(surface)` replacing `onChanged(isSelected ? null : surface)` passes. Extend the "expanding [+ Advanced Options]" test. (verification-gap, low)
- [x] [Review][Defer] Info SnackBar icon mapping (`cloud_off` vs `cloud_done`) and error SnackBar red background are not asserted [string_theory_flutter/lib/widgets/bag/bag_snack_bars.dart] — deferred: visual-only, message text already verified (verification-gap, low)
- [x] [Review][Defer] Sessions placeholder shows internal planning vocabulary, "coming soon in Epic 2", although session logging has shipped [string_theory_flutter/lib/widgets/bag/sessions_placeholder.dart:46] — deferred: pre-existing copy moved verbatim; spec forbids copy changes (blind-hunter, low)
- [x] [Review][Defer] Bag/Sessions/Account destinations are hand-copied in `BagBottomNav` and `BagNavigationRail`; adding a tab means editing both and keeping indices in order [string_theory_flutter/lib/widgets/bag/bag_bottom_nav.dart:31] — deferred: pre-existing duplication, now more visible; revisit when Epic 5 adds a tab (blind-hunter, low)

#### Rejected

- `last_updated` moves from `12:00` to `09:43` in `sprint-status.yaml` (acceptance-auditor, edge-case-hunter, blind-hunter, verification-gap) — low: the literal claim is true, but the commit was made at 09:44, so `09:43` is the real clock time and the old `12:00` was the odd value; no tool or reader depends on it.
- `virtual_bag_screen.dart` is 368 lines vs "~350", sheet 256 vs "~250" (acceptance-auditor, edge-case-hunter) — low: the targets are approximate, both files are well under half their original size, and the remaining `_build*` methods are thin composition.
- `export '../widgets/racquet_card.dart'` possibly dropped (acceptance-auditor) — false: still present at `virtual_bag_screen.dart:27`.
- `BagRacquetList` holds a stale bloc / crashes on a closed bloc (edge-case-hunter) — false: the original also called `_resolveBloc(context)` per use; the screen re-resolves it on every build and `_resolveBloc` returns the same stable instance. A closed bloc fails the same way pre-refactor.
- `BagRacquetList` takes `BagBloc` directly, inconsistent with callback-style widgets (blind-hunter) — false: it does not read the bloc; it forwards it to `RacquetCard`, which required it before the refactor.
- FAB column logic rewritten rather than moved (acceptance-auditor) and repetitive `if (hasRacquets)` (blind-hunter) — false: spacing traced for every badge/racquet combination and is identical to the original; both FABs exist iff `hasRacquets`. No named harm in the repetition.
- Null-id racquet is shown selected / index-fallback key can collide (edge-case-hunter) — low: logic moved verbatim from the original sheet (`racquet.id ?? index`); server-persisted racquets always have ids.
- `formatWorkoutStartTime` with UTC `now`; `formatWorkoutDuration` with zero/negative minutes; hard-coded English formatting vs `intl` (edge-case-hunter, blind-hunter) — low: logic moved verbatim per spec; `now` defaults to local time and is only injected by tests; adding guards or `intl` is scope creep for a no-behavior-change refactor.
- `VirtualBagScreen.formatWorkoutDuration` wrapper and key aliases kept alive only by an old test; duplicate formatting test (blind-hunter, verification-gap) — false: the spec requires this public API to stay unchanged and forbids editing existing tests.
- `AddRacquetFab` key not aliased on `VirtualBagScreen` (blind-hunter) — false: the original had no static alias for it (inline `Key('virtual_bag_fab_add')`); adding one would add public surface the spec forbids.
- `SimulateWorkoutBadge` "dev-only" without `kDebugMode` (blind-hunter) — false: gating by `supportsSimulation` is the original behavior and the spec forbids behavior changes.
- `buildDetectionSnackBar` lacks its own `mounted` guard (edge-case-hunter) — false: the only caller keeps `if (!mounted) return;` (`virtual_bag_screen.dart:186`).
- Chip decoration, 76px icon badge and label styles duplicated; inline `GoogleFonts` instead of theme text styles (blind-hunter) — low: pre-existing duplication carried over verbatim; consolidating would alter visuals the spec freezes.
- New widgets untested; refactor lacks a `test(...)` step per TDD (blind-hunter) — low: pre-existing tests pass unmodified, the spec's acceptance criterion, and specific wiring gaps are covered by the patch items above.
- Spec marked done without recorded evidence / "verbatim" overstated (blind-hunter, edge-case-hunter) — rejected: the fix would be editing the spec under review.
