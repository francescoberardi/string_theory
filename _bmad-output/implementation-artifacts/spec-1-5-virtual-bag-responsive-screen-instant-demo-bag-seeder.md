---
title: 'Story 1.5: Virtual Bag Responsive Screen & Instant Demo Bag Seeder'
type: 'feature'
created: '2026-10-04'
status: 'done'
baseline_commit: '8a90ef1a194c3c74da5647d425fa032a595f8e58'
route: 'dispatch'
review_loop_iteration: 1
context:
  - 'AGENTS.md'
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/DESIGN.md'
  - '_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/EXPERIENCE.md'
  - '_bmad-output/test-artifacts/atdd-checklist-1-5-virtual-bag-responsive-screen-instant-demo-bag-seeder.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Hackathon judges and new players opening String Theory for the first time see an empty bag without mock data, and the app lacks a responsive multi-racquet dashboard screen adapting across mobile and tablet/desktop.

**Approach:** Implement `VirtualBagScreen` in `string_theory_flutter/lib/screens/virtual_bag_screen.dart` with Court Midnight theme styling, an empty-state card featuring `[+ Add Racquet]` (opening `AddRacquetModal`) and `[⚡ Load Sample Bag]` (seeding 3 realistic racquets via `BagBloc.add(SeedSampleBag())`), and adaptive responsive presentation (single-column list with bottom nav on mobile <600dp, 2-column grid with NavigationRail on tablet/desktop >=600dp). Connect `VirtualBagScreen` as the default home body in `main.dart`.

## Boundaries & Constraints

**Always:**
- Use exact Court Midnight palette tokens from `DESIGN.md`: `#121516` canvas background, `#1A1E20` slate card surface, `#2A3034` border outline, `#C6F10E` electric volt primary, Barlow Condensed for metric/frame headings, and Inter for specs.
- Render empty state when `BagLoaded` contains an empty racquets list, featuring both `[+ Add Racquet]` (`keyEmptyAddButton`) and `[⚡ Load Sample Bag]` (`keyLoadSampleBagButton`).
- Tapping `[+ Add Racquet]` must open `AddRacquetModal.show(context, bagBloc: ...)`.
- Tapping `[⚡ Load Sample Bag]` must dispatch `SeedSampleBag()` to `BagBloc`, creating 3 realistic racquets:
  1. Wilson Blade 98 @ 76% health (Luxilon ALU Power Co-Poly @ 52 lbs, 5h / 20h max, primary).
  2. Babolat Pure Drive @ 58% health (Babolat RPM Blast Co-Poly @ 54 lbs, 9h / 20h max).
  3. Head Radical MP @ 34% health (Head Velocity MLT Multifilament @ 55 lbs, 25h / 35h max).
- Implement responsive layout switching at 600dp threshold:
  - Mobile (<600dp): single-column list (`keyRacquetList`) + `BottomNavigationBar` (`keyBottomNav`).
  - Tablet/Desktop (>=600dp): 2-column grid (`keyRacquetGrid`) + `NavigationRail` (`keyNavigationRail`).
- Maintain 100% test pass rate on all acceptance criteria in `string_theory_flutter/test/virtual_bag_screen_test.dart`.

**Never:**
- Never hardcode fixed pixel widths that break on small mobile devices or cause overflow errors.
- Never edit generated code in `string_theory_client` or `string_theory_server/lib/src/generated/`.
- Never block user interaction with unrecoverable loading spinners on failed bag loads; show retry action.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Empty Bag | `BagLoaded([])` | Renders `keyEmptyState` with `[+ Add Racquet]` and `[⚡ Load Sample Bag]` | Allows user to seed or add |
| Tap Add Racquet | User taps `[+ Add Racquet]` | Opens `AddRacquetModal` bottom sheet | Modal handles its own submission |
| Tap Load Sample Bag | User taps `[⚡ Load Sample Bag]` | Dispatches `SeedSampleBag` event; seeds 3 racquets via Serverpod and emits `BagLoaded([3 racquets])` | Emits `BagError` on RPC failure |
| Mobile Viewport | Viewport width < 600dp | Renders single-column list (`keyRacquetList`) and bottom navigation bar (`keyBottomNav`) | Smooth scroll behavior |
| Tablet Viewport | Viewport width >= 600dp | Renders 2-column grid (`keyRacquetGrid`) and `NavigationRail` (`keyNavigationRail`) | Adaptive grid layout |
| Bag Loading | `BagLoading` state | Displays centered loading indicator (`keyLoadingIndicator`) | Non-blocking animation |
| Bag Error | `BagError` state | Displays error banner with retry button dispatching `LoadBag()` | Actionable retry |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Main Virtual Bag screen implementing responsive layouts, empty state, and sample bag trigger.
- `string_theory_flutter/lib/bloc/bag_event.dart` -- `SeedSampleBag` event.
- `string_theory_flutter/lib/bloc/bag_bloc.dart` -- Handles `SeedSampleBag`, orchestrating creation of the 3 realistic demo racquets.
- `string_theory_flutter/lib/widgets/add_racquet_modal.dart` -- Modal launched from empty state or FAB.
- `string_theory_flutter/lib/main.dart` -- Replaces `GreetingsScreen()` with `VirtualBagScreen()` as the root body.
- `string_theory_flutter/test/virtual_bag_screen_test.dart` -- Acceptance test suite verifying AC-1 through AC-5.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_flutter/lib/bloc/bag_bloc.dart` -- Implement `_onSeedSampleBag` handler creating the 3 realistic racquets via Serverpod -- AC-3
- [x] `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Build empty state view with `[+ Add Racquet]` and `[⚡ Load Sample Bag]` buttons -- AC-1, AC-2, AC-3
- [x] `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Build responsive layout switching between mobile (single-column + bottom nav) and tablet (2-column grid + NavigationRail) -- AC-4, AC-5
- [x] `string_theory_flutter/lib/main.dart` -- Wire `VirtualBagScreen` into `MyHomePage` body -- Integration
- [x] `string_theory_flutter/test/virtual_bag_screen_test.dart` -- Un-skip and execute all 5 acceptance tests to turn them green -- Verification

**Acceptance Criteria:**
- Given user opens Virtual Bag with no racquets, then empty state renders with `[+ Add Racquet]` and `[⚡ Load Sample Bag]` (AC-1).
- When user taps `[+ Add Racquet]` on empty state, then `AddRacquetModal` opens (AC-2).
- When user taps `[⚡ Load Sample Bag]`, then 3 realistic racquets are seeded and bag updates (AC-3).
- On mobile (<600dp), racquets display in single-column list with bottom navigation bar (AC-4).
- On tablet/desktop (>=600dp), racquets display in adaptive 2-column grid with NavigationRail (AC-5).

## Implementation Notes

- Implemented `_onSeedSampleBag` in `BagBloc` (`string_theory_flutter/lib/bloc/bag_bloc.dart`) to create Wilson Blade 98 (primary co-poly), Babolat Pure Drive (co-poly), and Head Radical MP (multifilament) through Serverpod `createRacquet`, refreshing the virtual bag with `getVirtualBag()`.
- Implemented `VirtualBagScreen` with Court Midnight theme tokens, empty state with `[+ Add Racquet]` and `[⚡ Load Sample Bag]` buttons, responsive layout switching (<600dp mobile list with bottom navigation bar, >=600dp tablet 2-column grid with NavigationRail), loading indicator, error retry banner, and `RacquetCard` with radial health gauge and status badges.
- Connected `VirtualBagScreen` as the default body of `MyHomePage` in `string_theory_flutter/lib/main.dart`.
- Unskipped and validated all 5 acceptance tests in `string_theory_flutter/test/virtual_bag_screen_test.dart`.
- Added unit test in `string_theory_flutter/test/bag_bloc_test.dart` for `SeedSampleBag`.

## Spec Change Log

None.

## Review Triage Log

- **Seeded demo racquets court hours and health scores**: `BagBloc._onSeedSampleBag` now maps the seeded racquets to set realistic court hours (5.0h, 9.0h, 25.0h) and health scores (76%, 58%, 34%) to strictly adhere to the spec requirements.
- **Unstrung racquet health indicator**: Updated `RacquetCard` and `_buildHealthGauge` so unstrung racquets without an active string job render `'--'`, `'UNSTRUNG'`, and `'No string mounted'` with neutral tertiary styling instead of erroneously showing `100% HEALTH`.
- **Tablet grid aspect ratio overflow**: Switched `GridView.builder` from fixed `childAspectRatio: 2.3` to `mainAxisExtent: 140` to guarantee zero layout overflow across all tablet widths.
- **FAB obscuring bottom list/grid card**: Added bottom padding (`bottom: 88`) to both `ListView.separated` and `GridView.builder`.
- **Pull-to-refresh**: Wrapped both list and grid views in `RefreshIndicator` dispatching `LoadBag()`.
- **Racquet deletion safety**: Added confirmation `AlertDialog` before dispatching `DeleteRacquet`.
- **String specs null formatting**: Sanitized string specs assembly to cleanly omit absent fields without awkward whitespace.
- **Sessions navigation tab**: Built `_buildSessionsPlaceholder()` with tennis icon and "Court Sessions" title for destination index 1.
- **Duplicate initial load race**: Removed redundant post-frame callback `LoadBag()` from `initState`.
- **Verification gaps closed**: Added tests in `widget_test.dart` (asserting `VirtualBagScreen` is mounted), `virtual_bag_screen_test.dart` (card assertions, `BagLoading`, `BagError`, and unstrung racquet state), and `bag_bloc_test.dart` (RPC error handling).

## Verification

**Commands:**
- `analyze_files` (Dart MCP) -- 0 errors across workspace (PASSED)
- `flutter test` -- 40/40 tests in `string_theory_flutter` pass green (PASSED)
- `dart test` (server package) -- all server integration tests pass green (PASSED)
- `dart format` -- all Dart files formatted cleanly (PASSED)
