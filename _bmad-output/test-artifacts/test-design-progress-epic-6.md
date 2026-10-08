---
runScope: 'epic-level'
runKey: 'epic-6'
workflowStatus: 'completed'
totalSteps: 5
stepsCompleted: ['step-01-detect-mode', 'step-02-load-context', 'step-03-risk-and-testability', 'step-04-coverage-plan', 'step-05-generate-output']
lastStep: 'step-05-generate-output'
nextStep: ''
lastSaved: '2026-10-08'
---

## Step 1: Mode

- Mode: Epic-Level (user named Epic 6; sprint-status.yaml exists)
- Epic: 6 — Technical Debt, Concurrency & Production Polish
- Inputs: `_bmad-output/planning-artifacts/epics.md` (Epic 6, Stories 6.1–6.5), architecture doc
- Emphasis requested: Story 6.3 native UUID tenant migration

## Step 2: Context

- Stack: mobile (Flutter) + backend (Serverpod/Dart) — fullstack
- Inputs: epics.md (Epic 6, TD-1..TD-14), architecture/ARCHITECTURE-SPINE.md, server models (*.spy.yaml), tenant_resolver.dart, daily_decay_future_call.dart, session_endpoint.dart, bag_channels.dart, .github/workflows/tests.yml
- Fragments: risk-governance, probability-impact, test-levels-framework, test-priorities-matrix, nfr-criteria, playwright-cli
- Browser exploration: skipped (Flutter canvas app; no playwright-cli flows apply)
- Existing tests: server integration (bag_endpoint 29, session_endpoint 16, bag_stream 8, daily_decay 7, tenant_resolver), server unit (tenant_resolver 21, decay_engine 13); Flutter unit/widget/bloc (~30 files), patrol app test, e2e walkthrough
- Key findings:
  - Current int userId = UUID mod int64-max (lossy, 128→63 bit); not reversible from the int alone. Existing rows can only be re-keyed by recomputing the mapping for each serverpod_auth_core_user.id and joining.
  - Server test fixtures use numeric identifiers ('101', '1', '3201') via AuthenticationOverride.authenticationInfo; these will not parse as UuidValue after migration.
  - BagChannels.forUser(int) and SessionEndpoint dedup (global unique externalWorkoutId, cross-tenant 409) change shape.
  - DailyDecayService has no lock and writes currentHealthScore unconditionally; no broadcast.
  - CI: env secrets defined only in the server job; drift check already scoped to `lib/src/generated/ ../string_theory_client`.

## Step 3: Risk & Testability

15 risks; 5 high (R-001=9 BLOCK, R-002, R-003, R-005, R-006 = 6). See test-design-epic-6.md.

## Step 4: Coverage

P0 22, P1 31, P2 11, P3 2 (66 scenarios, ~66–95 h). PR-only execution plus a migration harness job.

## Step 5: Output

- Mode: epic-level, sequential
- Output: `_bmad-output/test-artifacts/test-design-epic-6.md`
- Checklist: validated (epic-level items); system-level/handoff items N/A
