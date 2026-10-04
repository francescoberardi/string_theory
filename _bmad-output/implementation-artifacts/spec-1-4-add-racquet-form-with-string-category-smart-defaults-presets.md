---
title: 'Story 1.4: Add Racquet Form with String Category Smart Defaults & Presets'
type: 'feature'
created: '2026-10-04'
status: 'in-review'
baseline_commit: 'c8f970868f0c2a26532822ca0010077884d622f9'
route: 'dispatch'
review_loop_iteration: 0
context:
  - 'AGENTS.md'
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/DESIGN.md'
  - '_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/EXPERIENCE.md'
  - '_bmad-output/test-artifacts/atdd-checklist-1-4-add-racquet-form-with-string-category-smart-defaults-presets.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Tennis players configuring their racquets shouldn't have to look up manufacturer play hours or string technicalities; the app needs a fast, guided Add Racquet modal with intelligent defaults by string category and 1-tap popular presets.

**Approach:** Implement `AddRacquetModal` in `string_theory_flutter/lib/widgets/add_racquet_modal.dart` with Court Midnight theme styling, automated category-driven max play hours pre-population, 1-tap presets (e.g. `[Popular Poly: Babolat RPM Blast @ 52 lbs]`), and reactive dispatch of `AddRacquet` events to `BagBloc`.

## Boundaries & Constraints

**Always:**
- Use exact Court Midnight palette tokens from `DESIGN.md`: `#121516` canvas background, `#1A1E20` slate card surface, `#2A3034` border outline, `#C6F10E` electric volt primary, Barlow Condensed for modal headers, and Inter for form inputs.
- Automatically populate Manufacturer Max Hours whenever a string material category is selected: Co-Poly (`20.0h`), Multifilament (`35.0h`), Synthetic Gut (`30.0h`), Natural Gut (`50.0h`), Kevlar/Hybrid (`25.0h`), while keeping the value fully user-editable.
- Provide a 1-tap preset button `[Popular Poly: Babolat RPM Blast @ 52 lbs]` that instantly populates racquet frame nickname, string brand, string model, tension, material category, and default max hours.
- Validate required fields (Racquet Name, String Brand, String Model, Tension, Max Hours) and dispatch `AddRacquet` event to `BagBloc` upon submission.
- Maintain 100% test pass rate on all acceptance criteria in `string_theory_flutter/test/add_racquet_modal_test.dart`.

**Never:**
- Never block the user from manually adjusting pre-populated smart defaults.
- Never edit generated code in `string_theory_client` or `string_theory_server/lib/src/generated/`.
- Never submit invalid or incomplete racquet configurations without highlighting the failing field.
- Never hardcode light theme assets or colors in the modal.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Open Modal | User triggers Add Racquet | `AddRacquetModal` bottom sheet / dialog renders with form inputs and Court Midnight styling | Default fields populated; date defaults to today |
| Select Co-Polyester | User selects `Co-Polyester` | `maxHours` field auto-updates to `20.0` | User can override text value |
| Select Multifilament | User selects `Multifilament` | `maxHours` field auto-updates to `35.0` | User can override text value |
| Tap Popular Poly Preset | User taps `[Popular Poly]` | Form fills with `Babolat Pure Aero`, `Babolat`, `RPM Blast`, `52.0 lbs`, `20.0 hrs`, `coPoly` | Instant UI update across all controllers |
| Submit Valid Form | User taps Submit | Dispatches `AddRacquet` to `BagBloc`; closes modal upon success | Popups snackbar / inline error if `BagError` emitted |
| Submit Incomplete Form | Required field empty (e.g. name) | Form displays validation warning and prevents submission | Inline validation message under field |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/widgets/add_racquet_modal.dart` -- Full implementation of `AddRacquetModal`, `RacquetPreset`, and `StringCategoryDefaults`.
- `string_theory_flutter/lib/bloc/bag_bloc.dart` -- Consumes `AddRacquet` event, invokes `client.bag.createRacquet`, updates bag state.
- `string_theory_flutter/lib/bloc/bag_event.dart` -- Immutable `AddRacquet` event definition.
- `string_theory_flutter/lib/theme/court_midnight_theme.dart` -- Theme tokens: `#121516` canvas, `#1A1E20` surface, `#2A3034` border, `#C6F10E` primary volt.
- `string_theory_flutter/test/add_racquet_modal_test.dart` -- Acceptance test suite verifying AC-1 through AC-5.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_flutter/lib/widgets/add_racquet_modal.dart` -- Implement form UI layout, controllers, and Court Midnight styling -- AC-1
- [x] `string_theory_flutter/lib/widgets/add_racquet_modal.dart` -- Wire category selection listener to `StringCategoryDefaults.maxHours` -- AC-2, AC-3
- [x] `string_theory_flutter/lib/widgets/add_racquet_modal.dart` -- Wire 1-tap preset button `[Popular Poly: Babolat RPM Blast @ 52 lbs]` -- AC-4
- [x] `string_theory_flutter/lib/widgets/add_racquet_modal.dart` -- Wire form validation and `BagBloc.add(AddRacquet(...))` submission -- AC-5
- [x] `string_theory_flutter/test/add_racquet_modal_test.dart` -- Un-skip and execute all 5 acceptance tests to turn them green -- Verification

**Acceptance Criteria:**
- Given user opens modal, then all required form fields render with Court Midnight theme styling (AC-1).
- When user selects `Co-Polyester`, then Max Hours automatically updates to `20.0 hrs` (AC-2).
- When user selects `Multifilament`, `Synthetic Gut`, or `Natural Gut`, then Max Hours updates to `35.0`, `30.0`, or `50.0 hrs` and remains editable (AC-3).
- When user taps Popular Poly preset, then all specs are populated instantly (AC-4).
- When user submits valid form, then `AddRacquet` event is dispatched to `BagBloc` (AC-5).

## Implementation Notes

- Implemented `AddRacquetModal` with full Court Midnight athletic design system tokens: `#121516` canvas background, `#1A1E20` surface, `#23282C` elevated inputs, `#2A3034` surface border, `#C6F10E` primary volt accent, Barlow Condensed typography for headers and CTAs, and Inter for form inputs.
- Provided `StringMaterialCategoryExtension` mapping all enum values to user-friendly titles (`Co-Polyester`, `Multifilament`, `Synthetic Gut`, `Natural Gut`, `Kevlar`, `Hybrid`, `Other`).
- Wired category dropdown selection to `StringCategoryDefaults.maxHours`, pre-populating max hours while keeping the field editable by the user.
- Wired 1-tap preset button `[Popular Poly: Babolat RPM Blast @ 52 lbs]` to instantly populate racquet frame, brand, model, string specs, tension (52.0), and max hours (20.0).
- Integrated form validation and reactive dispatch of `AddRacquet` event to `widget.bagBloc ?? context.read<BagBloc>()`.

## Spec Change Log

- None (implemented strictly within frozen intent).

## Review Triage Log

## Verification

**Commands:**
- `analyze_files` (Dart MCP) -- passed: 0 errors across workspace.
- `flutter test test/add_racquet_modal_test.dart` -- passed: all 5 acceptance tests + 2 edge-case tests pass green.
- `flutter test` -- passed: 26/26 tests passed in `string_theory_flutter`.
