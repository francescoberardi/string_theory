---
title: 'Story 6.4: Dedicated Sessions History Screen & Domain Model Extraction'
type: 'feature'
created: '2026-10-13'
baseline_commit: 'b1086d44240132c6bc0b2e07512458807449ce6a'
status: 'done'
route: 'dispatch'
review_loop_iteration: 1
context:
  - '{project-root}/_bmad-output/test-artifacts/atdd-checklist-6-4-dedicated-sessions-history-screen-domain-model-extraction.md'
  - '{project-root}/_bmad-output/implementation-artifacts/epic-6-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Sessions tab currently renders a temporary `SessionsPlaceholder` showing static copy, preventing players from reviewing their logged court sessions or accessing quick-log shortcuts from the Sessions tab. In addition, `RacquetPreset` is defined inside `lib/widgets/add_racquet_modal.dart`, violating domain-presentation separation by coupling pure business configuration defaults to Flutter widget code.

**Approach:** Extract `RacquetPreset` into `lib/domain/racquet_preset.dart` and reference it from presentation widgets. Implement a dedicated `SessionsScreen` in `lib/screens/sessions_screen.dart` with a reverse-chronological session list, racquet name resolution, formatted durations and court hours, empty state guidance, and a prominent `[+ Log Session]` quick-log action button. Wire `SessionsScreen` into `VirtualBagScreen` across BottomNav, NavigationRail, and NavigationDrawer, update existing placeholder navigation tests, and un-skip the Story 6.4 ATDD acceptance tests to turn them green.

## Boundaries & Constraints

**Always:**
- Keep domain models in `lib/domain/` pure Dart with zero dependencies on Flutter UI widgets or `BuildContext`.
- Re-export `RacquetPreset` from `lib/domain/racquet_preset.dart` or keep clean import references in `lib/widgets/add_racquet_modal.dart` to maintain backward compatibility.
- Follow `CourtMidnightTheme` tokens for the new `SessionsScreen` cards, badges, and empty states.
- Support responsive navigation: mobile (`BagBottomNav`), tablet (`BagNavigationRail`), and desktop (`BagNavigationDrawer`).
- Wire the `[+ Log Session]` button on `SessionsScreen` directly to `WorkoutAssignmentSheet.showManual`.
- Keep trunk green and verify clean static analysis (`flutter analyze` / `analyze_files`).

**Never:**
- Never edit generated code (`string_theory_client`, `lib/src/generated/`).
- Never delete or break existing `AddRacquetModal` preset selection or smart defaults logic.
- Never drop or leave unhandled errors when fetching session logs fails (render friendly retry state).

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Select Sessions tab | Tapping Sessions in bottom nav, rail, or drawer | Renders `SessionsScreen` (replaces `SessionsPlaceholder`) | N/A |
| Sessions exist | `getSessionLogs` returns 1+ sessions | Displays reverse-chronological list of cards with date, duration (e.g. `90 min`), racquet name, and court hours added (`+1.5 hrs`) | N/A |
| No sessions logged | `getSessionLogs` returns empty list `[]` | Renders `sessions_empty_state` with tennis icon, guidance copy, and `[+ Log Session]` button | N/A |
| Network error fetching logs | `getSessionLogs` throws exception | Displays error view with user-friendly message and `[Retry]` button | Traps exception, sets `errorMessage` |
| Tap `[+ Log Session]` | Player taps prominent button on Sessions screen | Opens `WorkoutAssignmentSheet.showManual` modal with loaded racquets | N/A |
| Domain model extraction | Instantiating `RacquetPreset` | Pure Dart model with `popularPoly` matching `StringCategoryDefaults.maxHours(coPoly)` (20.0 hrs) | Compile-time pure Dart enforcement |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/domain/racquet_preset.dart` -- Pure Dart domain model encapsulating preset specifications (`name`, `brand`, `model`, `materialCategory`, `stringBrand`, `stringModel`, `tension`, `maxRatedHours`) and canonical `popularPoly` preset.
- `string_theory_flutter/lib/widgets/add_racquet_modal.dart` -- Re-export or import domain `RacquetPreset`, removing duplicate class definition while preserving modal UI behavior and keys.
- `string_theory_flutter/lib/screens/sessions_screen.dart` -- Dedicated Sessions screen widget with `keySessionsScreen`, loading state, empty state (`keySessionsEmptyState`), sessions list (`keySessionsListView`), session card items, and `[+ Log Session]` CTA (`keyLogSessionButton`).
- `string_theory_flutter/lib/widgets/sessions/session_history_card.dart` (or inline in `sessions_screen.dart`) -- Card displaying date, duration, racquet name (resolved from `racquetId`), and court hours badge (`+X.X hrs`).
- `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Replace `SessionsPlaceholder()` in navigation switch (line 394) with `SessionsScreen`.
- `string_theory_flutter/test/virtual_bag_screen_test.dart` -- Update navigation test expectations from `SessionsPlaceholder` / `'COURT SESSIONS'` to `SessionsScreen` / `keySessionsScreen`.
- `string_theory_flutter/test/domain/racquet_preset_test.dart` -- Story 6.4 unit acceptance tests for `RacquetPreset` domain contracts.
- `string_theory_flutter/test/widgets/sessions_screen_test.dart` -- Story 6.4 widget acceptance tests for `SessionsScreen` navigation, list rendering, and CTA.
- `string_theory_flutter/test/helpers/tdd_red_phase.dart` -- Toggle `tddRedPhase64 = false` to turn tests green.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_flutter/lib/domain/racquet_preset.dart` -- Extract `RacquetPreset` domain model with pure properties and `popularPoly` default preset (AC-4).
- [x] `string_theory_flutter/lib/widgets/add_racquet_modal.dart` -- Update imports to reference domain `RacquetPreset`, removing internal class definition (AC-4).
- [x] `string_theory_flutter/lib/screens/sessions_screen.dart` -- Implement `SessionsScreen` with `getSessionLogs` loading, session list, empty state, and `[+ Log Session]` CTA (AC-1, AC-2, AC-3).
- [x] `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Route `AppNavigationDestination.sessions` to `SessionsScreen` in navigation switch (AC-1).
- [x] `string_theory_flutter/test/virtual_bag_screen_test.dart` -- Update existing navigation tests (lines 1066, 1099, 1211) to assert `SessionsScreen` instead of `SessionsPlaceholder`.
- [x] `string_theory_flutter/test/domain/racquet_preset_test.dart` -- Import domain `RacquetPreset` and verify domain tests pass.
- [x] `string_theory_flutter/test/helpers/tdd_red_phase.dart` -- Toggle `tddRedPhase64 = false` and verify all tests pass green.

**Acceptance Criteria:**
- Given the app navigation (BottomNav, NavigationRail, and Drawer), when the player selects the "Sessions" tab, then the app renders a dedicated `SessionsScreen` (replacing the temporary `SessionsPlaceholder`).
- Displays a chronological list of logged sessions with date, duration, racquet name, and court hours added, and an empty state when no sessions are logged.
- Provides a prominent `[+ Log Session]` action button that triggers the manual workout assignment quick-log sheet.
- `RacquetPreset` and `StringCategoryDefaults` are relocated from UI widgets into pure domain models in the domain layer, with presentation files referencing the domain contracts.

## Implementation Notes

- Extracted pure Dart `RacquetPreset` into `lib/domain/racquet_preset.dart` without Flutter widget or `BuildContext` dependencies, re-exporting from `lib/widgets/add_racquet_modal.dart` for backward compatibility.
- Implemented `SessionHistoryCard` in `lib/widgets/sessions/session_history_card.dart` displaying racquet name resolved from `racquetId`, duration (`X min`), court hours badge (`+X.X hrs`), date, surface, notes, and source badge.
- Implemented `SessionsScreen` in `lib/screens/sessions_screen.dart` featuring dynamic session logs fetching, reverse-chronological list view (`keySessionsListView`), empty state guidance (`keySessionsEmptyState`), loading and retry states, and `[+ Log Session]` button (`keyLogSessionButton`) wired to `WorkoutAssignmentSheet.showForManual`.
- Wired `SessionsScreen` into `VirtualBagScreen` across BottomNav, NavigationRail, and NavigationDrawer, replacing `SessionsPlaceholder`.
- Updated navigation tests in `test/virtual_bag_screen_test.dart` to assert `SessionsScreen` presence.
- Toggled `tddRedPhase64 = false` in `test/helpers/tdd_red_phase.dart` and verified all 426 tests pass green.

## Spec Change Log

- **Iteration 1**: Triaged review findings from Verification Gap, Edge Case Hunter, and Blind Hunter review passes. Patched missing ATDD edge scenarios, in-flight loading guards, pull-to-refresh UX preservation, source badge mapping, domain equality, and responsive container constraints.

## Review Triage Log

| Finding ID | Source | Issue Description | Severity | Verdict | Action Taken |
|------------|--------|-------------------|----------|---------|--------------|
| REV-01 | Verification Gap | Missing empty state test in `sessions_screen_test.dart` | High | Valid | Patched with dedicated empty state and CTA widget test |
| REV-02 | Verification Gap | Missing network error and retry button test | High | Valid | Patched with error state rendering and retry verification test |
| REV-03 | Verification Gap | Missing sort order verification with unsorted input | Medium | Valid | Patched with reverse-chronological sorting widget test |
| REV-04 | Edge Case Hunter | Race condition in concurrent fetch invocations | Medium | Valid | Patched with `_isFetching` in-flight guard in `SessionsScreen` |
| REV-05 | Edge Case Hunter | Pull-to-refresh unmounts `RefreshIndicator` & `ListView` | High | Valid | Patched: only set `_isLoading = true` if `_sessions == null` |
| REV-06 | Edge Case Hunter | Failed client resolution defaults to empty list without error | Medium | Valid | Patched: surfaces user-friendly error state with retry button |
| REV-07 | Edge Case Hunter | Whitespace-only court surface passes `isNotEmpty` check | Low | Valid | Patched: added `.trim().isNotEmpty` guard in `SessionHistoryCard` |
| REV-08 | Edge Case Hunter | Negative duration formats with double sign (`+-1.5 hrs`) | Low | Valid | Patched: added sign defensive format guard in `SessionHistoryCard` |
| REV-09 | Blind Hunter | Source badge string mismatch (`healthkit`, `simulated`) | Medium | Valid | Patched: added pattern matching aliases in `SessionHistoryCard` |
| REV-10 | Blind Hunter | Redundant plus glyph (`+ + Log Session`) on buttons | Medium | Valid | Patched: updated label to `'Log Session'` alongside `Icon(Icons.add)` |
| REV-11 | Blind Hunter | Empty state copy advises logging on Bag tab instead of Sessions | Low | Valid | Patched: updated guidance copy to reflect Sessions screen action |
| REV-12 | Blind Hunter | Redundant premature fetch on modal dismissal in `_handleLogSession` | Medium | Valid | Patched: removed redundant fetch; relied on `BagBloc` stream sync |
| REV-13 | Blind Hunter | Semantic baseball icon used for tennis court surface | Low | Valid | Patched: updated to `Icons.sports_tennis` in `SessionHistoryCard` |
| REV-14 | Blind Hunter | Unconstrained full-width cards on tablet and desktop | Low | Valid | Patched: wrapped `ListView.builder` in `ConstrainedBox(maxWidth: 800)` |
| REV-15 | Blind Hunter | Extracted `RacquetPreset` domain model lacks equality and hashCode | Medium | Valid | Patched: implemented `operator ==` and `hashCode` in `RacquetPreset` |
| REV-16 | Blind Hunter | `VirtualBagScreen` omitted `racquets` param to `SessionsScreen` | Medium | Valid | Patched: passed `racquets: state is BagLoaded ? state.racquets : null` |

