---
title: 'Story 6.1: State Management Resilience (Mutation Refresh Decoupling, Async Pull-to-Refresh & Auth 401 Routing)'
type: 'bugfix'
created: '2026-10-08'
status: 'done'
baseline_commit: '8f474c0f54c3ad500a1e5ee0d77b990e7717dfc6'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/test-artifacts/atdd-checklist-6-1-state-management-resilience-mutation-refresh-decoupling-asyn.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `BagBloc` reports a successful add/delete/set-primary/fast-forward as failed when the follow-up `getVirtualBag` reload fails. Pull-to-refresh drops its spinner before the reload settles, and the refresh unmounts the list. A 401 on `logSession` is queued offline with a misleading "saved offline" toast.

**Approach:** Decouple each mutation's RPC from its reload: once the RPC succeeds, a failed reload keeps the updated state and schedules a silent background re-sync. Make pull-to-refresh await the reload's outcome (8 s cap) while the list stays on screen. Route a 401 on `logSession` to a re-authentication prompt, never to the queue.

**Decision (re-auth prompt):** an error SnackBar says the session expired and offers a **Sign in** action. Tapping it re-provisions a guest (`authService.loginAsGuest()`) and reloads the bag; a failed sign-in shows an error SnackBar. The new guest starts with an empty bag, which is accepted because the expired identity is unrecoverable.

## Boundaries & Constraints

**Always:** Only the mutation RPC's own failure yields failure copy. Background re-sync never emits `BagLoading` or any error, and never runs after `close()`. Every new timing (reload timeout, re-sync delay) is injectable through the `BagBloc` constructor so tests are deterministic. Existing `bag_bloc_test.dart` expectations stay green unless a test here supersedes them.

**Never:** No server, model or generated-code changes. No change to `OfflineSessionQueue.sync` 401 handling ("sync paused" stays). No change to `RestringRacquet`, `SeedSampleBag` or `SyncOfflineSessions` flows.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Add, reload fails | `BagLoaded`; `createRacquet` ok; reload throws or exceeds the timeout | `BagLoaded` with the returned racquet appended (others demoted if it is primary); no error | re-sync scheduled |
| Mutation from a non-loaded state | `BagError`/`BagLoading`; delete/setPrimary/fastForward RPC ok; reload fails | no new state emitted, no failure copy | re-sync scheduled |
| Re-sync succeeds | re-sync pending | `BagLoaded` with server racquets (pending sessions applied) | failure → retry, max 3 attempts total |
| Mutation RPC fails | any | unchanged: failure copy as today | — |
| Pull-to-refresh | list shown; reload pending | spinner stays and the list stays mounted until `BagLoaded`/`BagError`, or 8 s pass | spinner released at 8 s |
| 401 on `logSession` | `BagLoaded`; RPC throws `ServerpodClientUnauthorized` or `BagException(401)` | optimistic gauge reverted, re-auth prompt, `onLogged` not called, queue untouched, no offline toast | — |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/bloc/bag_bloc.dart` -- `_onAddRacquet` reloads inside the RPC `try`. `_onDeleteRacquet`/`_onSetPrimaryRacquet`/`_onFastForwardRacquetAge` reload only when not `BagLoaded`. `_onLogSession` checks `isPermanentSessionRejection` before queueing; reuse `_emitLogFailure`. `close()` must cancel the re-sync timer.
- `string_theory_flutter/lib/bloc/bag_event.dart` -- `LoadBag` has no payload. `LogSession.onLogged` is the callback precedent to copy.
- `string_theory_flutter/lib/bloc/bag_error_messages.dart` -- `statusCode == 401` → `_sessionExpiredMessage` for every operation.
- `string_theory_flutter/lib/services/offline_session_queue.dart` -- `statusCodeOf`, `isPermanentSessionRejection` (excludes 401; leave as is).
- `string_theory_flutter/lib/widgets/bag/bag_racquet_list.dart` -- `_onRefresh` fires `LoadBag` and returns at once (list and grid).
- `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- the `BlocConsumer` builder renders `BagLoadingIndicator` for `BagLoading`, which unmounts `RefreshIndicator`. The listener shows error SnackBars.
- `string_theory_flutter/lib/client.dart` -- global `authService` (`late`); `AuthService.loginAsGuest` dedups in-flight logins.
- Red scaffolds (skipped): `test/bag_bloc_resilience_test.dart` (AC-1, AC-3), `test/widgets/bag_pull_to_refresh_test.dart` (AC-2), with the `test/helpers/tdd_red_phase.dart` skip helper.

## Tasks & Acceptance

**Execution:**
- [x] `lib/bloc/bag_bloc.dart` -- In `_onLogSession`, route `statusCodeOf(e) == 401` before the permanent/transient split. Revert the gauge, emit the re-auth prompt, and return. -- AC-3
- [x] `lib/bloc/bag_state.dart`, `lib/bloc/bag_error_messages.dart`, `lib/screens/virtual_bag_screen.dart` -- Add `BagLoaded.reauthRequired` (in props), set with the 401 `errorMessage`. Change the logSession 401 copy to fit the action (e.g. "Your session expired. Sign in to keep logging sessions."); other operations keep theirs. The listener adds a "Sign in" `SnackBarAction` when `reauthRequired`. Add a `VirtualBagScreen.onReauthenticate` param (default `authService.loginAsGuest`, resolved at tap time); on success add `LoadBag`, on failure show an error SnackBar. -- AC-3
- [x] `lib/bloc/bag_bloc.dart` -- Split the RPC `try` from the reload in the four mutation handlers. Add a reload timeout (default 10 s), a re-sync delay (default 5 s, up to 3 attempts, via `Timer`), and constructor params for both. -- AC-1
- [x] `lib/bloc/bag_event.dart`, `lib/bloc/bag_bloc.dart` -- Add an optional `LoadBag.onSettled` callback, invoked once `_onLoadBag` emits `BagLoaded`/`BagError` (excluded from props). -- AC-2
- [x] `lib/widgets/bag/bag_racquet_list.dart` -- `_onRefresh` adds `LoadBag(onSettled: completer.complete)` and awaits it, with an 8 s timeout that is swallowed. -- AC-2
- [x] `lib/screens/virtual_bag_screen.dart` -- `buildWhen` skips a `BagLoading` that follows a `BagLoaded` with racquets, so the list stays mounted during refresh. -- AC-2
- [x] Tests -- Un-skip the 3 scaffolds one by one (AC-3, AC-1, AC-2). Add bloc cases for: delete/setPrimary/fastForward from a non-loaded state, re-sync success and retry cap, reload timeout, `BagException(401)`, the 400/404 queue-drop regression, and no re-sync after close. Add widget cases for: refresh ending in `BagError`, the 8 s cap, grid layout, and a `VirtualBagScreen` refresh keeping the list mounted. Then delete `tdd_red_phase.dart` if it's unused.

**Acceptance Criteria:**
- Given the 3 scaffolds un-skipped, when `flutter test` runs, then they pass with no remaining `skip:`.
- Given the 401 SnackBar on `VirtualBagScreen`, when the user taps Sign in, then `onReauthenticate` runs and a `LoadBag` follows; if it throws, an error SnackBar shows and no `LoadBag` is added (widget test).

## Design Notes

Await via a callback, not `bloc.stream.firstWhere`. The bloc drops a `BagLoaded` equal to the current one, so an unchanged refresh would never emit and the spinner would hang until 8 s.

## Verification

**Commands:**
- `cd string_theory_flutter && flutter analyze --fatal-infos` -- expected: no issues
- `cd string_theory_flutter && dart format --set-exit-if-changed lib test` -- expected: exit 0
- `cd string_theory_flutter && flutter test` -- expected: all pass, 0 skipped from story 6.1

## Review Triage Log

| # | Source | Finding | Verdict | Route | Evidence |
|---|--------|---------|---------|-------|----------|
| 1 | blind, edge, verif-gap other | Re-sync emits a stale server snapshot over newer concurrent state (delete, optimistic gauge, restring, full load) | medium | patch | Bloc handlers run concurrently and `_onResyncBag` emits unconditionally after its fetch; a delete that lands mid-fetch is reverted. |
| 2 | blind, edge, verif-gap other | `_armResyncTimer` overwrites a live timer, which orphans it and runs parallel re-sync chains | low | patch | A failed in-flight `_ResyncBag` re-arms after `_scheduleResync` already armed a new timer; the fix is a one-line cancel. |
| 3 | verif-gap | Non-loaded delete/setPrimary/fastForward re-sync path not asserted; `hold` completer never completed | low | patch | The parametrized cases assert only `states isEmpty`; dropping `_adoptReload` would still pass. |
| 4 | verif-gap | `LoadBag` cancelling a pending re-sync is untested | low | patch | No test dispatches `LoadBag` while a re-sync is pending; the fix is a test only. |
| 5 | verif-gap | Sign-in resolving `false` is untested | low | patch | Only the throwing callback is covered; `loginAsGuest` returns `false` without throwing. |
| 6 | blind | 401 copy test is tautological; widget test copies the literal | low | patch | The test compares the constant to its own literal and never calls `bagErrorMessage`. |
| 7 | blind | Sign in moves the user to a new, empty guest account | false | reject | The Intent's Decision explicitly accepts the empty bag because the expired identity is unrecoverable. |
| 8 | blind | A 401 on logSession discards the session instead of keeping it | false | reject | The Intent and matrix require the 401 never to reach the queue ("queue untouched"). |
| 9 | blind, edge | A mutation from a non-loaded state gives no feedback; add from non-loaded doesn't show the racquet; no feedback after re-sync gives up | false | reject | Matrix row 2 specifies "no new state emitted, no failure copy, re-sync scheduled"; row 1 defines add only from `BagLoaded`. |
| 10 | blind | LogSession and offline-sync reloads are not converted to `_tryReload` | low | reject | LogSession already treats a failed reload as non-fatal after `onLogged`; a hung reload only delays a silent refresh. The Never list excludes SyncOfflineSessions. |
| 11 | blind | A refresh that ends in `BagError` replaces the list with the full-screen error | low | reject | Pre-existing load-error rendering; matrix row 5 only requires the spinner to hold until `BagLoaded`/`BagError`. |
| 12 | blind, edge | Sign-in action exists only for logSession; a 401 in `_tryReload` is retried as a network error | low | reject | The Intent scopes re-auth to logSession; the retries are capped at 3 and silent. |
| 13 | blind | Re-sync does not drain the offline queue | low | reject | The queue drains on the next `LoadBag` or connectivity change; the fix adds branches to the re-sync path. |
| 14 | blind | Spec status `in-review` vs sprint `in-progress` | false | reject | Workflow-managed: sprint status advances to review at presentation. |
| 15 | blind, edge, verif-gap | `persist: false` on the error SnackBar: the Sign in action can auto-dismiss (or would otherwise persist) | low | reject | It's a trade-off either way; the next 401 re-prompts. Actionless SnackBars are unaffected. |
| 16 | edge | A LogSession during refresh (`BagLoading` behind the kept list) skips the optimistic gauge, and a 401 there yields a plain `BagError` without Sign in | low | reject | Needs a log tapped inside the refresh window plus an expired session; the fix adds UI-gating guards. |
| 17 | edge | A 401 from a non-loaded state shows the "Sign in" copy with no action | low | reject | Matrix row 6 defines only `BagLoaded`; the logging UI is reachable only from a loaded bag. |
| 18 | edge | `LoadBag` failing while a re-sync is pending lets a later re-sync replace `BagError` | false | reject | Replacing an error screen with fresh server data is recovery, not a defect. |
| 19 | edge | The offline queue keeps old-identity sessions after re-auth | low | reject | Replays under the new tenant hit 404 on foreign racquet ids and are dropped as permanent rejections; data loss is already accepted by the Intent. |
| 20 | edge | The bag-updates stream stays bound to the expired identity after re-auth | maybe-false | defer | Depends on whether Serverpod tears down the streaming connection on 401/key change, which would null `_bagUpdatesSubscription` via `onError`/`onDone`. |
| 21 | edge | Pull-to-refresh after the bloc closed throws `StateError` | false | reject | Same pre-existing `bloc.add` call; the list is unmounted with the screen that owns the bloc. |
