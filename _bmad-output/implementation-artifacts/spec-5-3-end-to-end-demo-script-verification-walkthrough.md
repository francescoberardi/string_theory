---
title: 'Story 5.3: End-to-End Demo Script & Verification Walkthrough'
type: 'feature'
created: '2026-10-06'
status: 'done'
baseline_commit: '639021e3b9741928e9ab01c31aade906949d0dfb'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '{project-root}/_bmad-output/implementation-artifacts/epic-5-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Hackathon presenters and judges need a bulletproof, deterministic end-to-end demonstration script and automated widget/end-to-end walkthrough verifying the complete String Theory loop in <90 seconds without regressions across client and server.

**Approach:** 
1. Author a comprehensive presenter markdown guide (`docs/DEMO_SCRIPT.md`) detailing the exact 90-second judge narrative step-by-step:
   - Step 1: Instant anonymous guest authentication (<500ms).
   - Step 2: 1-Tap "Load Sample Bag" seeding 3 racquets across Green, Amber, Red health tiers.
   - Step 3: Apple Health / Health Connect simulated workout ingestion (<3s assignment).
   - Step 4: Real-time dynamic decay calculation & WebSocket gauge drop from 76% to 67%.
   - Step 5: 1-Tap "Restrung Today" 100% green reset and archived string job timeline inspection.
   - Step 6: Multi-platform adaptations (responsive drawer/rail and keyboard shortcuts `L`, `N`, `S`, `Esc`).
2. Create an automated end-to-end Flutter walkthrough test (`string_theory_flutter/test/e2e/judge_showcase_walkthrough_test.dart`) executing this full 5-step loop deterministically with timing assertions ensuring completion well under 90 seconds.

## Boundaries & Constraints

**Always:**
- Ensure the automated walkthrough test exercises the real state machines: Guest Auth -> Load Sample Bag -> Simulate Workout -> Assign Workout -> Verify Health Score Drop -> Restring Racquet -> Verify 100% Reset -> Verify Timeline Archive.
- Ensure the demo documentation provides clear cues, presenter speaking points, timing guidelines, and fallback recovery instructions.
- Ensure full workspace passes `dart analyze`, `dart format`, and all unit/widget/integration tests.

**Never:**
- Do not introduce flaky delays or uncontrolled timeouts in the automated test.
- Do not modify backend data contracts or breaking schema changes.

## I/O & Edge-Case Matrix

| Step | State / User Action | Expected Result | Verification Check |
|------|--------------------|-----------------|--------------------|
| 1. App Launch | Fresh session launch | Guest token auto-initialized, empty state shown with `[⚡ Load Sample Bag]` | Finds `Load Sample Bag` CTA |
| 2. Sample Bag | Tap `[⚡ Load Sample Bag]` | 3 racquets loaded: Wilson Blade (76% green), Babolat Pure Aero (48% amber), Head Radical (34% red) | All 3 racquets displayed with gauge values |
| 3. Ingestion | Tap `[🧪 Simulate Workout]` | Pending workout banner appears with tennis session metadata | Unassigned workout banner shown |
| 4. Assignment | Tap `Assign` to Wilson Blade | Workout logged, gauge drops from 76% to 67%, SnackBar confirms decay | Health drops, racquet updated |
| 5. Restring | Tap `Restrung Today` on Head Radical | Radical resets to 100% (Green), Restring Event recorded | Radical shows 100%, health green |
| 6. Timeline | Open Head Radical detail screen | Restring history shows previous dead string job archived | Timeline tile rendered |

</frozen-after-approval>

## Code Map

- `docs/DEMO_SCRIPT.md` -- Step-by-step hackathon judge demonstration script with speaking cues and <90s timeline.
- `string_theory_flutter/test/e2e/judge_showcase_walkthrough_test.dart` -- Automated deterministic E2E walkthrough test.
- `_bmad-output/implementation-artifacts/sprint-status.yaml` -- Sprint tracking status updates.

## Tasks & Acceptance

**Execution:**
- [x] Create `docs/DEMO_SCRIPT.md` containing the complete 90-second judge walkthrough script, talking points, keyboard shortcuts, and troubleshooting guide.
- [x] Create `string_theory_flutter/test/e2e/judge_showcase_walkthrough_test.dart` verifying the full 5-step judge demonstration path with fake/mock services in <90 seconds.
- [x] Run full test suite (`flutter test`, server `dart test`) and static analysis (`dart analyze`, `dart format`).

**Acceptance Criteria:**
- Given a fresh session,
- When following the demo path (Guest auth, Load Sample Bag, Simulate Workout, Assign to Wilson Blade, Restring Head Radical),
- Then the entire sequence completes cleanly without errors,
- And `docs/DEMO_SCRIPT.md` provides complete presenter guidance for a <90s live demo,
- And all tests and analysis pass.

## Implementation Notes
- Created `docs/DEMO_SCRIPT.md` with detailed timestamp breakdown (0:00 to 1:30), presenter talking points, visual cues, keyboard shortcuts reference, and fallback troubleshooting strategies.
- Implemented `string_theory_flutter/test/e2e/judge_showcase_walkthrough_test.dart` walking through all 6 core judge showcase steps (launch empty state -> seed sample bag -> ingest workout -> real-time decay drop to 67% -> restring Head Radical to 100% -> inspect historical timeline) completing in under 2 seconds.
- Verified workspace passes `dart analyze string_theory_flutter`, formatting checks, Flutter widget/e2e tests, and all Serverpod embedded PostgreSQL integration tests.

## Spec Change Log

## Review Triage Log
