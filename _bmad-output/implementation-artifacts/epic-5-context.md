# Epic 5 Context: Hackathon Polish, Multi-Platform Adaptations & Judge Showcase Controls

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Enable hackathon judges and web testers to evaluate the complete String Theory system seamlessly across mobile, tablet, and desktop/web surfaces with responsive adaptive layouts (NavigationRail on tablet, persistent drawer on desktop/web, and responsive 1/2/3-column card grids), keyboard shortcuts (L, N, S, Esc), responsive mouse hover states, an end-to-end judge showcase verification walkthrough under 90 seconds, and headless CI integration test automation with Patrol.

## Stories

- Story 5.1: Multi-Platform Responsive Layout (NavigationRail & Desktop Grid)
- Story 5.2: Keyboard Shortcuts & Desktop Mouse Hover States
- Story 5.3: End-to-End Demo Script & Verification Walkthrough
- Story 5.4: Patrol Headless End-to-End Test Automation in CI

## Requirements & Constraints

- **Responsive Adaptive Layouts (UX-DR3, NFR-1):**
  - Compact (<600dp: Mobile): Touch-first bottom navigation bar and single-column racquet card list/grid.
  - Medium (600dp - 1024dp: Tablet/iPad): Left-side `NavigationRail` and 2-column racquet card grid.
  - Expanded (>1024dp: Desktop/Web): Persistent side navigation drawer and 3-column racquet card grid.
- **Adaptive Modal Presentations:** Bottom sheets on mobile, centered dialog modals on desktop/web.
- **Keyboard Shortcuts & Accelerators (UX-DR6):** `L` for Log Session, `N` for New Racquet, `S` for Simulate Workout, `Esc` to close active modal dialogs.
- **Mouse Hover Micro-interactions:** Cards elevate slightly with brighter border glow on cursor hover.
- **Fast Judge Walkthrough (SM-3, NFR-3):** 100% deterministic, repeatable end-to-end demo completing in <90 seconds without regressions across client and server.
- **Headless CI Verification (TEST-2, NFR-8):** Automated Patrol integration test suite executing headlessly on PRs/commits to `main`.

## Technical Decisions

- **Responsive Layout Architecture:**
  - Leverage `LayoutBuilder` / `MediaQuery` breakpoints (compact <600dp, medium 600-1024dp, expanded >1024dp).
  - Scaffold wrapper providing adaptive shell navigation (`NavigationBar` vs `NavigationRail` vs persistent drawer).
  - Responsive racquet grid wrapping cards using `SliverGrid` / `GridView` with dynamic `crossAxisCount` (1 for mobile, 2 for tablet, 3 for desktop) or responsive container max-width constraints.
- **Keyboard Shortcut Handling:**
  - Flutter `Shortcuts` and `Actions` or `KeyboardListener` / `HardwareKeyboard` handling global key presses (L, N, S, Esc) without conflicting with active text input fields.
- **Patrol & Testing Infrastructure:**
  - Automated Patrol E2E tests in `string_theory_flutter/integration_test` running headlessly via CI workflow.

## UX & Interaction Patterns

- **Three Breakpoint Tiers:**
  - Compact (<600dp): BottomNavigationBar, full-width cards, modal bottom sheet for actions.
  - Medium (600-1024dp): NavigationRail, 2-column grid, centered or side modal presentation.
  - Expanded (>1024dp): Extended side navigation rail/drawer, 3-column grid, centered modal dialogs.
- **Desktop Hover & Polish:** Subtle hover elevation and border glow enhancement (`courtGreenGlow` / `courtGreenAccent`) on interactive cards.

## Cross-Story Dependencies

- Story 5.1 provides the responsive scaffold and multi-column grid foundation that all screens (VirtualBagScreen, SessionHistory, RacquetDetailScreen) utilize.
- Story 5.2 builds on top of the desktop/web layout by wiring keyboard accelerators and cursor hover states.
- Story 5.3 documents and verifies the end-to-end judge walkthrough across the responsive layout and features built in Epics 1-5.
- Story 5.4 automates the E2E verification in CI via Patrol.
