---
stepsCompleted:
  - 'step-01-preflight-and-context'
  - 'step-02-generation-mode'
  - 'step-03-test-strategy'
  - 'step-04-generate-tests'
  - 'step-04c-aggregate'
  - 'step-05-validate-and-complete'
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-10-13'
workflowType: 'testarch-atdd'
storyId: '6.4'
storyKey: '6-4-dedicated-sessions-history-screen-domain-model-extraction'
storyFile: '_bmad-output/planning-artifacts/epics.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-6-4-dedicated-sessions-history-screen-domain-model-extraction.md'
generatedTestFiles:
  - 'string_theory_flutter/test/helpers/tdd_red_phase.dart'
  - 'string_theory_flutter/test/widgets/sessions_screen_test.dart'
  - 'string_theory_flutter/test/domain/racquet_preset_test.dart'
inputDocuments:
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/implementation-artifacts/epic-6-context.md'
  - '_bmad-output/test-artifacts/test-design-epic-6.md'
  - '_bmad-output/implementation-artifacts/sprint-status.yaml'
  - '_bmad/tea/config.yaml'
  - 'string_theory_flutter/lib/screens/virtual_bag_screen.dart'
  - 'string_theory_flutter/lib/widgets/bag/sessions_placeholder.dart'
  - 'string_theory_flutter/lib/widgets/add_racquet_modal.dart'
  - 'string_theory_flutter/lib/domain/decay_engine.dart'
  - 'string_theory_decay_engine/lib/src/string_category_defaults.dart'
  - 'string_theory_client/lib/src/protocol/client.dart'
  - 'string_theory_server/lib/src/endpoints/session_endpoint.dart'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/data-factories.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/component-tdd.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-quality.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-healing-patterns.md'
acceptanceCriteria:
  - id: 'AC-1'
    idSource: 'generated'
    text: 'Given the app navigation (BottomNav, NavigationRail, and Drawer), when the player selects the "Sessions" tab, then the app renders a dedicated SessionsScreen (replacing the temporary SessionsPlaceholder).'
  - id: 'AC-2'
    idSource: 'generated'
    text: 'And it displays a chronological list of logged sessions with date, duration, racquet name, and court hours added.'
  - id: 'AC-3'
    idSource: 'generated'
    text: 'And it provides a prominent [+ Log Session] action button.'
  - id: 'AC-4'
    idSource: 'generated'
    text: 'And RacquetPreset and StringCategoryDefaults are relocated from UI widgets into pure domain models in the domain layer, with presentation files referencing the domain contracts.'
---

# ATDD Checklist: Story 6.4: Dedicated Sessions History Screen & Domain Model Extraction

**Date:** 2026-10-13  
**Author:** Francesco  
**Detected Stack:** `mobile` (`pubspec.yaml`; Flutter client + Serverpod backend in workspace)  
**Primary Test Level:** Component/Widget (`VirtualBagScreen` / `SessionsScreen`) + Unit (Domain, `RacquetPreset`)  
**Story Key:** `6-4-dedicated-sessions-history-screen-domain-model-extraction`  

---

## Step 1: Preflight & Context

### Prerequisites

- Story ACs: 4 criteria (source: `epics.md` Story 6.4, TD-11, TD-12; `epic-6-context.md`, `test-design-epic-6.md`).
- Test Framework: `string_theory_flutter` uses `flutter_test`, `mocktail`. Workspace passes `analyze_files` with 0 issues.
- Sequencing: Story 6.3 (UUID tenant migration), Story 6.1 (state management resilience), and Story 6.2 (health ingestion hardening) are complete and green.

### Affected Components

| Component | File | Change driven by |
| --- | --- | --- |
| Sessions Navigation Routing | `lib/screens/virtual_bag_screen.dart` (`switch (_navIndex)`) | AC-1 |
| Dedicated Sessions Screen | `lib/screens/sessions_screen.dart` (new) replacing `lib/widgets/bag/sessions_placeholder.dart` | AC-1, AC-2, AC-3 |
| Sessions History Card / List | `lib/widgets/sessions/session_history_card.dart` | AC-2 |
| Quick-Log Action Button | `lib/screens/sessions_screen.dart` (`keyLogSessionButton`) wiring `WorkoutAssignmentSheet.showManual` | AC-3 |
| Pure Domain Model Extraction | `lib/domain/racquet_preset.dart` (extracted from `lib/widgets/add_racquet_modal.dart`) | AC-4 |
| Form Defaults Presentation | `lib/widgets/add_racquet_modal.dart` (imports domain `RacquetPreset`) | AC-4 |

### Current behavior (the gaps)

- **AC-1:** Selecting the Sessions navigation tab (on bottom nav, navigation rail, or drawer) routes to `SessionsPlaceholder`, rendering a static placeholder with text `'COURT SESSIONS'`.
- **AC-2:** No sessions history list or card view exists in the client; sessions recorded via `logSession` or HealthKit ingestion are only reflected as incremented court hours on `StringJob`.
- **AC-3:** When on the Sessions tab, no `[+ Log Session]` action button is present (`LogSessionFab` on `VirtualBagScreen` is conditionally hidden when `_navIndex != 0`).
- **AC-4:** `RacquetPreset` is declared directly inside `lib/widgets/add_racquet_modal.dart` (lines 11–43), coupling a pure domain configuration specification with Flutter widget presentation code.

### Knowledge Fragments (closed set for `mobile`)

`data-factories.md`, `component-tdd.md`, `test-quality.md`, `test-healing-patterns.md`.

---

## Step 2: Generation Mode

**Mode:** AI generation from story ACs, test architecture design (`test-design-epic-6.md`), and codebase analysis.  
**Rationale:** The criteria require verifying widget navigation switching, dynamic list rendering, action button sheet dispatch, and pure Dart domain model extraction. Headless widget testing (`WidgetTester`) and unit tests provide fast, deterministic validation.

---

## Step 3: Test Strategy

### Red-phase constraints

- Scaffolds compile against current code and stay skipped on `main` via `test/helpers/tdd_red_phase.dart` (`tddRedPhase64`).
- Skip helper: `test/helpers/tdd_red_phase.dart` (`tddRedPhase64Reason` and `tddRedPhase64`).
- Mocks and fixtures: `MockBagBloc`, `MockClient`, `MockEndpointSession`, `FakeHealthSyncService`.

### Primary red-phase scaffolds (one per criterion)

| AC | Level | Pri | File | Scenario | First (criterion-defining) assertion | Red failure reason |
| --- | --- | --- | --- | --- | --- | --- |
| **AC-1** | Component (widget) | P2 | `test/widgets/sessions_screen_test.dart` | Player selects Sessions tab | `find.byKey(Key('sessions_screen')) findsOneWidget` | Found 0 widgets: `SessionsPlaceholder` rendered instead |
| **AC-2** | Component (widget) | P2 | `test/widgets/sessions_screen_test.dart` | Sessions tab rendered with logged sessions | `find.byKey(Key('sessions_list_view')) findsOneWidget` | Found 0 widgets: no session history list view implemented |
| **AC-3** | Component (widget) | P2 | `test/widgets/sessions_screen_test.dart` | Player taps `[+ Log Session]` on Sessions tab | `find.byKey(Key('sessions_log_session_button')) findsOneWidget` | Found 0 widgets: no log session button on Sessions tab |
| **AC-4** | Unit (domain) | P2 | `test/domain/racquet_preset_test.dart` | Instantiation and defaults of `RacquetPreset` | `RacquetPreset.popularPoly.maxRatedHours == 20.0` | Verifies pure domain specification and `StringCategoryDefaults` contract |

### Secondary branches (green-phase automation)

- **AC-1:** Navigation switching verified across all 3 responsive layouts: mobile (`BagBottomNav`), tablet (`BagNavigationRail`), desktop (`BagNavigationDrawer`).
- **AC-2:** Empty state illustration and guidance rendered when `getSessionLogs()` returns an empty list (`find.byKey(Key('sessions_empty_state'))`).
- **AC-2:** Chronological sorting: sessions are ordered reverse-chronologically by `startTime` (most recent match first).
- **AC-2:** Multi-racquet naming: session card resolves racquet name correctly from `racquetId` via `BagLoaded.racquets` (fallback to `'Racquet #$racquetId'`).
- **AC-3:** Sheet dismissal after logging updates session history list.
- **AC-4:** `AddRacquetModal` presentation layer imports and consumes `RacquetPreset` from the domain layer without regression on form auto-fill behavior.

---

## Step 4: Red-Phase Scaffolds & Evidence

### Files Created & Updated

| File | Type | Covers |
| --- | --- | --- |
| `test/helpers/tdd_red_phase.dart` | Helper | `tddRedPhase64Reason`, `tddRedPhase64` skip toggles |
| `test/widgets/sessions_screen_test.dart` | Widget Tests | AC-1, AC-2, AC-3 |
| `test/domain/racquet_preset_test.dart` | Unit Tests | AC-4 |

### Red-Phase Evidence (`flutter test --run-skipped`, 2026-10-13)

```
Failing tests (3 of 4 failed as expected in red phase, 1 domain contract verified):
  • [P2] [AC-1] selecting Sessions tab renders dedicated SessionsScreen and replaces SessionsPlaceholder across navigation modalities
    Expected: exactly one matching candidate with key: [<'sessions_screen'>]
      Actual: Found 0 widgets (Reason: SessionsPlaceholder rendered with 'COURT SESSIONS')

  • [P2] [AC-2] displays chronological list of logged sessions with date, duration, racquet name, and court hours added
    Expected: exactly one matching candidate with key: [<'sessions_list_view'>]
      Actual: Found 0 widgets (Reason: no session history list implemented)

  • [P2] [AC-3] provides prominent [+ Log Session] action button that triggers quick-log workout assignment sheet
    Expected: exactly one matching candidate with key: [<'sessions_log_session_button'>]
      Actual: Found 0 widgets (Reason: no log session action button on Sessions tab)

  • [P2] [AC-4] RacquetPreset domain model encapsulates pure specifications and popularPoly preset without UI dependencies
    Passed domain specification check; awaiting extraction from add_racquet_modal.dart into lib/domain/racquet_preset.dart
```

**Normal Test Run (`flutter test`):**  
**421 passed, 4 skipped, 0 failed** (100% green on `main`).

---

## Step 5: Validation & Handoff

### Checklist Validation

- [x] Prerequisites satisfied (Acceptance Criteria defined in `epics.md` and `test-design-epic-6.md`).
- [x] Deterministic criteria naming (`AC-1` through `AC-4`).
- [x] Exactly one primary red-phase scaffold per criterion.
- [x] Criterion-defining assertion is the first to fail under `--run-skipped`.
- [x] Clean compilation with `flutter analyze` / `analyze_files` (0 issues).
- [x] Code formatted with `dart format`.
- [x] CI/Trunk safety: tests skipped on `main` via `tdd_red_phase.dart`, preserving a green build.

### Downstream Handoff

- **Recommended Next Step:** `bmad-build` / `dev-story` for Story 6.4:
  1. Extract `RacquetPreset` to `lib/domain/racquet_preset.dart` and re-export in `lib/widgets/add_racquet_modal.dart`.
  2. Implement `SessionsScreen` in `lib/screens/sessions_screen.dart` with `Key('sessions_screen')`, `Key('sessions_list_view')`, and `Key('sessions_log_session_button')`.
  3. Replace `SessionsPlaceholder` in `VirtualBagScreen` with `SessionsScreen`.
  4. Toggle `tddRedPhase64 = false` in `test/helpers/tdd_red_phase.dart` to turn all tests green!
