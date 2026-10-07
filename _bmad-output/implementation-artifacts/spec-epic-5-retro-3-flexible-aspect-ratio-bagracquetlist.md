---
title: 'Implement flexible aspect ratio or extent in BagRacquetList grid for accessibility scaling'
type: 'refactor'
created: '2026-10-07'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `BagRacquetList` uses a hardcoded fixed `mainAxisExtent: 176.0` on tablet and desktop viewports, causing vertical text clipping and `RenderFlex` overflow errors in `RacquetCard` when larger accessibility text scaling (e.g. 1.5x or 2.0x font scaling) is active. Source: Epic 5 retro action item 3 (`epic-5-retro-item-3-flexible-aspect-ratio-bagracquetlist`).

**Approach:** Introduce dynamic grid card extent resolution in `BagRacquetList` that queries `MediaQuery.textScalerOf(context)` and scales the grid cell height proportionally to accommodate text scaling, provide a direct `resolveGridCardExtentForScaler` helper for deterministic unit testing, allow an optional `mainAxisExtent` constructor override, add comprehensive unit and widget tests across multiple text scaling factors, and mark action item 3 done in `sprint-status.yaml`.

</frozen-after-approval>

## Implementation Notes

- Implemented dynamic grid card extent calculation in `BagRacquetList.resolveGridCardExtentForScaler(TextScaler textScaler)` to dynamically scale card extent to accommodate text scaling without overflows.
- Added `BagRacquetList.resolveGridCardExtent(BuildContext context)` with `MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling` for safe resilience in tests and previews.
- Added an optional `mainAxisExtent` constructor parameter on `BagRacquetList` for explicit caller overrides, defaulting to `resolveGridCardExtent(context)`.
- Protected `RadialHealthGauge` center content with a bounded `SizedBox(width: (size * 0.76).clamp(...))` and `FittedBox(fit: BoxFit.scaleDown)` so `tensionLossText` properly truncates and percentage text does not overflow the circular gauge under high text scaling.
- Added comprehensive unit and widget tests in `string_theory_flutter/test/widgets/bag_racquet_list_test.dart` covering extent calculations, scaling factors (1.0x, 1.5x, 2.0x), mobile `ListView`, desktop 3-column grid, pull-to-refresh, and empty states.
- Added scaling tests in `string_theory_flutter/test/widgets/radial_health_gauge_test.dart`.
- Marked `epic-5-retro-item-3-flexible-aspect-ratio-bagracquetlist` as `done` in `_bmad-output/implementation-artifacts/sprint-status.yaml`.
- Verified clean `dart analyze` (0 issues), clean `dart format`, 383 passing Flutter tests, and 99 passing server integration tests.

## Review Triage Log

- `RadialHealthGauge`: `FittedBox` shrinks entire gauge center content when `tensionLossText` is present: medium, patched (bounded width with `SizedBox(width: (size * 0.76)...)` before `FittedBox` so `TextOverflow.ellipsis` engages).
- `RadialHealthGauge`: Counteracting accessibility text scaling: low, rejected (fixed-diameter circular graphics require bounded center scaling to remain within the indicator ring).
- `RadialHealthGauge`: Missing test coverage for text scaling and overflow prevention: medium, patched (added widget test under 2.0x text scaling in `radial_health_gauge_test.dart`).
- `BagRacquetList`: Redundant and non-linear-fragile check in `resolveGridCardExtentForScaler`: medium, patched (removed linear check and compute dynamic extent directly for all scalers).
- `BagRacquetList`: `mainAxisExtent` parameter is ignored when `isMobile: true`: low, patched (documented parameter specifying it applies to multi-column tablet/desktop grid layouts).
- `BagRacquetList`: Fragile coupling of `RacquetCard` layout heuristics: low, rejected (co-located presentation widgets; dynamic extent formula provides generous safety margin).
- `BagRacquetList`: Potential runtime error if `MediaQuery` is absent: low, patched (used `MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling`).
- `bag_racquet_list_test.dart`: Missing test coverage for mobile layout, desktop grid, and empty states: medium, patched (added mobile list, desktop 3-column, pull-to-refresh, and empty state tests).
- Sprint status tracking not updated: high, patched (marked `epic-5-retro-item-3-flexible-aspect-ratio-bagracquetlist` as `done` in `sprint-status.yaml`).
