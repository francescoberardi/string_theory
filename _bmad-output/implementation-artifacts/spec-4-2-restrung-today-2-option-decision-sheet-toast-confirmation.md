---
title: 'Story 4.2: "Restrung Today" 2-Option Decision Sheet & Toast Confirmation'
type: 'feature'
created: '2026-10-05'
status: 'done'
baseline_commit: '7b167c13ad7f370008686fa05272c653468c1120'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-4-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Story 4.1 shipped the transactional `restringRacquet` endpoint, but the app has no way to call it. A player with a dead stringbed cannot reset it, and nothing celebrates the fresh setup.

**Approach:** Add a `[Restrung Today]` button to every racquet card that opens a 2-option sheet: `[Keep Same & Reset]` (1 tap) or `[Change Specs]` (accordion with string brand, model, tension, material category). A new `RestringRacquet` bloc event calls the endpoint, resets the gauge optimistically and shows a green success toast.

## Boundaries & Constraints

**Always:**
- Button on every card that has an id and an active job (UX-DR5). It is filled and prominent when health < 40, outlined otherwise.
- `[Keep Same & Reset]` dispatches `RestringRacquet(racquetId, keepSame: true)` and closes the sheet in the same tap.
- `[Change Specs]` fields start with the current job's values. Brand and model are required, tension must be finite and > 0. Changing the category sets max hours to `StringCategoryDefaults.maxHours`; otherwise the current max hours are kept. Submit dispatches `keepSame: false` with those values.
- Toast text is exactly `Fresh stringbed mounted! Restrung to 100% health.`, shown only after the server confirms, in `healthOptimal` green.
- Gauge resets optimistically (health 100, hours 0) and reverts if the call fails. The failure shows an error SnackBar in plain words, not a raw exception.
- The server's response replaces the racquet in state, so the new job's specs win over the `restrung` stream message (100 health, 0 hours), which then changes nothing.
- Ignore a second `RestringRacquet` for a racquet whose restring is still in flight.

**Never:**
- No changes to server, client package, models or `lib/generated`. Do not use the endpoint's `simulateFailure` or `restringDate`.
- No offline queueing of restrings; offline is a failure with the error SnackBar.
- No history timeline or detail screen (Story 4.3). No `stringJobId` added to `BagStreamMessage`.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Keep same | tap button, then Keep Same | Sheet closes, gauge 100% at once, specs unchanged, toast after server OK | N/A |
| Change specs | expand, edit, submit | Server gets new category, brand, model, tension, max hours; card shows new specs | Invalid field shows inline error, nothing dispatched |
| Server failure | endpoint throws | Gauge reverts to previous health, error SnackBar, no success toast | Message: `Could not restring "<name>". Check your connection and try again.` |
| Double submit | second event while first in flight | Ignored; one endpoint call | N/A |
| Healthy racquet | health >= 40 | Outlined button; sheet works the same | N/A |
| No active job | `activeStringJob == null` | No button | N/A |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/bloc/bag_event.dart` -- add `RestringRacquet`.
- `string_theory_flutter/lib/bloc/bag_state.dart` -- add transient `successMessage` to `BagLoaded` (next to `infoMessage`; include in `props`).
- `string_theory_flutter/lib/bloc/bag_bloc.dart` -- `_onRestringRacquet`, reusing `_loaded`, the `_emitLogFailure` revert pattern and `client.bag.restringRacquet(racquetId:, keepSame:, materialCategory:, stringBrand:, stringModel:, tension:, maxRatedHours:)`.
- `string_theory_flutter/lib/widgets/restring_sheet.dart` -- new `RestringSheet.show(...)`, built on `workout_assignment/assignment_sheet_frame.dart`; reuse `StringCategoryDefaults` from `add_racquet_modal.dart` and its field styling.
- `string_theory_flutter/lib/widgets/racquet_card.dart` -- add the button to the center column; keep the existing popup menu.
- `string_theory_flutter/lib/widgets/bag/bag_racquet_list.dart` -- grid `mainAxisExtent` 140 to about 168 so the card with button and badge fits.
- `string_theory_flutter/lib/widgets/bag/bag_snack_bars.dart` -- add `buildSuccessSnackBar`.
- `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- listener shows the success SnackBar.
- Tests: `test/bag_bloc_test.dart`, `test/widgets/racquet_card_test.dart`, `test/virtual_bag_screen_test.dart`, new `test/widgets/restring_sheet_test.dart`.

## Tasks & Acceptance

**Execution:**
- [x] `test/bag_bloc_test.dart`, `test/widgets/restring_sheet_test.dart`, `test/widgets/racquet_card_test.dart`, `test/virtual_bag_screen_test.dart` -- write failing tests for every matrix row first (red) -- TDD protocol
- [x] `lib/bloc/bag_event.dart`, `bag_state.dart`, `bag_bloc.dart` -- event, `successMessage`, handler with optimistic reset, revert, in-flight guard -- turns bloc tests green
- [x] `lib/widgets/restring_sheet.dart` -- 2-option sheet with accordion form and keys -- turns sheet tests green
- [x] `lib/widgets/racquet_card.dart`, `bag/bag_racquet_list.dart` -- button and grid height -- turns card tests green
- [x] `lib/widgets/bag/bag_snack_bars.dart`, `lib/screens/virtual_bag_screen.dart` -- success toast -- turns screen test green
- [x] `_bmad-output/implementation-artifacts/sprint-status.yaml` -- set story 4-2 to `review` (build workflow); `done` after human acceptance

**Acceptance Criteria:**
- Given a racquet card, when the user taps `[Restrung Today]`, then a sheet shows `[Keep Same & Reset]` and a collapsed `[Change Specs]`.
- Given the sheet is open, when the user taps `[Keep Same & Reset]`, then the sheet closes, the bloc receives `RestringRacquet` with `keepSame: true`, and after server success the green toast is shown.
- Given the Change Specs accordion, when valid values are submitted, then the endpoint receives exactly those specs and the card shows them.
- Given the endpoint fails, then the gauge shows its earlier health, an error SnackBar appears and no success toast does.

## Implementation Notes

- Implemented directly (no subagent). Red state verified first: bloc and sheet tests failed to compile until the symbols existed.
- Added `BagBloc.applyOptimisticRestring`, `restringSuccessMessage`, `restringFailureMessage`, and `RacquetCard.restrungTodayKey`.
- Grid card height is `BagRacquetList.gridCardExtent = 176`. The spec's "about 168" overflowed by 1px on the tablet grid (card border takes 3px), which failed 16 existing tests until raised.
- On failure only the target racquet reverts, so stream updates to other racquets during the call are kept.
- Queued offline sessions for a restrung racquet are not re-applied to the new job in the optimistic state; the server remains authoritative on the next load.
- Verification after review patches: `flutter test` 248 pass, `dart analyze` clean, `dart format` clean.

## Spec Change Log

## Review Triage Log

Layers: blind-hunter (BH), edge-case-hunter (EH), verification-gap (VG). Review pass 1, 2026-10-05.

| Finding | Verdict | Evidence / route |
|---|---|---|
| EH/BH: tension prefill rounds 52.25 to 52.3 (`toStringAsFixed(1)`) | medium | Spec says fields start with the job's values; submit unchanged would alter tension. **Patched**: prefill with `toString()`; test added |
| EH: re-selecting the current category resets custom max hours | medium | Spec says only a change resets them. **Patched**: guard `category == _category`; test added |
| VG: success adoption skips `_withPending`, unlike every sibling path | medium | `SessionEndpoint` attributes queued sessions to the active (fresh) job at sync, so the overlay is right. **Patched** for the target racquet only (others already carry it); test added |
| VG: no test with an interleaved update to another racquet (success and failure) | medium | `replaceTarget` reads latest state; could regress unseen. **Patched**: two tests added |
| BH: `applyOptimisticRestring` branches and early returns untested | low | **Patched**: unit tests for partial specs, other/unstrung racquets, unknown racquet |
| BH: white text on `healthOptimal` toast fails contrast (~2.5:1) | low | Direct fix. **Patched**: black text and icon, as used on `primaryVolt` |
| EH/BH: every failure says "Check your connection" | low | Spec I/O matrix mandates this copy for endpoint failure; 400/404 are rare. Rejected: fix adds a branch |
| BH: sheet closes before server answers, failed Change Specs loses input | low | By spec: 1-tap close, SnackBar on failure. Rejected |
| EH: server committed but response lost, UI reverts, retry duplicates event | low | Rare network race inherent to a non-idempotent RPC; pull-to-refresh recovers. Rejected: fix (refetch on failure) adds branches; revisit with an idempotency key |
| BH/EH: revert after failure uses stale `original` for the target and drops concurrent updates to it | low | Only the target racquet; the next `getVirtualBag` after a logged session is authoritative. Rejected |
| BH: `LoadBag`/stream/sync can briefly show the old snapshot mid-flight | low | Transient, converges on the server response. Rejected |
| EH: fixed grid `mainAxisExtent` overflows at larger text scale | low | Pre-existing fixed-height pattern (was 140). **Deferred** |
| EH: double tap pops a second route | false | `ModalRoute` ignores pointers while reversing, and the in-flight guard drops a duplicate event |
| EH: hanging call keeps optimistic gauge | false | `Client` has a default `connectionTimeout`; the call fails and reverts |
| EH: decimal-comma input, no upper tension bound | low | Same as `AddRacquetModal`; server accepts. Rejected |
| EH: no feedback if the racquet is gone when the event arrives | low | Unreachable from the UI (button only on loaded racquets). Rejected |
| EH: duplicate event silently dropped | low | Sheet already closed; guard is the point. Rejected |
| EH: stale "Current strings" if the job changes while the sheet is open | low | Sheet is modal and short-lived. Rejected |
| EH: optimistic job with invalid `maxRatedHours` differs from server fallback | low | UI only sends category defaults or the current value. Rejected |
| BH: optimistic reset ignores `DecayEngine`, toast hard-codes 100% | false | A fresh job is 100 health and 0 hours by definition (spec, endpoint) |
| BH: 32dp button, no toggle semantics | low | Default `MaterialTapTargetSize.padded` gives a 48dp target. Rejected |
| BH: test hygiene (repeated verify block, subscription leak, `simulateFailure` stubs) | low | Cosmetic; the endpoint gates the seams to test mode. Rejected |
| BH: Patrol and red/green commits missing; no server test | false | Patrol is Story 5.4; the server tests are from 4.1 |
| BH: duplicated field and button styling | low | Pre-existing pattern; fix is a shared-theme refactor. Rejected |
| BH: stale or repeated success toast | false | The optimistic emit between two successes makes each state distinct |

## Design Notes

The `restrung` stream message needs no protocol change. It carries 100 health and 0 hours, which the RPC response already set, so patching the current job leaves it unchanged. This settles the open deferred item about `stringJobId`; record that in `deferred-work.md` only if review disagrees.

## Verification

**Commands:**
- `cd string_theory_flutter && flutter test` -- expected: all pass, including the new tests
- `dart analyze` (repo root) -- expected: no new issues
- `dart format --set-exit-if-changed string_theory_flutter/lib string_theory_flutter/test` -- expected: exit 0

**Manual checks:**
- Run the app, open a red racquet, tap `[Restrung Today]` then `[Keep Same & Reset]`: gauge goes green and the toast appears. Repeat with `[Change Specs]` and check the card text.
