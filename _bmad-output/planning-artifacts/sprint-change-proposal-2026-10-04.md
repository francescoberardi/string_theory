# Sprint Change Proposal: DevOps Multi-Package CI/CD Automation

**Date:** 2026-10-04  
**Project:** string_theory  
**Status:** Approved for Implementation  
**Trigger:** Expanding GitHub Actions CI quality gates across all packages (`string_theory_server`, `string_theory_client`, `string_theory_flutter`)  

---

## 1. Issue Summary

### Problem Statement
The current continuous integration (CI) workflows configured under `.github/workflows/` (`analyze.yml`, `format.yml`, and `tests.yml`) run exclusively against the backend package (`string_theory_server`). While the project is organized as a multi-package Dart workspace (`pubspec.yaml` declaring `string_theory_server`, `string_theory_client`, and `string_theory_flutter`), GitHub Actions does not run format checks, static analysis, or automated tests on the client or Flutter packages.

### Discovery & Context
Following the completion of Epic 1, the repository contains 7 Flutter test suites (`string_theory_flutter/test/`) covering BLoCs, authentication services, theme definitions, and widget rendering. However, because Story 5.4 in the original backlog deferred full CI pipeline integration until Epic 5 (end-of-hackathon polish), the repository was operating without automated quality gates for frontend code during the development of Epics 2 through 4. This poses an unacceptable regression risk for trunk-based development on `main`.

### Evidence
1. **`.github/workflows/analyze.yml`**: Line 24 contains `working-directory: string_theory_server` running `dart analyze --fatal-infos`, completely ignoring `string_theory_flutter` and `string_theory_client`.
2. **`.github/workflows/format.yml`**: Line 24 contains `working-directory: string_theory_server` running `dart format --set-exit-if-changed .`, leaving client and Flutter Dart files unchecked.
3. **`.github/workflows/tests.yml`**: Line 49 contains `working-directory: string_theory_server` running `dart test`, ignoring all Flutter widget and unit test suites.
4. **`string_theory_flutter/test/`**: 7 test files (1,000+ lines of test code) currently run only when invoked manually.

---

## 2. Impact Analysis

### Epic Impact
- **New Technical Epic Added**: `Epic 1.5: DevOps — Multi-Package CI/CD Pipeline Automation` inserted immediately following Epic 1 and prior to starting Epic 2.
- **Epic 5**: Story 5.4 re-scoped from a broad CI/CD overhaul to dedicated headless Patrol E2E integration test automation.
- **Epics 2, 3, 4**: Scope remains unchanged, but all subsequent story implementations will be protected by automated multi-package CI quality gates.

### Story Impact
- **New Story 1.5.1**: Multi-Package Linting & Workspace Formatting in GitHub Actions (`analyze.yml` & `format.yml`).
- **New Story 1.5.2**: Multi-Package Automated Test Runner in GitHub Actions (`tests.yml`).
- **Modified Story 5.4**: Re-titled to *Patrol Headless End-to-End Test Automation in CI*, focusing on mobile/headless integration runs.

### Artifact Conflicts
- **`epics.md`**: Updated with Epic 1.5 overview, full story specifications for 1.5.1 and 1.5.2, and re-scoped Story 5.4.
- **`ARCHITECTURE-SPINE.md`**: Updated Consistency Conventions table to codify multi-package CI enforcement across all 3 workspace packages.
- **`sprint-status.yaml`**: Updated to track `epic-1-5` and its stories in `backlog` status.

### Technical & Infrastructure Impact
- GitHub Actions run times will slightly increase (~30–45s) to run `flutter analyze` and `flutter test`, while embedded PostgreSQL server tests run concurrently or in separate pipeline jobs.
- All future pull requests and commits to `main` must pass formatting, analysis, and tests across all packages to merge.

---

## 3. Recommended Approach

### Evaluation
- **Direct Adjustment (Selected)**: Insert a compact, 2-story technical epic (`Epic 1.5`) immediately to unblock safe development of Epic 2.
- **Rollback**: Not applicable; no existing functional code requires rollback.
- **PRD MVP Review**: Not needed; does not alter functional requirements or release timelines.

### Rationale
Establishing reliable CI across the entire workspace early protects developer velocity and ensures the trunk remains green and deployable as domain logic (`DecayEngine`), BLoCs, and UI widgets are added.

- **Effort Estimate**: Low (0.5 – 1 day)
- **Risk Level**: Low
- **Timeline Impact**: Negligible; saves debugging and triage time in later epics.

---

## 4. Detailed Change Proposals

### Artifact 1: `epics.md` (`_bmad-output/planning-artifacts/epics.md`)

```markdown
### Epic 1.5: DevOps — Multi-Package CI/CD Pipeline Automation
Developers and CI systems have automated linting, formatting, and unit/widget test verification running across all workspace packages (`string_theory_server`, `string_theory_client`, and `string_theory_flutter`), guarding the repository quality gate on every commit and pull request.
**Requirements covered:** TEST-1, ARCH-1, NFR-8

---

## Epic 1.5: DevOps — Multi-Package CI/CD Pipeline Automation

Ensure full CI/CD quality gate enforcement across the entire Dart workspace, preventing client, server, or frontend regressions as Epics 2 through 5 are developed.

### Story 1.5.1: Multi-Package Linting & Workspace Formatting in GitHub Actions
As a DevOps engineer and developer,  
I want GitHub Actions to run format checks and static analysis across all workspace packages,  
So that stylistic inconsistencies and compiler warnings are caught immediately in CI before merge.

**Requirements Covered:** TEST-1, ARCH-1

**Acceptance Criteria:**
- **Given** `.github/workflows/format.yml`,
- **When** triggered on push or PR to `main`,
- **Then** `dart format --set-exit-if-changed .` runs across the entire repository root workspace (verifying server, client, and flutter code).
- **Given** `.github/workflows/analyze.yml`,
- **When** triggered on push or PR to `main`,
- **Then** dependencies are resolved via `flutter pub get` in the root workspace,
- **And** static analysis runs with fatal infos across `string_theory_server`, `string_theory_client`, and `string_theory_flutter` (`flutter analyze --fatal-infos` or matrix analysis),
- **And** any analysis warning or unformatted code fails the workflow.

### Story 1.5.2: Multi-Package Automated Test Runner in GitHub Actions
As a DevOps engineer and developer,  
I want `.github/workflows/tests.yml` to run tests for both the Serverpod backend and Flutter client,  
So that regressions in server endpoints, embedded PostgreSQL persistence, BLoC state logic, or widget rendering fail fast in CI.

**Requirements Covered:** TEST-1, ARCH-1

**Acceptance Criteria:**
- **Given** `.github/workflows/tests.yml`,
- **When** triggered on push or PR to `main`,
- **Then** Job 1 installs dependencies, runs Serverpod code generation check, and executes embedded PostgreSQL backend tests (`cd string_theory_server && dart test`),
- **And** Job 2 executes Flutter unit and widget tests (`cd string_theory_flutter && flutter test`),
- **And** failure in either backend or frontend test suites halts the pipeline and blocks PR merge.

---

### Story 5.4: Patrol Headless End-to-End Test Automation in CI
- Job executes the Patrol E2E smoke test suite headlessly (or in Android emulator action),
- Verifies full integration flow from guest auth to sample bag and workout simulation,
- Blocks PR merge if end-to-end integration regression occurs.
```

### Artifact 2: `ARCHITECTURE-SPINE.md` (`_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/ARCHITECTURE-SPINE.md`)

```markdown
| **Testing Standards & CI** | Strict TDD & Multi-Package CI Quality Gate. Backend: `serverpod_test` (embedded PostgreSQL). Client: `bloc_test` & Flutter widget tests. E2E: `patrol`. GitHub Actions CI runs format (`dart format .`), analysis (`flutter analyze --fatal-infos`), and test runners across all 3 workspace packages (`string_theory_server`, `string_theory_client`, `string_theory_flutter`). | Quality Gate, CI Workflows |
```

### Artifact 3: `sprint-status.yaml` (`_bmad-output/implementation-artifacts/sprint-status.yaml`)

```yaml
  epic-1-5: backlog
  1-5-1-multi-package-linting-workspace-formatting-github-actions: backlog
  1-5-2-multi-package-automated-test-runner-github-actions: backlog
  epic-1-5-retrospective: optional

  epic-2: backlog
  ...
  5-4-patrol-headless-end-to-end-test-automation-in-ci: backlog
```

---

## 5. Implementation Handoff

### Scope Classification
- **Classification**: **Minor to Moderate** (Infrastructure enhancement, no business logic or database schema changes).
- **Handoff Recipient**: **Developer Agent (Amelia)** for direct implementation of Story 1.5.1 and Story 1.5.2.

### Success Criteria
1. `.github/workflows/format.yml` fails on any unformatted file across the root workspace, server, client, or flutter directories.
2. `.github/workflows/analyze.yml` executes analysis across all 3 packages and fails on warnings (`--fatal-infos`).
3. `.github/workflows/tests.yml` executes embedded PostgreSQL server tests and Flutter unit/widget tests cleanly.
4. Pull requests and commits targeting `main` receive green checkmarks for all three workflows.
