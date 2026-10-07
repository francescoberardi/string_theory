---
title: 'Consolidate navigation destination models across bottom nav, rail, and drawer'
type: 'refactor'
created: '2026-10-07'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `BagBottomNav`, `BagNavigationRail`, and `BagNavigationDrawer` each triplicate the navigation destinations ('Bag', 'Sessions', 'Account'), their respective icons, and indices. Furthermore, `VirtualBagScreen` relies on hardcoded magic integer indices (0, 1, 2) when switching views, guarding fab visibility, and routing to settings. Source: Epic 5 retro action item 2 (`epic-5-retro-item-2-consolidate-navigation-destinations`).

**Approach:** Extract a shared `AppNavigationDestination` enum in `string_theory_flutter/lib/widgets/bag/app_navigation_destination.dart` defining the destinations (`bag`, `sessions`, `account`) with their labels and icons, plus factory/converter helpers to generate `BottomNavigationBarItem`, `NavigationRailDestination`, and `NavigationDrawerDestination`. Refactor `BagBottomNav`, `BagNavigationRail`, `BagNavigationDrawer`, and `VirtualBagScreen` to consume `AppNavigationDestination`, add dedicated unit/widget tests for the model, and mark action item 2 done in `sprint-status.yaml`.

</frozen-after-approval>

## Implementation Notes

- Extracted `AppNavigationDestination` enum into `string_theory_flutter/lib/widgets/bag/app_navigation_destination.dart` with destinations `bag`, `sessions`, and `account`, each carrying canonical `label` and `icon` properties.
- Added converter methods `toBottomNavigationBarItem()`, `toNavigationRailDestination()`, and `toNavigationDrawerDestination()` directly on the enum.
- Added `AppNavigationDestination.fromIndex(int index)` providing safe, bounds-checked reverse lookup from raw Flutter tap indices.
- Refactored `BagBottomNav`, `BagNavigationRail`, and `BagNavigationDrawer` to dynamically map their items from `AppNavigationDestination.values`.
- Encapsulated `BagNavigationDrawer._borderDecoration` as private.
- Refactored `VirtualBagScreen`:
  - Initialized `_navIndex = AppNavigationDestination.bag.index`.
  - Used `AppNavigationDestination.fromIndex(index)` and exhaustive `switch` pattern matching in `_onNavigationTapped` to safely handle route navigation and state updates.
  - Used `switch (AppNavigationDestination.fromIndex(_navIndex))` for content selection between `SessionsPlaceholder` and bag body.
  - Replaced magic integer checks for FAB visibility and auto-assignment sheet visibility with enum indices.
- Added comprehensive unit and widget tests:
  - `string_theory_flutter/test/widgets/app_navigation_destination_test.dart` verifying canonical values, index lookups, and widget conversions.
  - `string_theory_flutter/test/widgets/bag_bottom_nav_test.dart` verifying label rendering and tapped index dispatches.
  - `string_theory_flutter/test/widgets/bag_navigation_rail_test.dart` verifying label rendering and tapped index dispatches.
  - Updated `string_theory_flutter/test/widgets/bag_navigation_drawer_test.dart` to assert indices and labels via `AppNavigationDestination`.
- Marked `epic-5-retro-item-2-consolidate-navigation-destinations` as `done` in `_bmad-output/implementation-artifacts/sprint-status.yaml`.
- Verified `dart analyze` (0 issues), `dart format` (clean), 375 Flutter tests passing, and 99 Server tests passing.

## Review Triage Log

- `VirtualBagScreen` retains primitive state `int _navIndex = 0`: medium, patched (initialized with `AppNavigationDestination.bag.index` and typed with bounds checks).
- Missing index-to-enum reverse lookup in `AppNavigationDestination`: medium, patched (added `static AppNavigationDestination? fromIndex(int index)`).
- Fragile binary fallback rendering in `VirtualBagScreen`: low, patched (switched over `AppNavigationDestination.fromIndex(_navIndex)`).
- Missing bounds validation in `_onNavigationTapped`: low, patched (validated via `fromIndex(index)` before state mutation).
- Absence of selected/active icon support: low, rejected (the app design uses uniform icons for all destinations; active state is indicated via volt theme color/indicator).
- Missing widget keys and accessibility tooltips on generated destinations: low, rejected (parent widgets carry existing test keys; locators use text matchers consistent with existing suite).
- Domain model mixes widget instantiation and allocates per build: low, rejected (Flutter navigation items are lightweight immutable view descriptors built per frame).
- `app_navigation_destination_test.dart` uses `testWidgets` unnecessarily: low, patched (converted conversion checks to plain `test`).
- Missing widget unit tests for `BagBottomNav` and `BagNavigationRail`: low, patched (created dedicated widget tests for both).
- Existing drawer tests hardcode magic strings and integers: low, patched (updated `bag_navigation_drawer_test.dart` to assert via `AppNavigationDestination`).
- Unnecessary public exposure of `borderDecoration` in `BagNavigationDrawer`: low, patched (made private `_borderDecoration`).
- Spec status desynchronization and blank implementation notes: false (spec status and notes are finalized at the conclusion of the oneshot run).
