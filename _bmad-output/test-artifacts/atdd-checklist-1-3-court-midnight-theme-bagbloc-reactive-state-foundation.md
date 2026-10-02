---
stepsCompleted:
  - 'step-01-preflight-and-context'
  - 'step-02-generation-mode'
  - 'step-03-test-strategy'
  - 'step-04c-aggregate'
  - 'step-05-validate-and-complete'
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-10-02'
workflowType: 'testarch-atdd'
storyId: '1.3'
storyKey: '1-3-court-midnight-theme-bagbloc-reactive-state-foundation'
storyFile: '_bmad-output/planning-artifacts/epics.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-1-3-court-midnight-theme-bagbloc-reactive-state-foundation.md'
generatedTestFiles:
  - 'string_theory_flutter/test/court_midnight_theme_test.dart'
  - 'string_theory_flutter/test/bag_bloc_test.dart'
inputDocuments:
  - '_bmad-output/planning-artifacts/epics.md'
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
    idSource: 'generated'
    text: 'Flutter ThemeData configured with Court Midnight visual tokens (graphite canvas #121516, card surface #1A1E20, border #2A3034, electric volt highlight #C6F10E, Barlow Condensed headings and Inter body per DESIGN.md)'
  - id: 'AC-2'
    idSource: 'generated'
    text: 'BagBloc state management implementation supporting events (LoadBag, AddRacquet, DeleteRacquet, SetPrimaryRacquet) and immutable states (BagInitial, BagLoading, BagLoaded, BagError)'
  - id: 'AC-3'
    idSource: 'generated'
    text: 'BagBloc dispatches and handles Serverpod client.bag RPC calls (getVirtualBag, createRacquet, deleteRacquet, setPrimary) and emits BagLoaded with updated racquets'
  - id: 'AC-4'
    idSource: 'generated'
    text: 'BagBloc handles RPC failures gracefully by emitting BagError with user-facing error messages while maintaining state resilience'
  - id: 'AC-5'
    idSource: 'generated'
    text: 'bloc_test unit tests cover all BagBloc state transitions (load, add, delete, set primary, error paths) with 100% pass rate'
---

# ATDD Checklist: Story 1.3: Court Midnight Theme & BagBloc Reactive State Foundation

**Date:** 2026-10-02  
**Author:** Francesco  
**Target Stack:** Frontend / Mobile (Flutter 3.x / Dart 3.x / `flutter_bloc` / `google_fonts` / `mocktail`)  
**Story Key:** `1-3-court-midnight-theme-bagbloc-reactive-state-foundation`  
**Primary Test Level:** Unit & State Tests (`bloc_test`, `flutter_test`, `mocktail`)

---

## Story Summary

As a tennis player,  
I want a responsive athletic dark theme and rock-solid state management,  
So that the app feels like a high-performance sports dashboard and never stutters.

**Requirements Covered:** ARCH-4, UX-DR1, UX-DR3

---

## Acceptance Criteria Registry

- **AC-1** (generated): Flutter `ThemeData` configured with Court Midnight visual tokens (graphite canvas `#121516`, card surface `#1A1E20`, border `#2A3034`, electric volt highlight `#C6F10E`, Barlow Condensed headings and Inter body per `DESIGN.md`).
- **AC-2** (generated): `BagBloc` state management implementation supporting events (`LoadBag`, `AddRacquet`, `DeleteRacquet`, `SetPrimaryRacquet`) and immutable states (`BagInitial`, `BagLoading`, `BagLoaded`, `BagError`).
- **AC-3** (generated): `BagBloc` dispatches and handles Serverpod `client.bag` RPC calls (`getVirtualBag`, `createRacquet`, `deleteRacquet`, `setPrimary`) and emits `BagLoaded` with updated racquets.
- **AC-4** (generated): `BagBloc` handles RPC failures gracefully by emitting `BagError` with user-facing error messages while maintaining state resilience.
- **AC-5** (generated): `bloc_test` unit tests cover all `BagBloc` state transitions (load, add, delete, set primary, error paths) with 100% pass rate.

---

## Loaded Context & Preflight Status

- **Detected Stack:** Fullstack (Mobile client `string_theory_flutter` + Serverpod backend `string_theory_server`), target scope: `frontend` (`string_theory_flutter`).
- **State Management & Test Harness:** `flutter_bloc: ^9.1.1`, `bloc_test: ^10.0.0`, `mocktail: ^1.0.5`, `equatable: ^3.0.0`.
- **Visual System Reference:** `_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/DESIGN.md` (Court Midnight: `#121516` canvas, `#1A1E20` surface, `#C6F10E` volt accent, `#2A3034` borders).
- **Backend RPC Surface:** `client.bag` endpoints generated in `string_theory_client` (`getVirtualBag`, `createRacquet`, `setPrimary`, `deleteRacquet`).

---

## Generation Mode Selection

- **Selected Mode:** AI Generation
- **Rationale:** Story 1.3 focuses on foundational presentation tokens (`ThemeData` styling) and reactive BLoC state management (`BagBloc` events and state transitions) driven by mockable Serverpod client RPCs. Browser recording is not applicable to Flutter mobile/unit test suites.

---

## Test Strategy & Scenarios Mapping

| Criterion | Level | Priority | Scenario Description | Primary Red Failure Point |
| :--- | :--- | :--- | :--- | :--- |
| **AC-1** | Unit (Theme) | P0 | `ThemeData` configuration matches Court Midnight visual palette and typography | `theme.scaffoldBackgroundColor` does not equal `Color(0xFF121516)` |
| **AC-2** | Unit (BLoC) | P0 | `BagBloc` event & immutable state hierarchy validation | Initial state does not match `BagInitial()` |
| **AC-3** | Unit (BLoC) | P0 | `LoadBag` triggers `client.bag.getVirtualBag()` and emits `[BagLoading, BagLoaded]` | States emitted do not transition to `BagLoaded` |
| **AC-4** | Unit (BLoC) | P0 | RPC failure on `getVirtualBag()` emits `[BagLoading, BagError]` safely | Unhandled exception crashes bloc instead of emitting `BagError` |
| **AC-5** | Unit (BLoC) | P0 | `AddRacquet`, `DeleteRacquet`, and `SetPrimaryRacquet` transitions complete | Event handlers not registered or emit incorrect sequence |

### Red-Phase Isolation Guarantees

1. **Criterion-Defining Assertions**: Each test scaffold targets the exact newly promised property first (e.g. background color `#121516` for AC-1, initial state `BagInitial` for AC-2, state emission for AC-3/4).
2. **Serverpod RPC Mocking**: Scaffolds utilize `mocktail` (`MockClient` and `MockEndpointBag`) to isolate state tests from live server connections.
3. **Equatability & Immutability**: All states and events extend `Equatable` to ensure deterministic stream emissions and state equality.

---

## Red-Phase Test Scaffolds Created

### Flutter Theme Acceptance Test (1 test)

**File:** `string_theory_flutter/test/court_midnight_theme_test.dart`

- 🔴 **Test:** `[P0] AC-1 should configure ThemeData with Court Midnight visual tokens and typography`
  - **Status:** RED (scaffolded with `test.skip()`)
  - **Criterion:** AC-1 (Court Midnight palette `#121516`, `#1A1E20`, `#2A3034`, `#C6F10E` + Barlow Condensed / Inter)
  - **First Failure Point:** `theme.scaffoldBackgroundColor` returns default dark grey instead of `#121516`.

### BagBloc Acceptance Tests (4 tests)

**File:** `string_theory_flutter/test/bag_bloc_test.dart`

- 🔴 **Test:** `[P0] AC-2 should define BagBloc events and initial immutable state hierarchy`
  - **Status:** RED (scaffolded with `test.skip()`)
  - **Criterion:** AC-2 (`BagBloc` events and immutable state hierarchy)
  - **First Failure Point:** Event/state classes or initial state hierarchy mismatch.
- 🔴 **Test:** `[P0] AC-3 should dispatch Serverpod client.bag RPC calls and emit BagLoaded with updated racquets`
  - **Status:** RED (scaffolded with `test.skip()`)
  - **Criterion:** AC-3 (`client.bag` RPC handling and `BagLoaded` emission)
  - **First Failure Point:** `LoadBag` handler does not emit `[BagLoading, BagLoaded]`.
- 🔴 **Test:** `[P0] AC-4 should handle RPC failures gracefully by emitting BagError with user-facing error messages`
  - **Status:** RED (scaffolded with `test.skip()`)
  - **Criterion:** AC-4 (Resilient error handling emitting `BagError`)
  - **First Failure Point:** Unhandled exception thrown instead of emitting `BagError`.
- 🔴 **Test:** `[P0] AC-5 should verify comprehensive bloc_test coverage across AddRacquet, DeleteRacquet, and SetPrimaryRacquet transitions`
  - **Status:** RED (scaffolded with `test.skip()`)
  - **Criterion:** AC-5 (Full transition coverage across add, delete, set primary)
  - **First Failure Point:** Action handlers for mutations not implemented.

---

## TDD Red-Phase Compliance Summary

- **Total Scaffolds:** 5 tests across 2 files
- **All Tests Skipped:** YES (`test.skip(...)` with `skip: 'ATDD RED PHASE: ...'`)
- **Criterion Mapping:** Strict 1:1 mapping for all 5 acceptance criteria (AC-1 through AC-5)
- **First Failure Point Isolated:** Each test asserts the exact newly promised property before secondary checks
- **Syntax & Type Check:** Verified with `dart analyze` (0 issues across workspace)
- **Test Runner Verification:** Verified with `flutter test` (14 passing existing tests, 5 skipped scaffolds, 0 failed, 0 errors)

---

## Next Steps: Task-by-Task Implementation & Activation

During implementation of Story 1.3:

1. **Step 1 (AC-1):** Implement `CourtMidnightTheme.themeData` in `string_theory_flutter/lib/theme/court_midnight_theme.dart`:
   - Map color tokens (`#121516`, `#1A1E20`, `#2A3034`, `#C6F10E`).
   - Configure `GoogleFonts.barlowCondensedTextTheme()` for headlines and `GoogleFonts.interTextTheme()` for body.
   - Wire into `main.dart` `MaterialApp.theme`.
   - Un-skip AC-1 in `court_midnight_theme_test.dart` and verify green.
2. **Step 2 (AC-2):** Finalize `BagEvent` and `BagState` models in `string_theory_flutter/lib/bloc/`:
   - Verify props, equality, and immutable structure.
   - Un-skip AC-2 in `bag_bloc_test.dart` and verify green.
3. **Step 3 (AC-3, AC-4, AC-5):** Implement `BagBloc` event handlers in `string_theory_flutter/lib/bloc/bag_bloc.dart`:
   - Wire `client.bag.getVirtualBag()`, `createRacquet()`, `setPrimary()`, and `deleteRacquet()`.
   - Wrap RPC calls in robust try/catch emitting `BagError(message)` on failure.
   - Un-skip AC-3, AC-4, and AC-5 in `bag_bloc_test.dart` sequentially to verify all green!

---

## Validation & Completion Summary

- **Workflow Status:** COMPLETE ✅
- **Story ID:** `1.3`
- **Story Key:** `1-3-court-midnight-theme-bagbloc-reactive-state-foundation`
- **Story File:** `_bmad-output/planning-artifacts/epics.md`
- **ATDD Checklist:** `_bmad-output/test-artifacts/atdd-checklist-1-3-court-midnight-theme-bagbloc-reactive-state-foundation.md`
- **Generated Test Scaffolds:**
  - `string_theory_flutter/test/court_midnight_theme_test.dart` (1 red-phase test scaffold for AC-1)
  - `string_theory_flutter/test/bag_bloc_test.dart` (4 red-phase test scaffolds for AC-2, AC-3, AC-4, AC-5)
- **TDD Compliance:** 100% (All 5 criteria have isolated, red-phase skipped tests asserting expected Flutter theme and BLoC behavior)
- **Analyzer Status:** Clean (`dart analyze` passes with 0 issues)
- **Test Runner Status:** Clean (`flutter test` reports 14 passed, 5 skipped, 0 failures)
- **Next Recommended Workflow:** `/bmad-build go with Story 1.3` to implement Court Midnight theme and BagBloc reactive state.
