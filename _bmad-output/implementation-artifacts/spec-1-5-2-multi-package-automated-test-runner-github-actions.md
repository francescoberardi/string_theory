---
title: 'Multi-Package Automated Test Runner in GitHub Actions'
type: 'chore'
created: '2026-10-04'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** GitHub Actions workflow `tests.yml` currently runs only the Serverpod backend tests in `string_theory_server`, leaving `string_theory_flutter` unit and widget tests unverified in CI, which risks allowing regressions in UI, BLoC state logic, and theme components to merge into `main`.

**Approach:** Update `.github/workflows/tests.yml` to execute two dedicated test jobs: Job 1 for backend tests (`string_theory_server` Serverpod generate and embedded PostgreSQL `dart test`), and Job 2 for frontend tests (`string_theory_flutter` `flutter test`), with CI best practices (concurrency cancellation, least-privilege permissions, job timeouts, and action caching) ensuring failure in either halts the pipeline and blocks PR merge.

</frozen-after-approval>

## Implementation Notes

- Updated `.github/workflows/tests.yml` to split test execution into two dedicated parallel jobs: `server-tests` (Serverpod Backend Tests) and `flutter-tests` (Flutter Frontend Tests).
- Configured `server-tests` to install dependencies via `flutter pub get`, cache embedded PostgreSQL binaries at `~/.cache/serverpod/pg-binaries`, install `serverpod_cli@4.0.3`, verify code generation via `serverpod generate` and `git diff --exit-code` in `string_theory_server`, and run `dart test` in `string_theory_server`.
- Configured `flutter-tests` to install dependencies via `flutter pub get` and execute unit and widget tests via `flutter test` in `string_theory_flutter`.
- Integrated GitHub Actions best practices across the workflow: workflow-level concurrency cancellation for branches (`cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}`), least-privilege permissions (`contents: read`), action caching (`cache: true` for `subosito/flutter-action@v2`), and job timeouts (15m for backend, 10m for frontend).
- Validated locally: `flutter test string_theory_flutter` (40/40 tests passed), `cd string_theory_server && dart test` (12/12 integration tests passed), `dart format --output=none --set-exit-if-changed .` (51 files formatted, 0 changes), and `flutter analyze --fatal-infos` (0 issues).

## Review Triage Log

- finding: "Missing code generation drift check in server-tests" | verdict: medium | evidence: Added `git diff --exit-code` following `serverpod generate` in `server-tests` to ensure model or endpoint changes without committed generated code cause CI to fail.
- finding: "Unconditional cancel-in-progress: true cancels in-flight test runs on main" | verdict: medium | evidence: Patched concurrency block to `cancel-in-progress: ${{ github.ref != 'refs/heads/main' }}` ensuring all pushes to `main` complete CI test verification.
- finding: "Missing PR head ref scoping in concurrency group" | verdict: low | evidence: Updated concurrency group to `${{ github.workflow }}-${{ github.head_ref || github.ref }}` for proper PR branch deduplication.
- finding: "Missing .gitignore entry for root build/ directory" | verdict: low | evidence: Workspace subpackages manage their own build outputs and root worktree remains clean; not relevant to CI workflow changes.
- finding: "Missing Dart test GitHub Actions reporter in server-tests" | verdict: low | evidence: Standard `dart test` console output matches acceptance criteria and prints detailed progression without extra action dependencies.
- finding: "Missing dependency lockfile enforcement in CI" | verdict: false | evidence: Workspace monorepo dependency resolution uses `flutter pub get` across all packages identically to format.yml and analyze.yml.
- finding: "Status mismatch between sprint-status.yaml / spec and code review phase" | verdict: false | evidence: Per step-oneshot workflow, status transitions to `review`/`done` during the spec finalization stage following review triage.
