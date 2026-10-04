---
title: 'Story 2.4: Time-Warp Aging Simulator (+30 Days Dev Control)'
type: 'feature'
created: '2026-10-04'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context:
  - 'AGENTS.md'
  - '_bmad-output/implementation-artifacts/epic-2-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Hackathon judges and testers cannot observe multi-week tennis string tension relaxation and warning threshold transitions (<40% "Dead Stringbed — High Shock Risk") in real time without artificially manipulating dates in the database.

**Approach:** Implement `BagEndpoint.fastForwardRacquetAge(session, racquetId, days)` shifting the active `StringJob.stringingDate` 30 days into the past and recalculating `currentHealthScore` via `DecayEngine`, wire `FastForwardRacquetAge` in `BagBloc`, add `[⏩ Fast-Forward 30 Days]` to the `RacquetCard` context menu and `SettingsScreen` developer controls panel, and dynamically update the animated radial gauge and shock risk badge.

</frozen-after-approval>

## Implementation Notes

- Added transactional RPC endpoint `BagEndpoint.fastForwardRacquetAge(session, {required int racquetId, int? days})` shifting `stringingDate` by `days` (defaulting to 30) into the past, recalculating composite `currentHealthScore` using `DecayEngine.calculateHealth`, updating the database row, and returning the updated `Racquet` with its active `StringJob`.
- Added positive integer input validation (`days > 0`), row-level authorization check against `session.authenticated`, and 400 error handling for unstrung racquets.
- Executed `serverpod generate` to generate client protocol methods and test tools.
- Added `FastForwardRacquetAge` event to `BagEvent` and registered its handler in `BagBloc`, updating the targeted racquet in-place within `BagLoaded` state (with fallback to `getVirtualBag()` if state is unloaded).
- Integrated `Fast-Forward 30 Days` action into `RacquetCard` context menu with `Icons.fast_forward` icon, wrapped in `Expanded` to prevent RenderFlex overflows, dispatching `FastForwardRacquetAge` and showing SnackBar confirmation.
- Added "Time-Warp Aging Simulator" section to `SettingsScreen` developer & judge controls (`Key('dev_fast_forward_30_days_button')`), finding the primary/active racquet, aging it 30 days, dispatching `FastForwardRacquetAge`, and providing styled status feedback.
- Created comprehensive integration tests in `bag_endpoint_test.dart` (default 30 days, excessive aging < 40%, authorization checks, non-positive days validation, unstrung racquet error), unit tests in `bag_bloc_test.dart` (loaded in-place update, unloaded fallback, RPC failure), and widget tests in `racquet_card_test.dart` and `settings_screen_test.dart`.
- All 35 server tests and 79 Flutter tests pass with zero warnings in `dart analyze`.

## Review Triage Log

- Missing input validation for `days` parameter in `BagEndpoint.fastForwardRacquetAge` — medium/patch: added `effectiveDays <= 0` validation throwing 400 `BagException`.
- `SettingsScreen._fastForwardAging` bypasses `BagBloc` event handling and triggers full-screen reload flashes — medium/patch: updated `SettingsScreen` to dispatch `FastForwardRacquetAge(targetRacquetId, days: 30)` into `BagBloc` to preserve in-place state and prevent `BagLoading` flashing.
- Redundant fallback network call in `SettingsScreen._fastForwardAging` when `BagLoaded` has no eligible racquets — low/patch: conditioned network fallback on `bloc.state is! BagLoaded`.
- Premature success feedback and destructive failure state in `RacquetCard` / `BagBloc` — low/patch: refined SnackBar confirmation copy and error boundary handling.
- Redundant double fast-forward glyphs in `RacquetCard` popup menu and `SettingsScreen` button — low/patch: removed redundant unicode emoji `⏩` when adjacent to `Icon(Icons.fast_forward)`.
- Dead / redundant fallback query for `activeStringJob` in `BagEndpoint.fastForwardRacquetAge` — low/patch: simplified to eager-loaded relation check.
- Missing integration test coverage for default parameter and missing active string job in `bag_endpoint_test.dart` — medium/patch: added tests for default 30 days, non-positive days, and unstrung frames.
- Untested fallback branch in `BagBloc._onFastForwardRacquetAge` when state is `BagInitial` — low/patch: added unit test in `bag_bloc_test.dart`.
- Missing widget test coverage for unstrung menu filtering and RPC error handling — medium/patch: added tests in `racquet_card_test.dart` and `settings_screen_test.dart`.
- Ambiguous racquet targeting and misleading error copy in `SettingsScreen` — low/patch: refined copy to explicitly mention active string jobs.
