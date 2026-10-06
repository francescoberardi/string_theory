---
title: 'Map raw exceptions in BagBloc to friendly user messages'
type: 'feature'
created: '2026-10-06'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: '498a55245eb156f31a61f7f7c560dc74f0c067c0'
context:
  - '{project-root}/_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/EXPERIENCE.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `BagBloc` failure paths emit `'Failed to ...: $e'`, so users see raw exception dumps (e.g. `BagException(message: ..., statusCode: 400)`) in the bag error screen and SnackBars (epic-3 retro item 2).

**Approach:** Route every user-facing `BagBloc` error through one pure mapper (operation, error, target racquet → short plain-words copy, per the UX voice) and `debugPrint` the raw error instead.

## Boundaries & Constraints

**Always:** Classify by status code only (`BagException.statusCode` or `ServerpodClientHttpException.statusCode`, as `isPermanentSessionRejection` does); everything without a recognised code — network, timeout, 5xx, unknown, plain `Exception` — gets the operation's connection fallback. No raw error text, exception type name, or server `message` ever reaches `BagError.message` or `BagLoaded.errorMessage`. Every catch that emits a user-facing error also `debugPrint`s `'BagBloc: <operation> failed: $e'`. Keep the existing emission shapes (`BagError` vs `BagLoaded.errorMessage`, the clear-then-emit pattern, optimistic reverts) unchanged.

**Never:** No server, model, or migration changes. No l10n/intl framework. Never match on server `message` strings. Do not change which state type a failure emits (e.g. add-racquet failure still emits `BagError`). Do not touch `RacquetDetailScreen`'s `_historyError` or other non-`BagBloc` surfaces.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected message |
|----------|--------------|------------------|
| Load bag fails | any error | `Couldn't load your bag. Check your connection and try again.` |
| Add racquet, network | non-HTTP error / 5xx | `Couldn't add "{name}". Check your connection and try again.` |
| Add racquet, rejected | 400 | `Couldn't add "{name}". Check the racquet details and try again.` |
| Delete / set primary / fast-forward, network | non-HTTP error / 5xx | `Couldn't remove this racquet.` / `Couldn't set your primary racquet.` / `Couldn't fast-forward this racquet.` + ` Check your connection and try again.` |
| Seed sample bag fails | any error | `Couldn't load the sample bag. Check your connection and try again.` |
| Racquet-targeted op, 404 | delete, set primary, fast-forward, log session, restring | `That racquet is no longer in your bag.` |
| Log session, unstrung | 400 and target racquet in the pre-log state has no `activeStringJob` | `"{name}" has no strings mounted. Restring it before logging a session.` |
| Log session, duplicate workout | 409 | `This workout is already logged on another account.` |
| Log session, other permanent rejection | other non-401/408/429 4xx | `Couldn't log this session. Please try again.` |
| Offline enqueue fails | local storage throws | `Couldn't save this session. Please try again.` |
| Any op, 401 | 401 | `Your session expired. Restart the app to sign in again.` |
| Restring, network | non-HTTP error / 5xx | existing `restringFailureMessage(name)` unchanged |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/bloc/bag_bloc.dart` -- catch sites at `_onLoadBag` (~253), `_onAddRacquet` (~274), `_onDeleteRacquet` (~295), `_onSetPrimaryRacquet` (~321), `_onSeedSampleBag` (~396), `_onFastForwardRacquetAge` (~420), `_emitLogFailure` (~486, called from permanent rejection and enqueue failure), `_onRestringRacquet` (~569). Reuse `restringFailureMessage`, `_loaded`, the clear-then-emit pattern. Leave `debugPrint`-only paths (stream, queue load, sync, post-log refresh) as they are.
- `string_theory_flutter/lib/services/offline_session_queue.dart:92` -- `isPermanentSessionRejection`; reuse its status-code extraction pattern (extract a shared `statusCodeOf(Object)` helper if it avoids duplication).
- `ServerpodClientHttpException.statusCode` (serverpod_client 4.0.3) and generated `BagException.statusCode` -- read only.
- Server codes (read only): 400 bad input / no active string job, 404 racquet not found, 409 workout on another account, 401 from `tenant_resolver.dart`.
- `string_theory_flutter/test/bag_bloc_test.dart` -- asserts raw strings at ~146, ~389, ~470, ~832, ~867, ~905, ~1144; restring failure tests at ~1626 and ~1806 must keep passing.
- `string_theory_flutter/test/virtual_bag_screen_test.dart:365,803` -- feed literal messages into state; display-only, update to friendly copy for realism.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_flutter/test/bag_error_messages_test.dart` -- unit-test the mapper for every I/O Matrix row (BagException and ServerpodClientHttpException variants, plain Exception) -- TDD red first.
- [x] `string_theory_flutter/test/bag_bloc_test.dart` -- update raw-string expectations to friendly copy; add bloc tests for unstrung log (400), 409 duplicate, 404 delete, enqueue failure, and that no `errorMessage`/`BagError.message` contains the raw error text.
- [x] `string_theory_flutter/lib/bloc/bag_error_messages.dart` -- pure mapper: an operation enum + `String bagErrorMessage(BagOperation, Object error, {Racquet? racquet})` (shape is the implementer's call); copy as constants in one place.
- [x] `string_theory_flutter/lib/bloc/bag_bloc.dart` -- replace every `'Failed to ...: $e'` with the mapper, pass the target racquet from the pre-failure state, add `debugPrint` per catch; route restring 404/401 through the mapper, keep its network fallback.
- [x] `string_theory_flutter/test/virtual_bag_screen_test.dart` -- swap literal raw messages for friendly ones.

**Acceptance Criteria:**
- Given any `BagBloc` handler fails, when the error is surfaced, then the text matches the I/O Matrix and contains no exception class name, `statusCode`, or server message.
- Given a log-session rejection, when the bloc reverts the optimistic gauge, then racquets equal the pre-log list and `errorMessage` carries the mapped copy (existing clear-then-emit preserved).
- Given the raw error, when a handler fails, then a `debugPrint` line names the operation and includes the raw error.

## Implementation Notes

## Spec Change Log

## Review Triage Log

| # | Source | Finding | Verdict | Evidence / route |
|---|--------|---------|---------|------------------|
| 1 | blind, edge | logSession 401 is queued offline ("saved offline") instead of surfacing session-expired | medium | Real: `isPermanentSessionRejection` treats 401 as transient, so the bloc never maps it. Pre-existing routing, unchanged by this story (emission shapes frozen); the session is kept and syncs after restart re-auth. Defer. |
| 2 | blind, edge | Refresh `getVirtualBag` failure after a successful create/delete/set-primary/fast-forward reported as the mutation failing | medium | Real: mutation and refresh share one try (`bag_bloc.dart` add/delete/setPrimary/fastForward). Pre-existing structure, not caused by this story. Defer. |
| 3 | blind, VG | Dead `BagBloc.restringFailureMessage` static plus prefixed double import | low | Real: no caller outside the definition (repo grep); fix is a deletion. Patch. |
| 4 | blind, edge | 400/403/other 4xx on delete/set-primary/fast-forward/restring get the "check your connection" fallback | low | Real but rare: restring and fast-forward 400 need stale state (bloc guards `activeStringJob`) or invalid dev-control days; frozen Always routes unrecognised codes to the fallback; fix adds branches. Rejected. |
| 5 | blind | "Please try again" on permanent log rejections invites futile retries | low | Copy is in the approved frozen matrix; fix edits the spec. Rejected. |
| 6 | blind | `statusCodeOf` lives in the offline queue service, mapper imports it | low | No named breakage; both functions are pure. Rejected. |
| 7 | blind, edge | delete/set-primary/fast-forward read the target racquet from post-await state | false | Those operations' copy never uses the name and 404 copy is name-free, so no wrong output occurs. |
| 8 | blind | AC3 debugPrint asserted for only some operations | low | All paths share `_failure`, which logs before mapping; five operations asserted; VG layer found no gap. Rejected. |
| 9 | blind | Mapper tests miss 408/429 log, `racquetName` precedence, default name | low | 408/429 never reach the mapper on log (queued); untested branches are trivial. Rejected. |
| 10 | blind | 409 copy assumes cross-account duplicate | false | The only 409 throw is `session_endpoint.dart:119` "Workout already registered to another account". |
| 11 | blind | 401 on load shows "Restart the app" next to a "Reload Bag" button | low | Button is pre-existing, copy is frozen; reload re-runs auth-free load. Rejected. |
| 12 | edge | Log 400 on unstrung racquet might really be duration <= 0 | low | Needs unstrung racquet and invalid duration together; quick logger durations are positive. Rejected. |
| 13 | edge | Stale local strung state plus server "no active job" 400 gives "Please try again" | low | Requires concurrent restring/retire elsewhere; rare; fix needs server reason codes. Rejected. |
| 14 | edge | Empty or whitespace name renders `Couldn't add ""` | false | `add_racquet_modal.dart` trims and validates the name before dispatching `AddRacquet`. |

## Design Notes

The unstrung case is detected from bloc state (target racquet's `activeStringJob == null`) plus a 400, so server copy can change freely. 401 is surfaced, not retried: guest re-auth happens only at app start.

## Verification

**Commands:**
- `cd string_theory_flutter && flutter analyze` -- expected: no issues
- `dart format --set-exit-if-changed string_theory_flutter/lib string_theory_flutter/test` -- expected: exit 0
- `cd string_theory_flutter && flutter test` -- expected: all pass
