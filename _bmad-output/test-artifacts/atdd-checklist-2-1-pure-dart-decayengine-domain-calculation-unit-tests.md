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
storyId: '2.1'
storyKey: '2-1-pure-dart-decayengine-domain-calculation-unit-tests'
storyFile: '_bmad-output/planning-artifacts/epics.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-2-1-pure-dart-decayengine-domain-calculation-unit-tests.md'
generatedTestFiles:
  - 'string_theory_server/test/unit/domain/decay_engine_test.dart'
  - 'string_theory_flutter/test/domain/decay_engine_test.dart'
inputDocuments:
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/ARCHITECTURE-SPINE.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/SOLUTION-DESIGN.md'
  - '_bmad-output/implementation-artifacts/epic-1-retro-2026-10-04.md'
  - '_bmad/tea/config.yaml'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/data-factories.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/component-tdd.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-quality.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-healing-patterns.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-levels-framework.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-priorities-matrix.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/ci-burn-in.md'
acceptanceCriteria:
  - id: 'AC-1'
    idSource: 'generated'
    text: 'Given string parameters (hours played, max rated hours, stringing date, string material category), when DecayEngine.calculateHealth(...) executes, it returns an integer HealthScore (0–100%) based on DynamicPenalty = (hoursPlayed / maxRatedHours) * 70 and CalendarPenalty = (daysElapsed / shelfLife) * 30, where shelf life is 75 days (Co-Poly), 180 days (Multifilament/Synthetic), 365 days (Natural Gut).'
  - id: 'AC-2'
    idSource: 'generated'
    text: 'DecayEngine calculates secondary tension loss text (e.g., ~1.5 kg / ~3.3 lbs drop).'
  - id: 'AC-3'
    idSource: 'generated'
    text: 'Pure Dart unit tests verify boundary cases (0 hours, max hours, 400 days elapsed, negative clamps, exact shelf-life thresholds) with 100% pass rate.'
---

# ATDD Checklist: Story 2.1: Pure Dart DecayEngine Domain Calculation & Unit Tests

**Date:** 2026-10-04  
**Author:** Francesco  
**Target Stack:** Pure Dart / Multi-Package Domain (`string_theory_server` & `string_theory_flutter`)  
**Story Key:** `2-1-pure-dart-decayengine-domain-calculation-unit-tests`  
**Primary Test Level:** Unit / Pure Domain Calculation Tests (`package:test` & `flutter_test`)  

---

## 1. Story Summary

- **Title:** Story 2.1: Pure Dart DecayEngine Domain Calculation & Unit Tests
- **Epic:** Epic 2: Dynamic Health Score, Composite Decay & On-Demand FutureCall Trigger
- **Problem:** Co-poly and synthetic tennis strings lose elasticity dynamically through court playtime impacts and statically through calendar shelf-life creep in the tennis bag. We need a deterministic, shared domain calculation engine (`DecayEngine`) to calculate identical health scores and tension loss estimates across the Flutter client (for optimistic 60fps UI animations) and the Serverpod backend (for authoritative DB persistence and daily scheduled cron updates).
- **Core Domain Formula:**
  - $\text{DynamicPenalty} = (\text{hoursPlayed} / \text{maxRatedHours}) \times 70$
  - $\text{CalendarPenalty} = (\text{daysElapsed} / \text{shelfLife}) \times 30$
  - $\text{HealthScore} = \text{clamp}(100 - (\text{DynamicPenalty} + \text{CalendarPenalty}), 0, 100)$
  - $\text{ShelfLife}$:
    - `coPoly`: 75 days
    - `multifilament` & `syntheticGut`: 180 days
    - `naturalGut`: 365 days
    - `hybrid` / `other` / fallback: 180 days
  - $\text{TensionLoss}$: calculated drop estimate in kg and lbs based on initial tension and health degradation.

---

## 2. Acceptance Criteria Registry

| ID | Source | Criteria Description |
|---|---|---|
| `AC-1` | generated | Given string parameters (hours played, max rated hours, stringing date, string material category), when `DecayEngine.calculateHealth(...)` executes, it returns an integer `HealthScore` ($0–100\%$) based on $\text{DynamicPenalty} = (\text{hoursPlayed} / \text{maxRatedHours}) \times 70$ and $\text{CalendarPenalty} = (\text{daysElapsed} / \text{shelfLife}) \times 30$, where shelf life is 75 days (Co-Poly), 180 days (Multifilament/Synthetic), 365 days (Natural Gut). |
| `AC-2` | generated | `DecayEngine` calculates secondary tension loss text (e.g. `~1.5 kg / ~3.3 lbs drop`). |
| `AC-3` | generated | Pure Dart unit tests verify boundary cases (0 hours, max hours, 400 days elapsed, negative clamps, exact shelf-life thresholds) with 100% pass rate. |

---

## 3. Preflight & Generation Mode Selection

- **Detected Stack:** Pure Dart domain across multi-package workspace (`string_theory_server` and `string_theory_flutter`).
- **Generation Mode:** AI Generation Mode.
- **Rationale:** Story 2.1 is focused entirely on pure Dart mathematical and domain algorithms. There are no UI interactions or browser recording requirements.
- **Prerequisites Met:**
  - [x] Story loaded from `_bmad-output/planning-artifacts/epics.md`
  - [x] Acceptance criteria registered with deterministic IDs
  - [x] Test framework configured (`package:test` / `flutter_test`)
  - [x] Architecture constraints aligned (`ARCHITECTURE-SPINE.md` AD-1, AD-2)
  - [x] Retro item 2 from Epic 1 acknowledged (authoritative pure Dart `DecayEngine`)

---

## 4. Test Strategy & Scenarios Mapping

| Criterion | Level | Priority | Scenario Description | Primary Red Failure Point |
|---|---|---|---|---|
| **AC-1** | Unit | P0 | Calculate composite health score from dynamic hours and calendar days | `DecayEngine.calculateHealth` throws `UnimplementedError` |
| **AC-1** | Unit | P0 | Dynamic hours and calendar days penalties weighted at 70% and 30% independently | `DecayEngine.calculateHealth` calculation logic missing |
| **AC-2** | Unit | P1 | Calculate secondary tension loss text formatted with kg and lbs drop | `DecayEngine.calculateTensionLossText` throws `UnimplementedError` |
| **AC-2** | Unit | P1 | Report 0.0 kg / 0.0 lbs drop when stringbed is at 100% health | `DecayEngine.calculateTensionLossText` zero-drop formatting missing |
| **AC-3** | Unit | P0 | Return 100% health for fresh unplayed strings (0 hours, 0 days) | Boundary condition check missing |
| **AC-3** | Unit | P0 | Clamp health score to 0% when combined penalties exceed 100% | Underflow clamp logic missing |
| **AC-3** | Unit | P0 | Clamp negative hours or future stringing dates to 0 penalty (100% cap) | Negative input clamp missing |
| **AC-3** | Unit | P0 | Verify material category shelf-life mapping (`coPoly`: 75, `multi`: 180, `synthetic`: 180, `gut`: 365) | `DecayEngine.getShelfLifeDays` mapping missing |

---

## 5. Red-Phase Test Scaffolds Created

### 1. Serverpod Backend Domain Test Suite
- **File:** [`string_theory_server/test/unit/domain/decay_engine_test.dart`](file:///Users/francescoberardi/projects/personal/string_theory/string_theory_server/test/unit/domain/decay_engine_test.dart)
- **Framework:** `package:test`
- **Scaffolds Created:** 8 test scenarios grouped by acceptance criteria
- **Status:** 🔴 RED (scaffolded with `skip: 'TDD Red Phase: pending Story 2.1 implementation'`; fails with `UnimplementedError` when unskipped)

### 2. Flutter Client Domain Test Suite
- **File:** [`string_theory_flutter/test/domain/decay_engine_test.dart`](file:///Users/francescoberardi/projects/personal/string_theory/string_theory_flutter/test/domain/decay_engine_test.dart)
- **Framework:** `flutter_test`
- **Scaffolds Created:** 8 test scenarios grouped by acceptance criteria
- **Status:** 🔴 RED (scaffolded with `skip: 'TDD Red Phase: pending Story 2.1 implementation'`; fails with `UnimplementedError` when unskipped)

### 3. Red-Phase Stub Implementations
- **Server:** [`string_theory_server/lib/src/domain/decay_engine.dart`](file:///Users/francescoberardi/projects/personal/string_theory/string_theory_server/lib/src/domain/decay_engine.dart) (methods throw `UnimplementedError`)
- **Client:** [`string_theory_flutter/lib/domain/decay_engine.dart`](file:///Users/francescoberardi/projects/personal/string_theory/string_theory_flutter/lib/domain/decay_engine.dart) (methods throw `UnimplementedError`)

---

## 6. Implementation Checklist (DEV Team Roadmap)

### Phase 1: Core Mathematical Implementation (`DecayEngine.calculateHealth`)
- [ ] Implement `getShelfLifeDays(StringMaterialCategory category)`:
  - `coPoly`: 75
  - `multifilament`: 180
  - `syntheticGut`: 180
  - `naturalGut`: 365
  - `kevlar`: 120
  - `hybrid`: 180
  - `other`: 180
- [ ] Implement `calculateHealth(...)`:
  - Calculate `effectiveHours = max(0.0, hoursPlayed)`
  - Calculate `effectiveMaxHours = max(1.0, maxRatedHours)`
  - Compute `dynamicPenalty = (effectiveHours / effectiveMaxHours) * 70.0`
  - Calculate `daysElapsed = max(0.0, (now ?? DateTime.now()).difference(stringingDate).inHours / 24.0)`
  - Compute `calendarPenalty = (daysElapsed / shelfLifeDays) * 30.0`
  - Compute `rawHealth = 100.0 - (dynamicPenalty + calendarPenalty)`
  - Return `rawHealth.round().clamp(0, 100)`

### Phase 2: Tension Drop Calculation & Text Formatting (`DecayEngine.calculateTensionLossText`)
- [ ] Implement `calculateTensionLossText({required int healthScore, double installedTensionLbs = 52.0})`:
  - Estimate tension drop percentage based on degradation: `healthDropFraction = (100 - healthScore.clamp(0, 100)) / 100.0`
  - Max expected elasticity tension loss at 0% health is ~25% of installed tension
  - Calculate `lbsDrop = (installedTensionLbs * 0.25 * healthDropFraction)`
  - Calculate `kgDrop = lbsDrop * 0.45359237`
  - Return formatted string: `"~${kgDrop.toStringAsFixed(1)} kg / ~${lbsDrop.toStringAsFixed(1)} lbs drop"`

### Phase 3: Green Verification
- [ ] Remove `skip` flags in `string_theory_server/test/unit/domain/decay_engine_test.dart`
- [ ] Remove `skip` flags in `string_theory_flutter/test/domain/decay_engine_test.dart`
- [ ] Run backend tests: `cd string_theory_server && dart test`
- [ ] Run frontend tests: `cd string_theory_flutter && flutter test`
- [ ] Run static analysis: `dart analyze` across workspace

---

## 7. Red-Green-Refactor Guidance

1. **Verify RED state**:
   To observe failing tests prior to implementation, remove the `skip: tddRedPhaseReason` parameter in any test block and run the test. The test will fail with `UnimplementedError: DecayEngine.<method> is not yet implemented`.
2. **Implement GREEN**:
   Fill in the mathematical calculations in both `string_theory_server/lib/src/domain/decay_engine.dart` and `string_theory_flutter/lib/domain/decay_engine.dart`.
3. **Verify REFACTOR**:
   Ensure 100% test pass rate and 0 analysis errors across both backend and frontend suites.
