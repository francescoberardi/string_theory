---
stepsCompleted:
  - 'step-01-preflight-and-context'
  - 'step-02-generation-mode'
  - 'step-03-test-strategy'
  - 'step-04-generate-tests'
  - 'step-04c-aggregate'
  - 'step-05-validate-and-complete'
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-10-12'
workflowType: 'testarch-atdd'
storyId: '6.2'
storyKey: '6-2-health-ingestion-hardening-lifecycle-resumed-sync-workout-ar'
storyFile: '_bmad-output/planning-artifacts/epics.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-6-2-health-ingestion-hardening-lifecycle-resumed-sync-workout-ar.md'
generatedTestFiles:
  - 'string_theory_flutter/test/helpers/tdd_red_phase.dart'
  - 'string_theory_flutter/test/services/health/native_health_sync_service_hardening_test.dart'
  - 'string_theory_flutter/test/widgets/health_sync_hardening_widget_test.dart'
inputDocuments:
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/implementation-artifacts/epic-6-context.md'
  - '_bmad-output/test-artifacts/test-design-epic-6.md'
  - '_bmad-output/implementation-artifacts/sprint-status.yaml'
  - '_bmad/tea/config.yaml'
  - 'string_theory_flutter/lib/services/health/health_sync_service.dart'
  - 'string_theory_flutter/lib/services/health/native_health_sync_service.dart'
  - 'string_theory_flutter/lib/screens/virtual_bag_screen.dart'
  - 'string_theory_flutter/test/services/health/native_health_sync_service_test.dart'
  - 'string_theory_flutter/test/widgets/workout_assignment_sheet_test.dart'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/data-factories.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/component-tdd.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-quality.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-healing-patterns.md'
acceptanceCriteria:
  - id: 'AC-1'
    idSource: 'generated'
    text: 'Given NativeHealthSyncService attached to the virtual bag, when the application transitions from background to foreground (AppLifecycleState.resumed), then workout sync executes automatically, provided at least 60 seconds have elapsed since the prior sync (cooldown gate).'
  - id: 'AC-2'
    idSource: 'generated'
    text: 'syncWorkouts() enforces a 5-second timeout and guarantees _isSyncing = false in a finally block.'
  - id: 'AC-3'
    idSource: 'generated'
    text: 'When multiple tennis sessions arrive in a single batch, or workouts arrive while an assignment sheet is active, BagBloc/UI buffers them in a FIFO pending queue and presents each sequentially upon sheet completion or dismissal.'
  - id: 'AC-4'
    idSource: 'generated'
    text: 'When Health Connect or HealthKit permissions are missing or denied, the UI surfaces clear informational guidance rather than a silent empty list.'
  - id: 'AC-5'
    idSource: 'generated'
    text: 'Processed or dismissed workout IDs are stored in persistent storage so app restarts do not re-alert on previously handled workouts.'
---

# ATDD Checklist: Story 6.2: Health Ingestion Hardening (Lifecycle Resumed Sync, Workout Arrival Queue & Permission Feedback)

**Date:** 2026-10-12  
**Author:** Francesco  
**Detected Stack:** `mobile` (`pubspec.yaml`; Flutter client + Serverpod backend in workspace)  
**Primary Test Level:** Unit (Service, `NativeHealthSyncService`) + Component/Widget (`VirtualBagScreen` / `WorkoutAssignmentSheet`)  
**Story Key:** `6-2-health-ingestion-hardening-lifecycle-resumed-sync-workout-ar`  

---

## Step 1: Preflight & Context

### Prerequisites

- Story ACs: 5 criteria (source: `epics.md` Story 6.2, TD-4..TD-6; `epic-6-context.md`).
- Test Framework: `string_theory_flutter` uses `flutter_test`, `mocktail`, `shared_preferences`. CI enforces `flutter analyze --fatal-infos`.
- Sequencing: Story 6.3 (UUID tenant migration) and Story 6.1 (state management resilience) are complete and green.

### Affected Components

| Component | File | Change driven by |
| --- | --- | --- |
| Lifecycle sync & Cooldown | `lib/screens/virtual_bag_screen.dart` (`WidgetsBindingObserver`, `didChangeAppLifecycleState`) | AC-1 |
| Sync timeout & concurrency guard | `lib/services/health/native_health_sync_service.dart` (`syncWorkouts`, `_isSyncing`) | AC-2 |
| Workout FIFO Queue & sequential sheets | `lib/screens/virtual_bag_screen.dart` (`_workoutQueue`, sheet dismiss callback) | AC-3 |
| Permission feedback UI | `lib/screens/virtual_bag_screen.dart` / `lib/widgets/health/health_permission_guidance.dart` | AC-4 |
| Workout ID persistence across restarts | `lib/services/health/native_health_sync_service.dart` (backed by `SharedPreferences` / `WorkoutIdStorage`) | AC-5 |

### Current behavior (the gaps)

- **AC-1:** `VirtualBagScreen` does not observe app lifecycle changes (`WidgetsBindingObserver`). When the app is resumed from background, no sync is initiated, and there is no 60-second cooldown gate.
- **AC-2:** `NativeHealthSyncService.syncWorkouts()` has no timeout (hangs if plugin hangs) and no `_isSyncing` guard (concurrent callers can trigger redundant overlapping queries).
- **AC-3:** `_flushDetections()` only opens `batch.first`. Any other workouts in the batch or arriving while a sheet is open are ignored/dropped from presentation instead of being queued FIFO.
- **AC-4:** When `requestAuthorization()` returns `false`, `NativeHealthSyncService` returns `const []` silently. The UI shows no guidance explaining missing or denied permissions.
- **AC-5:** `_seenIds` in `NativeHealthSyncService` is purely an in-memory set. Restarting the app with fresh service instances forgets handled workouts, leading to duplicate alerts.

### Knowledge Fragments (closed set for `mobile`)

`data-factories.md`, `component-tdd.md`, `test-quality.md`, `test-healing-patterns.md`.

---

## Step 2: Generation Mode

**Mode:** AI generation from story ACs, test architecture design (`test-design-epic-6.md`), and codebase analysis.  
**Rationale:** The ACs target Flutter lifecycle hooks, asynchronous service timeouts, queue management, and UI guidance rendering. Headless widget and unit tests provide fast, deterministic validation.

---

## Step 3: Test Strategy

### Red-phase constraints

- Scaffolds compile against current code and stay skipped on `main` via `tdd_red_phase.dart`.
- Skip helper: `test/helpers/tdd_red_phase.dart` (`tddRedPhaseReason` for `test`, `tddRedPhase` for `testWidgets`).
- Mocks and fakes: `FakeHealthGateway`, `ControllableHealthGateway`, `FakeHealthSyncService`.

### Primary red-phase scaffolds (one per criterion)

| AC | Level | Pri | File | Scenario | First (criterion-defining) assertion | Red failure reason |
| --- | --- | --- | --- | --- | --- | --- |
| **AC-1** | Component (widget) | P1 | `test/widgets/health_sync_hardening_widget_test.dart` | App resumes after 65s cooldown | `fakeHealthService.syncCalls == 2` | `<1>`: no lifecycle listener exists |
| **AC-2** | Unit / Widget | P1 | `test/services/health/native_health_sync_service_hardening_test.dart` | Gateway hangs indefinitely; 5s timeout elapses | `syncCompleted == true` | Hangs: no 5s timeout or concurrency guard |
| **AC-3** | Component (widget) | P1 | `test/widgets/health_sync_hardening_widget_test.dart` | Batch of 2 workouts arrives; first sheet dismissed | `find.byType(WorkoutAssignmentSheet) findsOneWidget` (workout 2) | Second workout never opens upon dismissing first |
| **AC-4** | Component (widget) | P2 | `test/widgets/health_sync_hardening_widget_test.dart` | Health permissions denied | `find.textContaining('Health permissions required') findsOneWidget` | Found 0 widgets: no permission guidance in UI |
| **AC-5** | Unit | P1 | `test/services/health/native_health_sync_service_hardening_test.dart` | Workout dismissed; new service instance created | `detectedAfterRestart.isEmpty` | Length is 1: IDs not persisted across restarts |

### Secondary branches (green-phase automation)

- **AC-1:** Resume before 60 seconds elapsed is ignored (cooldown gate). Resume during an active sync does not trigger duplicate sync.
- **AC-2:** Error in gateway during sync resets `_isSyncing` in `finally` so subsequent syncs proceed. Concurrent caller while syncing returns empty list or existing future without secondary fetch.
- **AC-3:** Workouts arriving while sheet is open are queued. Assigning racquet advances queue; tapping skip/dismiss also advances queue. FIFO order preserved across 3+ workouts.
- **AC-4:** Clicking guidance opens settings or re-requests authorization. Permission granted state removes guidance.
- **AC-5:** Persisted storage read on startup initializes seen IDs. Corrupt storage key recovers gracefully with empty set.

---

## Step 4: Red-Phase Scaffolds & Evidence

### Files Created

| File | Type | Covers |
| --- | --- | --- |
| `test/helpers/tdd_red_phase.dart` | Helper | `tddRedPhaseReason`, `tddRedPhase` skip toggles |
| `test/services/health/native_health_sync_service_hardening_test.dart` | Service Unit Tests | AC-2, AC-5 |
| `test/widgets/health_sync_hardening_widget_test.dart` | Widget / Lifecycle Tests | AC-1, AC-3, AC-4 |

### Red-Phase Evidence (`flutter test --run-skipped`, 2026-10-12)

```
Failing tests (5 of 5 failed as expected in red phase):
  • [P1] [AC-1] app lifecycle resumed triggers workout sync when 60s cooldown gate has elapsed
    Expected: <2>
      Actual: <1> (Reason: no AppLifecycle listener or resumed sync on VirtualBagScreen)

  • [P1] [AC-2] syncWorkouts enforces a 5-second timeout and guarantees _isSyncing = false in a finally block
    Test timed out / failed assertion: syncWorkouts hung indefinitely without 5s timeout

  • [P1] [AC-3] multiple workouts or arrivals while sheet is active are buffered in FIFO order and presented sequentially
    Expected: exactly one matching candidate
      Actual: Found 0 widgets with text "1h 30m" (Reason: second workout dropped, not queued)

  • [P2] [AC-4] missing or denied health permission surfaces clear informational guidance in the UI
    Expected: exactly one matching candidate
      Actual: Found 0 widgets with text containing "Health permissions required"

  • [P1] [AC-5] processed or dismissed workout IDs are stored in persistent storage across restarts
    Expected: empty list
      Actual: [<DetectedWorkout: TENNIS-PERSIST-1>] (Reason: handled IDs not persisted)
```

**Normal Test Run (`flutter test`):**  
**417 passed, 5 skipped, 0 failed** (100% green on `main`).

---

## Step 5: Validation & Handoff

### Checklist Validation

- [x] Prerequisites satisfied (Acceptance Criteria defined in `epics.md` and `epic-6-context.md`).
- [x] Deterministic criteria naming (`AC-1` through `AC-5`).
- [x] Exactly one primary red-phase scaffold per criterion.
- [x] Criterion-defining assertion is the first to fail under `--run-skipped`.
- [x] Clean compilation with `flutter analyze --fatal-infos` (0 issues).
- [x] Code formatted with `dart format`.
- [x] CI/Trunk safety: tests skipped on `main` via `tdd_red_phase.dart`, preserving a green build.

### Green-Phase Implementation Plan (`bmad-build`)

1. **Task 1 (AC-2):** Add `_isSyncing` boolean flag, 5s timeout on `fetchWorkouts`, and reset `_isSyncing = false` in `finally` inside `NativeHealthSyncService.syncWorkouts()`. Unskip AC-2.
2. **Task 2 (AC-5):** Implement persistent handled workout ID storage in `NativeHealthSyncService` using `SharedPreferences`. Unskip AC-5.
3. **Task 3 (AC-1):** Add `WidgetsBindingObserver` to `VirtualBagScreen`, listen to `AppLifecycleState.resumed`, and enforce 60s cooldown gate before calling `syncWorkouts()`. Unskip AC-1.
4. **Task 4 (AC-3):** Implement FIFO `Queue<DetectedWorkout>` in `VirtualBagScreen` / state management to sequentially present pending sheets on assign or dismiss. Unskip AC-3.
5. **Task 5 (AC-4):** Expose permission status in `HealthSyncService` and display clear guidance widget in `VirtualBagScreen` when permissions are denied. Unskip AC-4.
