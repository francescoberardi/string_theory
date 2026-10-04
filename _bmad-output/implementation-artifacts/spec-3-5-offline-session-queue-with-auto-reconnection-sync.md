---
title: 'Story 3.5: Offline Session Queue with Auto-Reconnection Sync'
type: 'feature'
created: '2026-10-04'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: 'aaba6115177834c8e2397f5cb35b20ee45bdeea4'
context:
  - '_bmad-output/implementation-artifacts/epic-3-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Tennis players frequently play on courts in concrete clubs or outdoor facilities with no cellular data or Wi-Fi. Attempting to log a detected or manual workout offline currently throws network errors, leaving players unable to record court hours and failing to update racquet stringbed health.

**Approach:** Build a resilient `OfflineSessionQueue` backed by local persistence (`shared_preferences`) and JSON serialization of `SessionLog`. When a session is logged offline or network RPC fails, apply instant optimistic string decay via pure Dart `DecayEngine` to update UI gauges at 60 fps, enqueue the session with a unique client idempotency key, and automatically drain the queue to Serverpod's `SessionEndpoint` upon network reconnection via `client.connectivityMonitor` with authoritative state reconciliation.

## Boundaries & Constraints

**Always:**
- Apply optimistic gauge decay immediately to the active stringbed in `BagLoaded` state using `DecayEngine.calculateHealth(...)`.
- When offline or if network RPC fails, persist the `SessionLog` into local queue and show an informational SnackBar ("Session saved offline. Will sync when back online.") instead of a blocking error.
- Call `event.onLogged?.call()` when enqueued offline so bottom sheets close cleanly without trapping the user.
- Ensure every queued session has a unique `externalWorkoutId` (preserving existing ID if present, or generating a deterministic key like `client_offline_<timestamp>_<racquetId>` if null) to guarantee Serverpod `session_log_external_id_idx` idempotency and zero double-counting on retries.
- Listen to `client.connectivityMonitor` connection status; when transitioning to online (`connected == true`), automatically trigger queue synchronization.
- Attempt queue synchronization on app launch / `BagBloc` initialization if queued sessions exist.
- When sync finishes, reconcile authoritative state from Serverpod via `client.bag.getVirtualBag()`, emit updated state, and show a confirmation toast ("Synced X offline sessions").
- Keep un-synced sessions in queue if connectivity drops mid-sync.
- Provide clean `SessionQueueStorage` interface allowing in-memory implementation for deterministic testing.
- Maintain Court Midnight theme tokens and accessibility semantics.

**Never:**
- No database migrations, schema edits, or server protocol changes (Serverpod `SessionLog` and `SessionEndpoint` already support idempotent logging via `externalWorkoutId`).
- Never edit generated files under `lib/src/generated/` or the `string_theory_client` package.
- Do not drop queued sessions on app restart or kill; queue must persist in `SharedPreferences`.
- Never block UI or show fatal `BagError` screen on offline logging failures.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Offline manual session logging | Device offline; user logs 1h session on racquet #1 | Optimistic decay updates racquet #1 gauge immediately; session saved to local queue; `pendingSyncCount: 1`; info toast shown | Safe fallback; `onLogged` called |
| Offline detected session logging | Device offline; user confirms detected workout | Optimistic decay applied; session enqueued preserving `externalWorkoutId`; pending workout dismissed | Safe fallback; sheet closes |
| Online reconnection sync | Regains connection with 2 queued sessions | Sessions posted sequentially to `SessionEndpoint`; queue drained to 0; bag refreshed from server; toast "Synced 2 offline sessions" | Partial sync on mid-transfer drop |
| App launch with pending queue | App starts with 1 pending session and active internet | `BagBloc` loads bag and drains pending queue in background; state reconciled | Retries on next connectivity pulse |
| Duplicate sync / network retry | Session sent to server but connection dropped before response; re-sent on next pulse | Serverpod idempotent match on `externalWorkoutId` returns existing row; queue safely removes item | Idempotent duplicate handled gracefully |
| Server rejects invalid session (400) | Corrupt or invalid queued record | Item discarded from queue to avoid poisoning queue; error logged | Prevents sync deadlock |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/pubspec.yaml` -- Add `shared_preferences: ^2.5.4` dependency.
- `string_theory_flutter/lib/services/offline_session_queue.dart` -- NEW. Service managing local queue persistence (`SessionQueueStorage`), enqueuing `SessionLog`s, JSON serialization, and sync execution with `Client`.
- `string_theory_flutter/lib/bloc/bag_event.dart` -- Add `SyncOfflineSessions` event.
- `string_theory_flutter/lib/bloc/bag_state.dart` -- Add `infoMessage` and `pendingSyncCount` to `BagLoaded`.
- `string_theory_flutter/lib/bloc/bag_bloc.dart` -- Wire `OfflineSessionQueue`:
  - In `_onLogSession`: calculate optimistic decay via `DecayEngine.calculateHealth`, attempt server RPC; catch network exceptions / offline status to enqueue session locally, update optimistic `BagLoaded`, and invoke `onLogged`.
  - Wire `client.connectivityMonitor` listener to dispatch `SyncOfflineSessions` when connected.
  - Implement `_onSyncOfflineSessions`: drain queue via `client.session.logSession`, refresh bag via `client.bag.getVirtualBag()`, and emit reconciled state.
- `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Surface `infoMessage` SnackBars and display pending offline sync banner/indicator when `state.pendingSyncCount > 0`.
- `string_theory_flutter/test/services/offline_session_queue_test.dart` -- NEW. Unit tests for queue operations, persistence, JSON serialization, idempotency ID generation, and sync handling.
- `string_theory_flutter/test/bag_bloc_test.dart` -- Unit tests for offline `LogSession`, optimistic decay calculation, auto-reconnection sync, and idempotent deduplication.
- `string_theory_flutter/test/virtual_bag_screen_test.dart` -- Widget tests for offline feedback and pending sync indicator.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_flutter/pubspec.yaml` -- Add `shared_preferences: ^2.5.4` and verify `dart pub get`.
- [x] `string_theory_flutter/test/services/offline_session_queue_test.dart` -- Unit tests for `OfflineSessionQueue`: enqueue, dequeue, persistence round-trip, deduplication, and sync error recovery.
- [x] `string_theory_flutter/lib/services/offline_session_queue.dart` -- Implement `OfflineSessionQueue` and `SessionQueueStorage` (with `SharedPreferencesSessionQueueStorage` and `InMemorySessionQueueStorage`).
- [x] `string_theory_flutter/test/bag_bloc_test.dart` -- Add unit tests for:
  - Optimistic decay calculation on `LogSession` when server call fails with network exception.
  - Offline session enqueuing and `BagLoaded` emission with `pendingSyncCount: 1` and `infoMessage`.
  - `SyncOfflineSessions` draining queue, reconciling with `getVirtualBag()`, and clearing pending count.
  - Auto-reconnection listener triggering sync when `connectivityMonitor` reports `connected == true`.
- [x] `string_theory_flutter/lib/bloc/bag_state.dart` & `lib/bloc/bag_event.dart` -- Update `BagLoaded` state with `infoMessage` and `pendingSyncCount`, add `SyncOfflineSessions`.
- [x] `string_theory_flutter/lib/bloc/bag_bloc.dart` -- Implement optimistic decay, offline queueing fallback in `_onLogSession`, and `_onSyncOfflineSessions` handler with connectivity monitoring.
- [x] `string_theory_flutter/test/virtual_bag_screen_test.dart` -- Add widget tests for offline session info SnackBar and pending sync indicator banner.
- [x] `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Display offline sync indicator banner when `pendingSyncCount > 0` and show info SnackBars.

**Acceptance Criteria:**
- Given the device has no internet connection, when a session is logged, then the session is stored in a local device queue and the UI applies optimistic gauge decay immediately.
- Given pending sessions in the local device queue, when connectivity is restored, then the queue automatically posts pending sessions to Serverpod and reconciles the state.

## Implementation Notes

## Spec Change Log

## Review Triage Log

- `false` (BH-1) | `/tmp/story_3_5_diff.txt` is an ephemeral review artifact, not a patch to be applied via `git apply`.
- `false` (BH-2) | Offline caching of the entire virtual bag across cold restarts is out of scope for Story 3.5.
- `false` (BH-3, ECH-3) | In-memory `currentRacquets` already includes optimistic decay; re-applying `_withPending` on stream messages would double-count hours.
- `medium` (BH-4, ECH-1, VG-2) | Manual sessions with null `externalWorkoutId` on initial online RPC create a new key on offline retry if server commit succeeds but network response drops, breaking deduplication. Route: `patch` (fixed: generate `externalWorkoutId` upfront in `_onLogSession`).
- `false` (BH-5) | Appending to `_items` maintains list ordering in single-threaded event loop.
- `low` (BH-6, ECH-2) | If `_persist()` throws during `_drain`, the session is removed from `_items` in memory; rolling back with `items.insert(0, next)` keeps memory and disk in sync. Route: `patch` (fixed: wrapped persistence in try-catch with rollback).
- `false` (BH-7) | Bloc processes events sequentially and `_onSyncOfflineSessions` checks `pendingCount == 0` at entry.
- `false` (BH-8) | `SharedPreferences.getInstance()` caches instance in memory with negligible overhead.
- `false` (BH-9) | Instant optimistic emission is required for 60fps gauge response before async RPC.
- `false` (BH-10) | Manual retry tap on banner is out of scope; spec requires automatic sync on reconnection.
- `false` (BH-11) | Offline app startup with server unreachable is already covered by existing `LoadBag` tests.
- `false` (BH-12) | Matches existing app-wide convention of English UI strings.
- `low` (VG-1) | Missing unit test in `bag_bloc_test.dart` verifying state reconciliation when all queued sessions are permanently discarded during sync. Route: `patch` (fixed: added unit test in `bag_bloc_test.dart`).

## Design Notes

- **Optimistic Decay Calculation:**
  ```dart
  final job = targetRacquet.activeStringJob;
  if (job != null) {
    final updatedHours = (job.totalCourtHours ?? 0.0) + (durationMinutes / 60.0);
    final optimisticHealth = DecayEngine.calculateHealth(
      hoursPlayed: updatedHours,
      maxRatedHours: job.maxRatedHours ?? 20.0,
      stringingDate: job.stringingDate,
      materialCategory: job.materialCategory,
    );
    final updatedJob = job.copyWith(
      totalCourtHours: updatedHours,
      currentHealthScore: optimisticHealth,
    );
  }
  ```
- **Idempotency Guarantee:**
  If `externalWorkoutId` is not provided (manual session), generate `client_offline_${DateTime.now().microsecondsSinceEpoch}_${racquetId}` before enqueuing. Serverpod's `session_log_external_id_idx` ensures re-sending the same queued item never creates duplicate records.

## Verification

**Commands:**
- `dart analyze` in repo root -- expected: No issues found
- `dart format --set-exit-if-changed .` in `string_theory_flutter` -- expected: no formatting diffs
- `flutter test` in `string_theory_flutter` -- expected: all unit, bloc, and widget tests pass
- `flutter build web` in `string_theory_flutter` -- expected: web build succeeds
