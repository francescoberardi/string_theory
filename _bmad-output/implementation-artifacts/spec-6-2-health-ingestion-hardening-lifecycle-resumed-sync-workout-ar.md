---
title: 'Story 6.2: Health Ingestion Hardening (Lifecycle Resumed Sync, Workout Arrival Queue & Permission Feedback)'
type: 'feature'
created: '2026-10-12'
baseline_commit: 'bff75225dce7e6a4b5edced153607968cbbdc3ee'
status: 'in-review'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '_bmad-output/implementation-artifacts/epic-6-context.md'
  - '_bmad-output/test-artifacts/atdd-checklist-6-2-health-ingestion-hardening-lifecycle-resumed-sync-workout-ar.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Match detection drops workouts when multi-session batches arrive or when a sheet is already active, sync does not trigger upon returning to the foreground, health plugin hangs freeze syncing without timeouts, missing permissions leave a silent empty state, and handled workout IDs are forgotten on restart.

**Approach:** Implement an app lifecycle resume listener with a 60-second cooldown gate; enforce a 5-second timeout and concurrency guard on sync; buffer detections in a FIFO queue for sequential sheet presentation; persist handled workout IDs in SharedPreferences; and surface clear permission guidance in the UI.

## Boundaries & Constraints

**Always:**
- Pure Dart `DecayEngine` remains the authoritative calculation model.
- Minimal `DetectedWorkout` mapping ensures raw health sensor records never leave the device (NFR-7).
- `syncWorkouts()` never throws and guarantees `_isSyncing = false` in a `finally` block.
- Cooldown gate strictly prevents redundant platform sync queries if resumed within 60 seconds of the previous sync.
- Handled and dismissed workout IDs persist in `SharedPreferences` across app restarts.

**Never:**
- Never drop a workout arriving while an assignment sheet is open.
- Never re-alert a user about a workout that has already been dismissed or assigned.
- Never leave `_isSyncing` locked in `true` when a health plugin query times out or fails.
- Never silently show an empty list when health permissions are explicitly denied.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Lifecycle resume after >=60s | `AppLifecycleState.resumed`, last sync 65s ago | Automatically invokes `syncWorkouts()` | Handled internally in `try-finally` |
| Lifecycle resume within cooldown | `AppLifecycleState.resumed`, last sync 15s ago | No-op, sync skipped | N/A |
| Plugin query hangs | `gateway.fetchWorkouts()` does not complete | Completes after 5s timeout with empty list, resets `_isSyncing = false` | Timeout handled safely, no crash |
| Concurrent sync calls | `syncWorkouts()` called while already in flight | Second call does not trigger duplicate gateway query | Returns early / active future |
| Multi-workout batch arrival | 2+ workouts detected | Buffers in FIFO queue; presents first; upon dismiss/complete, auto-opens next | Preserves all detected workouts |
| Arrival during open sheet | Workout detected while sheet open | Appends to FIFO queue; presented when current sheet closes | No drop or UI clash |
| Permissions denied/missing | `requestAuthorization()` returns `false` | Displays "Health permissions required" guidance card/banner | Surfaces actionable guidance |
| App restart after handling | Same workout ID in health store after restart | Skipped because ID exists in persistent storage | No duplicate prompt |

</frozen-after-approval>

## Code Map

- `string_theory_flutter/lib/services/health/native_health_sync_service.dart` -- Concurrency guard `_isSyncing`, 5-second timeout, `finally` cleanup, persistent `_seenIds` backing.
- `string_theory_flutter/lib/services/health/health_sync_service.dart` -- Strategy interface; `hasPermission` / permission status exposure.
- `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- `WidgetsBindingObserver` for lifecycle resume, 60s cooldown gate, FIFO queue for `WorkoutAssignmentSheet`, permission guidance UI.
- `string_theory_flutter/test/services/health/native_health_sync_service_hardening_test.dart` -- Unit tests for AC-2 and AC-5.
- `string_theory_flutter/test/widgets/health_sync_hardening_widget_test.dart` -- Widget and lifecycle tests for AC-1, AC-3, and AC-4.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_flutter/lib/services/health/native_health_sync_service.dart` -- Add `_isSyncing` guard, 5-second timeout on sync, and ensure `_isSyncing = false` in `finally` block (AC-2).
- [x] `string_theory_flutter/lib/services/health/native_health_sync_service.dart` -- Load and persist handled workout IDs via `SharedPreferences` so restarts do not re-alert (AC-5).
- [x] `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Implement `WidgetsBindingObserver` to trigger sync on `resumed` with a 60-second cooldown gate (AC-1).
- [x] `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Implement FIFO queue for incoming workouts so batches and in-flight arrivals present sequentially upon sheet dismiss or completion (AC-3).
- [x] `string_theory_flutter/lib/screens/virtual_bag_screen.dart` -- Surface clear "Health permissions required" guidance when permissions are denied (AC-4).
- [x] `string_theory_flutter/test/helpers/tdd_red_phase.dart` -- Unskip acceptance tests and verify 100% green pass rate across unit and widget tests.

**Acceptance Criteria:**
- Given `NativeHealthSyncService` attached to the virtual bag, when the application transitions from background to foreground (`AppLifecycleState.resumed`), then workout sync executes automatically, provided at least 60 seconds have elapsed since the prior sync (cooldown gate).
- `syncWorkouts()` enforces a 5-second timeout and guarantees `_isSyncing = false` in a `finally` block.
- When multiple tennis sessions arrive in a single batch, or workouts arrive while an assignment sheet is active, `BagBloc`/UI buffers them in a FIFO pending queue and presents each sequentially upon sheet completion or dismissal.
- When Health Connect or HealthKit permissions are missing or denied, the UI surfaces clear informational guidance rather than a silent empty list.
- Processed or dismissed workout IDs are stored in persistent storage so app restarts do not re-alert on previously handled workouts.

## Implementation Notes
- Implemented `WidgetsBindingObserver` in `VirtualBagScreen` with 60s cooldown gating using `package:clock` (`clock.now()`).
- Added concurrency guard `_isSyncing`, 5-second `syncTimeout`, and SharedPreferences persistence with key `'handled_workout_ids_v1'`.
- Added FIFO queue `_pendingWorkoutsQueue` in `VirtualBagScreen` with auto-dequeue on bottom sheet completion or dismissal.
- Added `HealthPermissionGuidance` component in Court Midnight styling displayed when `!hasPermission`.
- All 422 Flutter tests and all server tests are 100% passing.

## Spec Change Log
- 2026-10-12: Story 6.2 implementation completed and verified against all 5 acceptance criteria. Moving to in-review.

## Review Triage Log

## Design Notes

- **Persistent ID Key**: `'handled_workout_ids_v1'` in `SharedPreferences`, storing a string set.
- **Cooldown Tracking**: `DateTime? _lastSyncCompleted` stored on stateful widget/observer, comparing against `DateTime.now()` with `Duration(seconds: 60)`.
- **FIFO Queue Flow**: `final Queue<DetectedWorkout> _pendingWorkoutsQueue = Queue();` When sheet is open, new arrivals push to queue. On sheet dismiss or assignment completion, if queue is non-empty, `_openDetectedAssignmentSheet` is called with `_pendingWorkoutsQueue.removeFirst()`.
