---
stepsCompleted:
  - 'step-01-preflight-and-context'
  - 'step-02-generation-mode'
  - 'step-03-test-strategy'
  - 'step-04c-aggregate'
  - 'step-05-validate-and-complete'
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-10-04'
workflowType: 'testarch-atdd'
storyId: '1.5'
storyKey: '1-5-virtual-bag-responsive-screen-instant-demo-bag-seeder'
storyFile: '_bmad-output/planning-artifacts/epics.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-1-5-virtual-bag-responsive-screen-instant-demo-bag-seeder.md'
generatedTestFiles:
  - 'string_theory_flutter/test/virtual_bag_screen_test.dart'
inputDocuments:
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/PRD.md'
  - '_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/DESIGN.md'
  - '_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/EXPERIENCE.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/ARCHITECTURE-SPINE.md'
  - '_bmad/tea/config.yaml'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/data-factories.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/component-tdd.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-quality.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-healing-patterns.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/selector-resilience.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/timing-debugging.md'
acceptanceCriteria:
  - id: 'AC-1'
    idSource: 'supplied'
    text: 'Given a user opens the Virtual Bag screen, when no racquets exist, then an empty state appears with [+ Add Racquet] and a prominent [⚡ Load Sample Bag] button'
  - id: 'AC-2'
    idSource: 'supplied'
    text: 'Tapping [+ Add Racquet] on the empty state opens the AddRacquetModal'
  - id: 'AC-3'
    idSource: 'supplied'
    text: 'Tapping [⚡ Load Sample Bag] seeds 3 realistic racquets (Wilson Blade @ 76% green, Babolat Pure Drive @ 58% amber, Head Radical @ 34% red) via Serverpod and updates the bag'
  - id: 'AC-4'
    idSource: 'supplied'
    text: 'On mobile screens (<600dp width), racquets display as a single-column card list with a bottom navigation bar'
  - id: 'AC-5'
    idSource: 'supplied'
    text: 'On tablet/desktop screens (>=600dp width), racquets display in an adaptive 2-column grid with NavigationRail'
---

# ATDD Checklist: Story 1.5: Virtual Bag Responsive Screen & Instant Demo Bag Seeder

**Date:** 2026-10-04  
**Author:** Murat (Master Test Architect)  
**Target Stack:** Frontend / Mobile (Flutter 3.x / Dart 3.x / `flutter_bloc` / `mocktail`)  
**Story Key:** `1-5-virtual-bag-responsive-screen-instant-demo-bag-seeder`  
**Primary Test Level:** Component, Widget, and Responsive Layout Tests (`flutter_test`, `mocktail`)

---

## Story Summary

As a hackathon judge or new player,  
I want to see my racquets in a responsive grid and have an instant "Sample Bag" button on empty state,  
So that I can test the full app immediately without typing mock data.

**Requirements Covered:** FR-5, UX-DR3

---

## Acceptance Criteria Registry

- **AC-1** (supplied): Given a user opens the Virtual Bag screen, when no racquets exist, then an empty state appears with `[+ Add Racquet]` and a prominent `[⚡ Load Sample Bag]` button.
- **AC-2** (supplied): Tapping `[+ Add Racquet]` on the empty state opens the `AddRacquetModal`.
- **AC-3** (supplied): Tapping `[⚡ Load Sample Bag]` seeds 3 realistic racquets (Wilson Blade @ 76% green, Babolat Pure Drive @ 58% amber, Head Radical @ 34% red) via Serverpod and updates the bag.
- **AC-4** (supplied): On mobile screens (<600dp width), racquets display as a single-column card list with a bottom navigation bar.
- **AC-5** (supplied): On tablet/desktop screens (>=600dp width), racquets display in an adaptive 2-column grid with `NavigationRail`.

---

## Loaded Context & Preflight Status

- **Detected Stack:** Fullstack (Mobile client `string_theory_flutter` + Serverpod backend `string_theory_server`), target scope: `frontend` (`string_theory_flutter`).
- **State Management & Test Harness:** `flutter_bloc: ^9.1.1`, `mocktail: ^1.0.5`, `equatable: ^3.0.0`, `flutter_test`.
- **Modal Component:** `AddRacquetModal` in `string_theory_flutter/lib/widgets/add_racquet_modal.dart` (implemented in Story 1.4).
- **Responsive Guidelines:** `EXPERIENCE.md` Section 1: Mobile (<600dp) uses bottom navigation bar + 1-column card list; Tablet (>=600dp) uses `NavigationRail` + 2-column grid.

---

## Generation Mode Selection

- **Selected Mode:** AI Generation
- **Rationale:** Flutter responsive layout and widget-level TDD test suites operate via headless `WidgetTester` (`flutter_test`) with simulated view constraints (`tester.view.physicalSize`). Browser recording is not applicable to Flutter mobile test suites.

---

## Test Strategy & Scenarios Mapping

| Criterion | Level | Priority | Scenario Description | Primary Red Failure Point |
| :--- | :--- | :--- | :--- | :--- |
| **AC-1** | Widget | P0 | Empty state displays `[+ Add Racquet]` and `[⚡ Load Sample Bag]` | `find.byKey(VirtualBagScreen.keyEmptyState)` finds nothing in stub widget |
| **AC-2** | Widget | P0 | Tapping `[+ Add Racquet]` opens `AddRacquetModal` bottom sheet | `find.byType(AddRacquetModal)` finds nothing after button tap |
| **AC-3** | Integration | P0 | Tapping `[⚡ Load Sample Bag]` dispatches `SeedSampleBag` to `BagBloc` | `verify(() => mockBagBloc.add(SeedSampleBag()))` fails |
| **AC-4** | Responsive | P0 | Viewport width <600dp renders single-column list & bottom nav bar | `keyRacquetList` or `keyBottomNav` not found; incorrect responsive layout |
| **AC-5** | Responsive | P0 | Viewport width >=600dp renders 2-column grid & `NavigationRail` | `keyRacquetGrid` or `keyNavigationRail` not found; desktop layout missing |

---

## Red-Phase Isolation Guarantees

1. **Criterion-Defining Assertions**: Each test targets the exact newly promised property first (e.g. empty state visibility for AC-1, modal presence for AC-2, `SeedSampleBag` event dispatch for AC-3, list vs grid presence for AC-4/5).
2. **BLoC Mocking with Mocktail**: `MockBagBloc` stubs `state` and `stream` to control `BagLoaded([])` vs populated bag without network latency.
3. **Viewport Size Simulation**: `tester.view.physicalSize` and `devicePixelRatio` deterministically simulate mobile (<600dp) and tablet/desktop (>=600dp) environments with `addTearDown` cleanup.
4. **Red-Phase Skipped Scaffolds**: Tests use `test.skipWidgets(...)` (`skip: true`) to maintain clean CI builds until unskipped in TDD red-green cycle.

---

## Red-Phase Test Scaffolds Created

### VirtualBagScreen Acceptance Tests (5 tests)

**File:** `string_theory_flutter/test/virtual_bag_screen_test.dart`

- 🔴 **Test:** `[P0] AC-1 should render empty state with Add Racquet and Load Sample Bag buttons when bag is empty`
  - **Status:** RED (scaffolded with `test.skipWidgets()`)
  - **Criterion:** AC-1 (Empty state rendering)
  - **First Failure Point:** `VirtualBagScreen.keyEmptyState` not found in stub widget.
- 🔴 **Test:** `[P0] AC-2 should open AddRacquetModal when [+ Add Racquet] is tapped on empty state`
  - **Status:** RED (scaffolded with `test.skipWidgets()`)
  - **Criterion:** AC-2 (Modal trigger from empty state)
  - **First Failure Point:** `AddRacquetModal` not rendered after tapping add button.
- 🔴 **Test:** `[P0] AC-3 should dispatch SeedSampleBag event to BagBloc when [⚡ Load Sample Bag] is tapped`
  - **Status:** RED (scaffolded with `test.skipWidgets()`)
  - **Criterion:** AC-3 (Sample bag seeding dispatch)
  - **First Failure Point:** `mockBagBloc.add(SeedSampleBag())` never called.
- 🔴 **Test:** `[P0] AC-4 should display single-column card list with bottom navigation bar on mobile screen width (<600dp)`
  - **Status:** RED (scaffolded with `test.skipWidgets()`)
  - **Criterion:** AC-4 (Mobile single-column layout with bottom nav)
  - **First Failure Point:** `VirtualBagScreen.keyRacquetList` not rendered in mobile view.
- 🔴 **Test:** `[P0] AC-5 should display adaptive 2-column grid with NavigationRail on tablet/desktop screen width (>=600dp)`
  - **Status:** RED (scaffolded with `test.skipWidgets()`)
  - **Criterion:** AC-5 (Tablet 2-column grid layout with NavigationRail)
  - **First Failure Point:** `VirtualBagScreen.keyRacquetGrid` not rendered in tablet view.

---

## TDD Red-Phase Compliance Summary

- **Total Scaffolds:** 5 tests in `string_theory_flutter/test/virtual_bag_screen_test.dart`
- **All Tests Skipped:** YES (`skip: true` pending Story 1.5 implementation)
- **Criterion Mapping:** Strict 1:1 mapping for all 5 acceptance criteria (AC-1 through AC-5)
- **First Failure Point Isolated:** Each test asserts the exact newly promised property before secondary checks
- **Syntax & Type Check:** Verified with `dart analyze` (0 issues across workspace)

---

## Next Steps: Task-by-Task Implementation & Activation

During implementation of Story 1.5:

1. **Step 1 (AC-1 & AC-2):** Build the empty state widget in `VirtualBagScreen` with Court Midnight theme styling:
   - Render `[+ Add Racquet]` button wiring `AddRacquetModal.show(context)`.
   - Render `[⚡ Load Sample Bag]` button.
   - Un-skip AC-1 and AC-2 in `virtual_bag_screen_test.dart` and verify green.
2. **Step 2 (AC-3):** Implement `SeedSampleBag` handler in `BagBloc`:
   - Call Serverpod to create/seed the 3 realistic racquets:
     1. Wilson Blade 98 @ 76% health (Luxilon ALU Power, 5h played / 20h max).
     2. Babolat Pure Drive @ 58% health (Babolat RPM Blast, 9h played / 20h max).
     3. Head Radical MP @ 34% health (Head Velocity MLT, 25h played / 35h max).
   - Wire `[⚡ Load Sample Bag]` to dispatch `SeedSampleBag()`.
   - Un-skip AC-3 in `virtual_bag_screen_test.dart` and verify green.
3. **Step 3 (AC-4 & AC-5):** Build responsive layout in `VirtualBagScreen` using `LayoutBuilder` / `MediaQuery`:
   - Mobile (<600dp): single-column list view with bottom navigation bar.
   - Tablet/desktop (>=600dp): 2-column card grid with `NavigationRail`.
   - Wire `VirtualBagScreen` into `MyHomePage` body in `main.dart`.
   - Un-skip AC-4 and AC-5 in `virtual_bag_screen_test.dart` and verify all green!

---

## Validation & Completion Summary

- **Workflow Status:** COMPLETE ✅
- **Story ID:** `1.5`
- **Story Key:** `1-5-virtual-bag-responsive-screen-instant-demo-bag-seeder`
- **Story File:** `_bmad-output/planning-artifacts/epics.md`
- **ATDD Checklist:** `_bmad-output/test-artifacts/atdd-checklist-1-5-virtual-bag-responsive-screen-instant-demo-bag-seeder.md`
- **Generated Test Scaffolds:**
  - `string_theory_flutter/test/virtual_bag_screen_test.dart` (5 red-phase acceptance tests)
- **TDD Compliance:** 100% (All 5 acceptance criteria mapped, isolated, and verified)
- **Analyzer Status:** Clean (0 errors across Flutter client and Serverpod server)
- **Next Recommended Workflow:** `/bmad-build` to implement Story 1.5 (`Virtual Bag Responsive Screen & Instant Demo Bag Seeder`).
