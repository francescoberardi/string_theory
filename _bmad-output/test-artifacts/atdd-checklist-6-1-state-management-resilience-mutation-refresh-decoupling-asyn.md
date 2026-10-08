---
stepsCompleted:
  - 'step-01-preflight-and-context'
  - 'step-02-generation-mode'
  - 'step-03-test-strategy'
  - 'step-04-generate-tests'
  - 'step-04c-aggregate'
  - 'step-05-validate-and-complete'
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-10-08'
workflowType: 'testarch-atdd'
storyId: '6.1'
storyKey: '6-1-state-management-resilience-mutation-refresh-decoupling-asyn'
storyFile: '_bmad-output/planning-artifacts/epics.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-6-1-state-management-resilience-mutation-refresh-decoupling-asyn.md'
generatedTestFiles:
  - 'string_theory_flutter/test/helpers/tdd_red_phase.dart'
  - 'string_theory_flutter/test/bag_bloc_resilience_test.dart'
  - 'string_theory_flutter/test/widgets/bag_pull_to_refresh_test.dart'
inputDocuments:
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/implementation-artifacts/epic-6-context.md'
  - '_bmad-output/test-artifacts/test-design-epic-6.md'
  - '_bmad-output/implementation-artifacts/sprint-status.yaml'
  - '_bmad/tea/config.yaml'
  - 'string_theory_flutter/lib/bloc/bag_bloc.dart'
  - 'string_theory_flutter/lib/bloc/bag_event.dart'
  - 'string_theory_flutter/lib/bloc/bag_state.dart'
  - 'string_theory_flutter/lib/bloc/bag_error_messages.dart'
  - 'string_theory_flutter/lib/services/offline_session_queue.dart'
  - 'string_theory_flutter/lib/widgets/bag/bag_racquet_list.dart'
  - 'string_theory_flutter/lib/screens/virtual_bag_screen.dart'
  - 'string_theory_flutter/test/bag_bloc_test.dart'
  - 'string_theory_flutter/test/widgets/bag_racquet_list_test.dart'
  - '.claude/skills/bmad-testarch-atdd/resources/knowledge/data-factories.md'
  - '.claude/skills/bmad-testarch-atdd/resources/knowledge/component-tdd.md'
  - '.claude/skills/bmad-testarch-atdd/resources/knowledge/test-quality.md'
  - '.claude/skills/bmad-testarch-atdd/resources/knowledge/test-healing-patterns.md'
acceptanceCriteria:
  - id: 'AC-1'
    idSource: 'generated'
    text: 'Given the player performs AddRacquet, DeleteRacquet, SetPrimaryRacquet, or FastForwardRacquetAge, when the backend mutation RPC succeeds but the subsequent getVirtualBag reload fails or times out, then BagBloc does NOT emit an error SnackBar claiming the operation failed; it retains the updated state and schedules a background re-sync.'
  - id: 'AC-2'
    idSource: 'generated'
    text: 'When the player pulls to refresh on VirtualBagScreen, RefreshIndicator.onRefresh awaits the asynchronous emission of BagLoaded or BagError (with an 8-second safety timeout) before dismissing the spinner.'
  - id: 'AC-3'
    idSource: 'generated'
    text: 'When logSession encounters an HTTP 401 Unauthorized, BagBloc treats it as permanent authentication expiry, prompts re-authentication immediately, and does NOT queue the session with the "saved offline" toast.'
---

# ATDD Checklist: Story 6.1: State Management Resilience (Mutation Refresh Decoupling, Async Pull-to-Refresh & Auth 401 Routing)

**Date:** 2026-10-08
**Author:** Francesco
**Detected Stack:** `mobile` (auto: `pubspec.yaml`; Flutter client + Serverpod backend in one repo)
**Primary Test Level:** Unit (bloc, `mocktail` client) + Component (widget, `flutter_test`)
**Story Key:** `6-1-state-management-resilience-mutation-refresh-decoupling-asyn` (sprint-status key)

---

## Step 1: Preflight & Context

### Prerequisites

- Story ACs: clear, 3 criteria (source: `epics.md` Story 6.1, TD-1..TD-3; no story spec file yet).
- Framework: `string_theory_flutter` uses `flutter_test`, `bloc_test`, `mocktail`. CI runs `flutter analyze --fatal-infos`.
- Sequencing: 6.3 (UUID tenants) is done, so Flutter fixtures already use `Namespace.nil.uuidValue`. No fixture churn expected.

### Affected Components

| Component | File | Change driven by |
| --- | --- | --- |
| BagBloc mutation handlers | `lib/bloc/bag_bloc.dart` (`_onAddRacquet`, `_onDeleteRacquet`, `_onSetPrimaryRacquet`, `_onFastForwardRacquetAge`) | AC-1 |
| Pull-to-refresh | `lib/widgets/bag/bag_racquet_list.dart` (`_onRefresh`, list + grid) | AC-2 |
| Log session routing | `lib/bloc/bag_bloc.dart` (`_onLogSession`); `isPermanentSessionRejection` in `lib/services/offline_session_queue.dart` | AC-3 |
| Re-auth prompt | `lib/bloc/bag_error_messages.dart` (`_sessionExpiredMessage`); `virtual_bag_screen.dart` listener | AC-3 |

### Current behavior (the bugs)

- **AC-1:** `_onAddRacquet` reloads inside the same `try`, so a reload failure after a successful
  `createRacquet` emits `BagError("Couldn't add …")`. Delete / setPrimary / fastForward reload only when
  the state is **not** `BagLoaded` (initial, loading, error) and then fail the same way.
- **AC-2:** `_onRefresh` adds `LoadBag` and returns immediately, so the spinner dismisses before the reload settles.
- **AC-3:** `isPermanentSessionRejection` excludes 401, so `_onLogSession` queues it offline with the
  "Session saved offline" toast, and `onLogged` fires.

### Knowledge Fragments (closed set for `mobile`)

`data-factories.md`, `component-tdd.md`, `test-quality.md`, `test-healing-patterns.md`.

---

## Step 2: Generation Mode

**Mode:** AI generation, from the story ACs, the test design, and source analysis.

**Why:** the ACs are bloc state transitions and one widget interaction. Browser recording doesn't apply:
the stack is `mobile` and Flutter renders to canvas.

---

## Step 3: Test Strategy

### Red-phase constraints

- Scaffolds compile against today's API (no new events, states or seams referenced) and stay skipped on `main`.
- Skip helper: `test/helpers/tdd_red_phase.dart`. `tddRedPhaseReason` (String) for `test`, `tddRedPhase` (bool) for `testWidgets`.
- Client mocked with `mocktail`; first `getVirtualBag` answers, later ones throw (network drop after load).

### Primary red-phase scaffolds (one per criterion)

| AC | Level | Pri | File | Scenario | First (criterion-defining) assertion | Fails today because |
| --- | --- | --- | --- | --- | --- | --- |
| AC-1 | Unit (bloc) | P1 | `test/bag_bloc_resilience_test.dart` | Loaded bag; `createRacquet` succeeds; reload throws | no `BagError` emitted | `BagError("Couldn't add \"Yonex Ezone 98\". Check your connection…")` |
| AC-2 | Component (widget) | P1 | `test/widgets/bag_pull_to_refresh_test.dart` | Fling `BagRacquetList` (mobile); `getVirtualBag` held on a `Completer`; pump 2 s | `RefreshProgressIndicator` count while reloading == 1 | `onRefresh` returns at once: count is 0 |
| AC-3 | Unit (bloc) | P1 | `test/bag_bloc_resilience_test.dart` | Loaded bag; `logSession` throws `ServerpodClientUnauthorized` | `queue.pendingCount == 0` | 401 is queued: count is 1 |

Priorities follow the test design: R-009 (AC-1, AC-2) and R-010 (AC-3), score 4, so P1.

Trailing assertions in the same leaves (they cannot change the first failure):
AC-1 no `errorMessage` on any `BagLoaded`, final racquets contain both ids. AC-2 spinner gone after the reload settles.
AC-3 no "saved offline" toast, `onLogged` not called, final `errorMessage` equals `bagErrorMessage(logSession, 401)`.

### Secondary branches (green-phase automation, no red leaves)

- **AC-1 (R-009):**
  - `DeleteRacquet`, `SetPrimaryRacquet` and `FastForwardRacquetAge` from a non-loaded state (`BagError` / `BagLoading`), RPC ok, reload throws → no failure copy emitted.
    These are the other 3 of the test design's 4 bloc tests.
  - Background re-sync is scheduled after the failed reload and, once it succeeds, the bag reconciles to server state.
    The delay and mechanism are a design decision (see Risks), so inject the timer or clock.
  - A reload that **times out** (hangs) behaves like one that throws.
  - The mutation RPC itself failing still emits the failure copy. Already covered in `bag_bloc_test.dart`, keep it green.
- **AC-2 (R-009):**
  - Reload ends in `BagError` → spinner released.
  - Reload never settles → spinner released at 8 s (`fakeAsync` / `tester.pump(8s)`), not before.
  - Grid layout (`isMobile: false`) behaves the same.
  - `VirtualBagScreen` keeps the list mounted during `BagLoading` from a refresh, so the `RefreshIndicator` isn't torn down mid-refresh.
- **AC-3 (R-010):**
  - `BagException(statusCode: 401)` is treated like `ServerpodClientUnauthorized`.
  - The optimistic gauge is reverted to the pre-log racquets.
  - The re-auth prompt itself: an actionable SnackBar or route, depending on the design decision below.
  - Offline queue `sync` with a 401 (currently "sync paused") stays out of scope unless the design says otherwise.
  - Test design 6.1/6.3 row: queue drops a session rejected with 400/404 (R-008). Already the behavior via
    `isPermanentSessionRejection`; add a regression test.

---

## Step 4: Red-Phase Scaffolds

**Execution mode:** sequential, in-session. Config `tea_execution_mode: auto` would pick subagents, but every
input was already loaded here and subagents weren't requested. No worker temp files were written.
**Worker B (E2E):** 0 tests. The Patrol suite needs a live server and can't force a reload failure or a 401. Component and bloc levels cover the criteria.

### Files

| File | Change | Leaves |
| --- | --- | --- |
| `test/helpers/tdd_red_phase.dart` | **New.** `tddRedPhaseReason` + `tddRedPhase` | – |
| `test/bag_bloc_resilience_test.dart` | **New.** Local mocks, `racquet()` factory, `loadedBlocWithFailingReload` | AC-1, AC-3 |
| `test/widgets/bag_pull_to_refresh_test.dart` | **New.** Real `BagBloc` over a mocked client, `Completer`-held reload | AC-2 |

All 3 leaves are skipped. `flutter analyze --fatal-infos` reports no issues; `dart format` made no changes.

### Red-phase evidence (`flutter test --run-skipped`, 2026-10-08)

| AC | Result | Failure (the expected reason) |
| --- | --- | --- |
| AC-1 | 🔴 | Expected empty, actual `[BagError(Couldn't add "Yonex Ezone 98". Check your connection and try again.)]` |
| AC-2 | 🔴 | Expected `<1>`, actual `<0>`: "onRefresh must await BagLoaded/BagError" |
| AC-3 | 🔴 | Expected `<0>`, actual `<1>`: "401 must not be queued" |

**Green-ability probe (AC-2):** temporarily made `_onRefresh` await the next `BagLoaded`/`BagError` (8 s
timeout): the scaffold passed. Reverted; `lib/` is unchanged.

Regular `flutter test`: **386 passed, 3 skipped, 0 failed**.

---

## Step 5: Validation & Handoff

### Checklist validation

- [x] Prerequisites satisfied (ACs clear; `flutter_test` + `mocktail` + `bloc_test`)
- [x] Criterion ids AC-1..AC-3 generated deterministically in source order; no supplied ids
- [x] Exactly one skipped leaf per criterion; every leaf title carries one declared id
- [x] Criterion-defining assertion is the first that can fail (verified by the failure messages above)
- [x] State-transition criteria exercise the transition: mutation → failed reload (AC-1), refresh in flight (AC-2), 401 rejection (AC-3)
- [x] Setup uses existing API only; no new events/states referenced
- [x] Secondary branches recorded as green-phase work (Step 3)
- [x] No browser sessions opened; artifacts stored in `_bmad-output/test-artifacts/`
- [ ] Story file link-back: N/A. `storyFile` is `epics.md` (no story spec yet). `bmad-build` should reference this checklist when it creates the spec

### Activation order (green phase, task by task)

1. **AC-3:** route 401 in `_onLogSession` before the queue branch (revert optimistic gauge, surface the
   re-auth prompt, skip `onLogged`). Un-skip AC-3; add the `BagException(401)` and gauge-revert cases.
2. **AC-1:** split each mutation handler's RPC `try` from its reload; on reload failure keep the updated state
   (add: append the returned racquet) and schedule a background re-sync. Un-skip AC-1; add delete/setPrimary/
   fastForward and re-sync cases.
3. **AC-2:** make `_onRefresh` await the next `BagLoaded`/`BagError` with an 8 s timeout, and keep the list
   mounted during refresh-triggered `BagLoading`. Un-skip AC-2; add the `BagError`, 8 s timeout and grid cases.

Run `flutter test` in `string_theory_flutter` after each step. Remove `skip:` only for the task being implemented.

### Risks & assumptions

- **AC-3 "prompts re-authentication" is underspecified.** The scaffold asserts today's prompt: the session-expired
  copy from `bagErrorMessage` ("Your session expired. Restart the app to sign in again."). If the
  implementation adds a dedicated state or event (e.g. a re-auth SnackBar action calling `authService`), update
  the trailing assertion. The criterion-defining "not queued" assertion stays.
- **AC-1 re-sync mechanism is undefined** (delay, retry count). Inject the timer so the secondary test is deterministic.
- **AC-1 for delete/setPrimary/fastForward:** with a `BagLoaded` state these handlers don't reload today, so
  the bug only shows from a non-loaded state. If the green phase adds a reload after every mutation, cover the loaded state too.
- **AC-2 `VirtualBagScreen` (confirmed):** `LoadBag` emits `BagLoading`, and `_buildBodyForState` only renders
  `BagRacquetList` for `BagLoaded`, so a real pull-to-refresh unmounts the `RefreshIndicator` mid-refresh. Fixing
  `_onRefresh` alone is not enough: either keep the racquets during a refresh (e.g. don't emit `BagLoading` when
  already loaded) or keep the list mounted. The scaffold tests `BagRacquetList` in isolation, so add a
  `VirtualBagScreen`-level test in the green phase.
- The AC-2 scaffold captures the spinner count, then settles the reload before asserting, so a red failure
  can't leave `LoadBag` pending and hang `bloc.close`.
