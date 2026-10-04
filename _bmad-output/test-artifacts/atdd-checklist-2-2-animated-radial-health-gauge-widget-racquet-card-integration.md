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
storyId: '2.2'
storyKey: '2-2-animated-radial-health-gauge-widget-racquet-card-integration'
storyFile: '_bmad-output/planning-artifacts/epics.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-2-2-animated-radial-health-gauge-widget-racquet-card-integration.md'
generatedTestFiles:
  - 'string_theory_flutter/test/widgets/radial_health_gauge_test.dart'
  - 'string_theory_flutter/test/widgets/racquet_card_test.dart'
inputDocuments:
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/ARCHITECTURE-SPINE.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/SOLUTION-DESIGN.md'
  - '_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/DESIGN.md'
  - '_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/EXPERIENCE.md'
  - '_bmad-output/implementation-artifacts/epic-1-retro-2026-10-04.md'
  - '_bmad-output/implementation-artifacts/epic-2-context.md'
  - '_bmad/tea/config.yaml'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/data-factories.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/component-tdd.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-quality.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-healing-patterns.md'
acceptanceCriteria:
  - id: 'AC-1'
    idSource: 'generated'
    text: 'Given a racquet card rendering in the Virtual Bag or standalone, when the health score changes or card loads, then a circular radial ring gauge smoothly animates to the score at 60 fps.'
  - id: 'AC-2'
    idSource: 'generated'
    text: 'The ring glows Green (#10B981) for >= 70%, Amber (#F59E0B) for 40–69%, and Red (#EF4444) for < 40%.'
  - id: 'AC-3'
    idSource: 'generated'
    text: 'The center displays the bold percentage in Barlow Condensed with secondary tension loss helper text below.'
  - id: 'AC-4'
    idSource: 'generated'
    text: 'Racquets with < 40% health display a cautionary badge: "Dead Stringbed — High Shock Risk".'
---

# ATDD Checklist: Story 2.2: Animated Radial Health Gauge Widget & Racquet Card Integration

**Date:** 2026-10-04  
**Author:** Francesco  
**Target Stack:** Mobile / Flutter (`string_theory_flutter`)  
**Story Key:** `2-2-animated-radial-health-gauge-widget-racquet-card-integration`  
**Primary Test Level:** Component / Widget Tests (`flutter_test`)  

---

## 1. Story Summary

- **Title:** Story 2.2: Animated Radial Health Gauge Widget & Racquet Card Integration
- **Epic:** Epic 2: Dynamic Health Score, Composite Decay & On-Demand FutureCall Trigger
- **Problem:** Tennis players need to assess their racquet's stringbed elasticity and arm-shock injury risk in under 1 second without deciphering raw hour logs or dates.
- **Solution:** A standalone, 60fps smoothly animated circular radial ring gauge widget (`RadialHealthGauge`) with color-coded status glow tiers (Green $\ge 70\%$, Amber $40–69\%$, Red $<40\%$), center Barlow Condensed bold percentage, secondary tension loss helper text (`~1.5 kg / ~3.3 lbs drop`), and a high arm shock risk badge integrated seamlessly into `RacquetCard`.
- **Architectural Linkage:** Addresses Retro Item 1 from Epic 1: extracting `RacquetCard` and `RadialHealthGauge` from `virtual_bag_screen.dart` into reusable, standalone widgets in `lib/widgets/`.

---

## 2. Acceptance Criteria Registry

| ID | Source | Criteria Description |
|---|---|---|
| `AC-1` | generated | Given a racquet card rendering in the Virtual Bag or standalone, when the health score changes or card loads, then a circular radial ring gauge smoothly animates to the score at 60 fps. |
| `AC-2` | generated | The ring glows Green (`#10B981`) for $\ge 70\%$, Amber (`#F59E0B`) for $40–69\%$, and Red (`#EF4444`) for $<40\%$. |
| `AC-3` | generated | The center displays the bold percentage in Barlow Condensed with secondary tension loss helper text below. |
| `AC-4` | generated | Racquets with $<40\%$ health display a cautionary badge: *"Dead Stringbed — High Shock Risk"*. |

---

## 3. Preflight & Generation Mode Selection

- **Detected Stack:** `mobile` (Flutter app with UI widgets, `flutter_test`).
- **Generation Mode:** AI Generation Mode.
- **Rationale:** Component and widget testing for Flutter widgets using `WidgetTester` (`flutter_test`) provides high-fidelity, deterministic 60fps frame ticker control without needing live browser recording tools.
- **Prerequisites Met:**
  - [x] Story loaded from `_bmad-output/planning-artifacts/epics.md`
  - [x] Acceptance criteria registered with deterministic IDs
  - [x] Test framework configured (`flutter_test`)
  - [x] Architecture constraints aligned (`ARCHITECTURE-SPINE.md`, `DESIGN.md`, `EXPERIENCE.md`)
  - [x] Epic 1 retro action item 1 acknowledged (extract `RacquetCard` and `RadialHealthGauge` into standalone files)

---

## 4. Test Strategy & Scenarios Mapping

| Criterion | Level | Priority | Scenario Description | Primary Red Failure Point |
|---|---|---|---|---|
| **AC-1** | Component | P0 | Smoothly animate radial ring progress from 0 to target score at 60fps | Missing animation controller / ticker progress in `RadialHealthGauge` |
| **AC-1** | Component | P0 | Smoothly animate when health score updates to new value | `didUpdateWidget` animation transition missing |
| **AC-2** | Component | P0 | Display optimal green ring and glow (`#10B981`) for health $\ge 70\%$ | Incorrect color threshold or missing optimal color mapping |
| **AC-2** | Component | P0 | Display degraded amber ring and glow (`#F59E0B`) for health $40–69\%$ | Incorrect degraded color mapping |
| **AC-2** | Component | P0 | Display critical red ring and glow (`#EF4444`) for health $<40\%$ | Incorrect critical color mapping |
| **AC-2** | Component | P1 | Display muted tertiary styling for unstrung racquet (null health score) | Null safety crash or missing unstrung state handling |
| **AC-3** | Component | P0 | Display bold health percentage in center with Barlow Condensed styling | Center percentage text missing or improper font style |
| **AC-3** | Component | P1 | Display secondary tension loss text below percentage | Missing secondary tension loss text widget |
| **AC-4** | Component | P0 | Racquet card displays cautionary badge "Dead Stringbed — High Shock Risk" when health $<40\%$ | Missing cautionary badge widget or wrong threshold |
| **AC-4** | Component | P0 | Racquet card does NOT display cautionary badge when health $\ge 40\%$ | Cautionary badge incorrectly shown on healthy or amber stringbed |

---

## 5. Red-Phase Test Scaffolds Created

### 1. Radial Health Gauge Component Test Suite
- **File:** [`string_theory_flutter/test/widgets/radial_health_gauge_test.dart`](file:///Users/francescoberardi/projects/personal/string_theory/string_theory_flutter/test/widgets/radial_health_gauge_test.dart)
- **Framework:** `flutter_test`
- **Scaffolds Created:** 7 test scenarios covering AC-1, AC-2, AC-3
- **Status:** 🔴 RED (scaffolded with `skip: 'ATDD Red Phase: pending Story 2.2 implementation'`; fails on unimplemented widget assertions when unskipped)

### 2. Racquet Card Integration Test Suite
- **File:** [`string_theory_flutter/test/widgets/racquet_card_test.dart`](file:///Users/francescoberardi/projects/personal/string_theory/string_theory_flutter/test/widgets/racquet_card_test.dart)
- **Framework:** `flutter_test`
- **Scaffolds Created:** 5 test scenarios covering AC-1, AC-3, AC-4, and unstrung state
- **Status:** 🔴 RED (scaffolded with `skip: 'ATDD Red Phase: pending Story 2.2 implementation'`; fails on unimplemented standalone card assertions when unskipped)

---

## 6. Implementation Checklist (DEV Team Roadmap)

### Phase 1: Standalone `RadialHealthGauge` Widget (`lib/widgets/radial_health_gauge.dart`)
- [ ] Create `RadialHealthGauge` widget:
  - Constructor parameters:
    - `int? healthScore` (0–100, or null if unstrung)
    - `String? tensionLossText` (secondary text, e.g. `~1.5 kg / ~3.3 lbs drop`)
    - `double size` (default `56.0` or `64.0`)
    - `bool animate` (default `true`)
    - `Duration animationDuration` (default `Duration(milliseconds: 750)`)
- [ ] Implement smooth 60fps radial ring animation:
  - Use `AnimationController` / `TweenAnimationBuilder<double>` animating from 0.0 to `healthScore / 100.0`.
  - Trigger animation on load and when `healthScore` changes (`didUpdateWidget`).
- [ ] Implement 3-tier color coding and glowing ring:
  - Green (`CourtMidnightTheme.healthOptimal` = `#10B981`) for $\ge 70\%$
  - Amber (`CourtMidnightTheme.healthDegraded` = `#F59E0B`) for $40–69\%$
  - Red (`CourtMidnightTheme.healthCritical` = `#EF4444`) for $<40\%$
  - Gray (`CourtMidnightTheme.textTertiary`) for unstrung / null
  - Add glowing visual aura (box shadow / glow sweep or soft outer border).
- [ ] Implement center typography and tension loss helper text:
  - Barlow Condensed bold percentage (`$healthScore%` or `--%`).
  - Secondary helper text below (`tensionLossText` or `HEALTH` / `UNSTRUNG`).

### Phase 2: Standalone `RacquetCard` Widget (`lib/widgets/racquet_card.dart`)
- [ ] Extract `RacquetCard` from `virtual_bag_screen.dart` into `lib/widgets/racquet_card.dart`.
- [ ] Embed `RadialHealthGauge`:
  - Pass `job.currentHealthScore`.
  - Pass calculated tension loss text from `DecayEngine.calculateTensionLossText(...)`.
- [ ] Implement Cautionary Badge:
  - Display `"Dead Stringbed — High Shock Risk"` with alert icon when health is $<40\%$.
  - Ensure card background adopts `healthCriticalBg` and red accent border on critical health.
- [ ] Export and integrate in `virtual_bag_screen.dart`.

### Phase 3: Green Verification
- [ ] Remove `skip` flags in `string_theory_flutter/test/widgets/radial_health_gauge_test.dart`
- [ ] Remove `skip` flags in `string_theory_flutter/test/widgets/racquet_card_test.dart`
- [ ] Run Flutter test suite: `cd string_theory_flutter && flutter test`
- [ ] Run static analysis: `dart analyze` across workspace
- [ ] Verify hot reload / UI appearance in Virtual Bag screen.

---

## 7. Red-Green-Refactor Guidance

1. **Verify RED state**:
   To observe failing tests prior to implementation, remove the `skip: tddRedPhaseReason` parameter in any test block in `radial_health_gauge_test.dart` or `racquet_card_test.dart` and run `flutter test`. The tests will fail against the missing widgets or features.
2. **Implement GREEN**:
   Implement `RadialHealthGauge` and `RacquetCard` in `string_theory_flutter/lib/widgets/`, satisfying all acceptance criteria.
3. **Verify REFACTOR**:
   Ensure all tests pass cleanly, 0 analyzer warnings, and format with `dart format`.
