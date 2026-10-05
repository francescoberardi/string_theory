---
title: 'Story 5.1: Multi-Platform Responsive Layout (NavigationRail & Desktop Grid)'
type: 'feature'
created: '2026-10-05'
status: 'ready-for-dev'
baseline_commit: 'adcbd5f81d97c524cd9975484001e03af074335f'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-5-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Currently, the Virtual Bag screen only handles a binary breakpoint (<600dp mobile vs >=600dp tablet/desktop), hardcoding a 2-column grid and unextended `NavigationRail`. On desktop and wide browser windows (>1024dp), screen real estate is underutilized with stretched 2-column cards and no persistent navigation drawer.

**Approach:** Implement a 3-tier responsive adaptive layout across mobile (<600dp: touch bottom navigation + 1-column list), tablet (600–1024dp: side `NavigationRail` + 2-column card grid), and desktop/web (>1024dp: persistent side `NavigationDrawer` + 3-column card grid).

## Boundaries & Constraints

**Always:**
- Keep mobile (<600dp) rendering `BagBottomNav` and single-column `ListView` with `keyRacquetList`.
- Render unextended `NavigationRail` (`keyNavigationRail`) with 2-column `GridView` (`keyRacquetGrid`) on medium screens (600dp <= width <= 1024dp).
- Render persistent `BagNavigationDrawer` (`keyNavigationDrawer`) with 3-column `GridView` (`keyRacquetGrid`) on expanded screens (>1024dp).
- Maintain navigation destination parity across all three navigation modes: Bag (0), Sessions (1), and Account/Settings (2).
- Follow Court Midnight dark theme styling (`CourtMidnightTheme.surface`, `primaryVolt`, `surfaceBorder`).

**Never:**
- Do not break existing mobile bottom navigation interactions or tablet tests.
- Do not perform full page reloads or destroy bloc state when resizing between breakpoints.
- Do not alter backend models, endpoints, or database tables.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Mobile viewport (<600dp) | Window width 400dp, height 800dp | Bottom navigation bar (`keyBottomNav`) visible; `keyNavigationRail` and `keyNavigationDrawer` absent; `keyRacquetList` single column rendered. | N/A |
| Tablet viewport (600–1024dp) | Window width 800dp, height 1000dp | Side `NavigationRail` (`keyNavigationRail`) visible; `keyBottomNav` and `keyNavigationDrawer` absent; `keyRacquetGrid` with 2 columns rendered. | N/A |
| Desktop viewport (>1024dp) | Window width 1280dp, height 900dp | Persistent `BagNavigationDrawer` (`keyNavigationDrawer`) visible; `keyBottomNav` and `keyNavigationRail` absent; `keyRacquetGrid` with 3 columns rendered. | N/A |
| Dynamic window resize | User resizes browser window across 600dp and 1024dp thresholds | Layout smoothly transitions between bottom nav, navigation rail, and navigation drawer without resetting active tab or bloc state. | Preserve navigation index and scroll position |
| Empty bag across breakpoints | 0 racquets in bag state across mobile, tablet, desktop | `BagEmptyState` renders properly centered within all layout tiers. | N/A |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Responsive shell managing breakpoint branching (<600dp, 600–1024dp, >1024dp), exposing static widget keys and wiring navigation actions.
- `string_theory_flutter/lib/widgets/bag/bag_navigation_drawer.dart` -- New persistent side navigation drawer widget for desktop/web (>1024dp) with app header branding, styled destinations (Bag, Sessions, Account), and active selection highlight.
- `string_theory_flutter/lib/widgets/bag/bag_racquet_list.dart` -- Adaptive racquet collection displaying 1-column list on mobile, 2-column grid on tablet, and 3-column grid on desktop.
- `string_theory_flutter/lib/widgets/bag/bag_navigation_rail.dart` -- Existing tablet side rail (600–1024dp) destination handler.
- `string_theory_flutter/test/virtual_bag_screen_test.dart` -- Widget test suite verifying all 3 responsive layout tiers, navigation destinations, and card grid columns.

## Tasks & Acceptance

**Execution:**
- [ ] `string_theory_flutter/lib/widgets/bag/bag_navigation_drawer.dart` -- Create persistent side navigation drawer widget with `keyNavigationDrawer`, branded header ("STRING THEORY"), destinations (Bag, Sessions, Account), and `CourtMidnightTheme` styling.
- [ ] `string_theory_flutter/lib/widgets/bag/bag_racquet_list.dart` -- Update `BagRacquetList` to accept `int crossAxisCount` (or dynamically calculate columns: 1 for <600dp, 2 for 600–1024dp, 3 for >1024dp) so desktop renders 3-column cards.
- [ ] `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Update responsive layout logic to branch across 3 breakpoints: mobile (<600dp), tablet (600–1024dp), and desktop (>1024dp) displaying `BagNavigationDrawer` and 3-column grid. Expose `keyNavigationDrawer`.
- [ ] `string_theory_flutter/test/virtual_bag_screen_test.dart` -- Add dedicated widget tests for tablet (800dp) 2-column grid + `keyNavigationRail`, desktop (1280dp) 3-column grid + `keyNavigationDrawer`, and verify bottom nav remains on mobile (<600dp).

**Acceptance Criteria:**
- Given the app running in a browser or desktop window,
- When window width is <600dp,
- Then it renders a touch-friendly bottom navigation bar (`keyBottomNav`) and single-column cards (`keyRacquetList`),
- And when window width is between 600dp and 1024dp, it transforms into a side `NavigationRail` (`keyNavigationRail`) with a 2-column card grid (`keyRacquetGrid`),
- And when window width is >1024dp, it displays an expanded navigation drawer (`keyNavigationDrawer`) and a 3-column card grid (`keyRacquetGrid`).

## Implementation Notes

<!-- Agent-owned. Append-only during implementation. -->

## Design Notes

- **Breakpoint constants**:
  - `kMobileBreakpoint = 600.0`
  - `kDesktopBreakpoint = 1024.0`
- **NavigationDrawer styling**:
  - Container width: 240dp.
  - Background: `CourtMidnightTheme.surface`.
  - Right border: 1px `CourtMidnightTheme.surfaceBorder`.
  - Header: Barlow Condensed title "STRING THEORY" with Volt green tennis ball accent.
  - Items: `NavigationDrawerDestination` with custom icons and Volt highlight on selected item.

## Verification

**Commands:**
- `dart analyze string_theory_flutter` -- expected: 0 issues found
- `dart test test/virtual_bag_screen_test.dart` (in `string_theory_flutter`) -- expected: All widget tests pass
- `dart test` (in `string_theory_flutter`) -- expected: All Flutter unit and widget tests pass
