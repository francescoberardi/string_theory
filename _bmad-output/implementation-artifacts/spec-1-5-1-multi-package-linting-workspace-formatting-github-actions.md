---
title: 'Multi-Package Linting & Workspace Formatting in GitHub Actions'
type: 'chore'
created: '2026-10-04'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** GitHub Actions workflows (`format.yml` and `analyze.yml`) currently target only the `string_theory_server` subdirectory, leaving `string_theory_client` and `string_theory_flutter` unvalidated in CI, which risks allowing formatting inconsistencies or static analysis errors to merge into `main`.

**Approach:** Update `.github/workflows/format.yml` to execute `dart format --set-exit-if-changed .` across the entire workspace repository root, and update `.github/workflows/analyze.yml` to resolve dependencies via `flutter pub get` and execute static analysis across all workspace packages with fatal infos (`flutter analyze --fatal-infos`).

</frozen-after-approval>

## Implementation Notes

- Updated `.github/workflows/format.yml` to run `dart format --set-exit-if-changed .` across the entire root workspace without scoping to `string_theory_server`.
- Updated `.github/workflows/analyze.yml` to run `flutter analyze --fatal-infos` across the entire workspace.
- Added GitHub Actions best practices: concurrency cancellation (`cancel-in-progress: true`), read-only permissions (`contents: read`), Flutter SDK caching (`cache: true`), and 10-minute job timeouts.
- Verified locally with `dart format --output=none --set-exit-if-changed .` (passed across all 51 files) and `flutter analyze --fatal-infos` (passed across workspace).

## Review Triage Log

- finding: "Separate workflow duplication" | verdict: false | evidence: Epic 1.5 and Story 1.5.1 acceptance criteria explicitly specify separate format.yml and analyze.yml workflows to support distinct GitHub branch protection checks.
- finding: "Heavyweight Flutter SDK setup for formatting" | verdict: false | evidence: Monorepo workspace contains Flutter package string_theory_flutter; resolving workspace dependencies via flutter pub get requires Flutter SDK.
- finding: "Missing caching for dependencies and Flutter artifacts" | verdict: low | evidence: Added cache: true to subosito/flutter-action@v2 in both workflows.
- finding: "Missing concurrency cancellation" | verdict: low | evidence: Added concurrency block with cancel-in-progress: true in both workflows.
- finding: "Missing least-privilege permissions" | verdict: low | evidence: Added permissions: contents: read in both workflows.
- finding: "Root analysis tool selection in a monorepo workspace" | verdict: false | evidence: Running flutter analyze --fatal-infos at the root workspace successfully invokes static analysis across all three packages in the workspace.
- finding: "Unrestricted format check on generated code" | verdict: false | evidence: Serverpod generator already generates properly formatted code and dart format passes cleanly with 0 diffs across all 51 workspace files; Story 1.5.1 explicitly requires workspace root format checks.
- finding: "Missing job timeout specification" | verdict: low | evidence: Added timeout-minutes: 10 to jobs in both workflows.
