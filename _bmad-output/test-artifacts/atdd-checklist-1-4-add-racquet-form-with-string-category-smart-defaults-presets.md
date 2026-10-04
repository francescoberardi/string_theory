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
storyId: '1.4'
storyKey: '1-4-add-racquet-form-with-string-category-smart-defaults-presets'
storyFile: '_bmad-output/planning-artifacts/epics.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-1-4-add-racquet-form-with-string-category-smart-defaults-presets.md'
generatedTestFiles:
  - 'string_theory_flutter/test/add_racquet_modal_test.dart'
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
    text: 'Given a user opens the [Add Racquet] modal, the form renders with required inputs (Racquet Nickname/Model, String Material Category, String Brand, String Model, Tension, Stringing Date, Max Rated Hours, 1-tap Preset, and Submit CTA)'
  - id: 'AC-2'
    idSource: 'supplied'
    text: 'When the user selects String Material Category Co-Polyester, Manufacturer Max Hours automatically pre-populates to 20.0 hrs'
  - id: 'AC-3'
    idSource: 'supplied'
    text: 'Selecting Multifilament pre-populates to 35.0 hrs, Synthetic Gut to 30.0 hrs, and Natural Gut to 50.0 hrs (all user-editable)'
  - id: 'AC-4'
    idSource: 'supplied'
    text: 'A 1-tap preset button [Popular Poly: Babolat RPM Blast @ 52 lbs] fills frame, string model, and tension instantly'
  - id: 'AC-5'
    idSource: 'supplied'
    text: 'Submitting the form validates inputs, builds AddRacquet event, and dispatches it to BagBloc'
---

# ATDD Checklist: Story 1.4: Add Racquet Form with String Category Smart Defaults & Presets

**Date:** 2026-10-04  
**Author:** Murat (Master Test Architect)  
**Target Stack:** Frontend / Mobile (Flutter 3.x / Dart 3.x / `flutter_bloc` / `mocktail`)  
**Story Key:** `1-4-add-racquet-form-with-string-category-smart-defaults-presets`  
**Primary Test Level:** Component & Widget Integration Tests (`flutter_test`, `mocktail`)

---

## Story Summary

As a tennis player,  
I want to add a racquet with automated smart defaults and popular presets,  
So that I don't have to look up manufacturer play hours or string technicalities.

**Requirements Covered:** FR-4, UX-DR1

---

## Acceptance Criteria Registry

- **AC-1** (supplied): Given a user opens the `[Add Racquet]` modal, the form renders with required inputs (Racquet Nickname/Model, String Material Category, String Brand, String Model, Tension, Stringing Date, Max Rated Hours, 1-tap Preset, and Submit CTA).
- **AC-2** (supplied): When the user selects String Material Category `Co-Polyester` (`coPoly`), Manufacturer Max Hours automatically pre-populates to `20.0 hrs`.
- **AC-3** (supplied): Selecting `Multifilament` (`multifilament`) pre-populates to `35.0 hrs`, `Synthetic Gut` (`syntheticGut`) to `30.0 hrs`, and `Natural Gut` (`naturalGut`) to `50.0 hrs` (all user-editable).
- **AC-4** (supplied): A 1-tap preset button `[Popular Poly: Babolat RPM Blast @ 52 lbs]` fills frame, string model, tension, and default max hours instantly.
- **AC-5** (supplied): Submitting the form validates inputs, builds `AddRacquet` event, and dispatches it to `BagBloc`.

---

## Loaded Context & Preflight Status

- **Detected Stack:** Fullstack (Mobile client `string_theory_flutter` + Serverpod backend `string_theory_server`), target scope: `frontend` (`string_theory_flutter`).
- **State Management & Test Harness:** `flutter_bloc: ^9.1.1`, `mocktail: ^1.0.5`, `equatable: ^3.0.0`, `flutter_test`.
- **Form & Design Tokens:** `CourtMidnightTheme` (`#121516` canvas, `#1A1E20` surface, `#2A3034` borders, `#C6F10E` electric volt accent).
- **Event Contract:** `AddRacquet` in `string_theory_flutter/lib/bloc/bag_event.dart` requiring `name`, `materialCategory`, `stringBrand`, `stringModel`, `tension`, `maxRatedHours`, `stringingDate`.

---

## Generation Mode Selection

- **Selected Mode:** AI Generation
- **Rationale:** Flutter component and widget-level TDD test suites operate via headless `WidgetTester` (`flutter_test`) and mocktail BLoC mocking. Browser recording is not applicable to Flutter mobile test suites.

---

## Test Strategy & Scenarios Mapping

| Criterion | Level | Priority | Scenario Description | Primary Red Failure Point |
| :--- | :--- | :--- | :--- | :--- |
| **AC-1** | Widget | P0 | `AddRacquetModal` renders all required input fields and controls | `find.byKey(AddRacquetModal.keyNameField)` finds nothing in stub modal |
| **AC-2** | Widget | P0 | Selecting `Co-Polyester` category sets Max Hours to `20.0 hrs` | Max hours text field does not update or pre-fill with `'20.0'` |
| **AC-3** | Widget | P0 | Selecting Multifilament (`35h`), Synthetic Gut (`30h`), Natural Gut (`50h`) updates hours and allows manual edit | Dropdown selection changes do not reflect hours; manual input rejected |
| **AC-4** | Widget | P0 | Tapping `[Popular Poly]` preset populates frame, string, tension, and hours | Preset button tap does not populate form text controllers |
| **AC-5** | Integration | P0 | Form submit dispatches `AddRacquet` event to `BagBloc` with valid payload | `verify(() => mockBagBloc.add(...))` never called or has wrong arguments |

---

## Red-Phase Isolation Guarantees

1. **Criterion-Defining Assertions**: Each test targets the exact newly promised property first (e.g. key existence for AC-1, pre-populated text `'20.0'` for AC-2, state changes for AC-3, preset text values for AC-4, and event verification for AC-5).
2. **BLoC Mocking with Mocktail**: `MockBagBloc` intercepts dispatched events without needing a live Serverpod backend connection.
3. **Red-Phase Skipped Scaffolds**: Tests are created with `skip: true` (`test.skipWidgets(...)`) to maintain a clean build until unskipped in the TDD cycle.
4. **Isolated Stub**: Minimal `AddRacquetModal` stub compiles with 0 analyzer issues while guaranteeing failure on all criterion assertions once unskipped.

---

## Red-Phase Test Scaffolds Created

### AddRacquetModal Acceptance Tests (5 tests)

**File:** `string_theory_flutter/test/add_racquet_modal_test.dart`

- 🔴 **Test:** `[P0] AC-1 should render AddRacquetModal with required racquet and string input fields`
  - **Status:** RED (scaffolded with `test.skipWidgets()`)
  - **Criterion:** AC-1 (Modal input field presence)
  - **First Failure Point:** `AddRacquetModal.keyNameField` not found in stub widget.
- 🔴 **Test:** `[P0] AC-2 should pre-populate Manufacturer Max Hours to 20.0 hrs when Co-Polyester category is selected`
  - **Status:** RED (scaffolded with `test.skipWidgets()`)
  - **Criterion:** AC-2 (Co-Poly 20.0 hrs smart default)
  - **First Failure Point:** `Category` selection does not update `maxHours` field to `'20.0'`.
- 🔴 **Test:** `[P0] AC-3 should pre-populate Max Hours for Multifilament (35h), Synthetic Gut (30h), Natural Gut (50h) and remain editable`
  - **Status:** RED (scaffolded with `test.skipWidgets()`)
  - **Criterion:** AC-3 (Multifilament, Synth Gut, Natural Gut defaults & manual override)
  - **First Failure Point:** Category dropdown selection changes do not reflect in hours field.
- 🔴 **Test:** `[P0] AC-4 should instantly fill racquet frame, string model, tension, and defaults when Popular Poly preset is tapped`
  - **Status:** RED (scaffolded with `test.skipWidgets()`)
  - **Criterion:** AC-4 (Popular Poly 1-tap preset)
  - **First Failure Point:** Preset button tap does not populate form fields with `Babolat Pure Aero`, `RPM Blast`, `52.0 lbs`.
- 🔴 **Test:** `[P0] AC-5 should validate form inputs and dispatch AddRacquet event to BagBloc upon submission`
  - **Status:** RED (scaffolded with `test.skipWidgets()`)
  - **Criterion:** AC-5 (Form validation and `BagBloc` event dispatch)
  - **First Failure Point:** Submit button does not dispatch `AddRacquet` to `mockBagBloc`.

---

## TDD Red-Phase Compliance Summary

- **Total Scaffolds:** 5 tests in `string_theory_flutter/test/add_racquet_modal_test.dart`
- **All Tests Skipped:** YES (`skip: true` pending Story 1.4 implementation)
- **Criterion Mapping:** Strict 1:1 mapping for all 5 acceptance criteria (AC-1 through AC-5)
- **First Failure Point Isolated:** Each test asserts the exact newly promised property before secondary checks
- **Syntax & Type Check:** Verified with `dart analyze` (0 issues across workspace)

---

## Next Steps: Task-by-Task Implementation & Activation

During implementation of Story 1.4:

1. **Step 1 (AC-1):** Build the `AddRacquetModal` layout and input fields in `string_theory_flutter/lib/widgets/add_racquet_modal.dart` with Court Midnight theme styling.
   - Un-skip AC-1 in `add_racquet_modal_test.dart` and verify green.
2. **Step 2 (AC-2 & AC-3):** Implement category change listener linking `StringCategoryDefaults.maxHours(category)` to the hours `TextEditingController`.
   - Ensure user can manually override the controller text.
   - Un-skip AC-2 and AC-3 in `add_racquet_modal_test.dart` and verify green.
3. **Step 3 (AC-4):** Wire the preset chips (`[Popular Poly: Babolat RPM Blast @ 52 lbs]`) to populate controllers simultaneously.
   - Un-skip AC-4 in `add_racquet_modal_test.dart` and verify green.
4. **Step 4 (AC-5):** Implement form validation and submit action dispatching `AddRacquet` event to `widget.bagBloc ?? context.read<BagBloc>()`.
   - Un-skip AC-5 in `add_racquet_modal_test.dart` and verify all green!

---

## Validation & Completion Summary

- **Workflow Status:** COMPLETE ✅
- **Story ID:** `1.4`
- **Story Key:** `1-4-add-racquet-form-with-string-category-smart-defaults-presets`
- **Story File:** `_bmad-output/planning-artifacts/epics.md`
- **ATDD Checklist:** `_bmad-output/test-artifacts/atdd-checklist-1-4-add-racquet-form-with-string-category-smart-defaults-presets.md`
- **Generated Test Scaffolds:**
  - `string_theory_flutter/test/add_racquet_modal_test.dart` (5 red-phase acceptance tests)
- **TDD Compliance:** 100% (All 5 acceptance criteria mapped, isolated, and verified)
- **Analyzer Status:** Clean (0 errors across Flutter client and Serverpod server)
- **Next Recommended Workflow:** `/bmad-build` to implement Story 1.4 (`Add Racquet Form with String Category Smart Defaults & Presets`).
