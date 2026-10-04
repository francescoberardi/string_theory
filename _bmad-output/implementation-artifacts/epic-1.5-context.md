# Epic 1.5 Context: DevOps — Multi-Package CI/CD Pipeline Automation

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Establish automated continuous integration quality gates across all packages in the repository workspace (`string_theory_server`, `string_theory_client`, and `string_theory_flutter`). This ensures that code formatting, static analysis with fatal diagnostics, and automated tests (both embedded PostgreSQL Serverpod backend tests and Flutter BLoC/widget tests) execute on every push and pull request targeting `main`, preventing regressions and maintaining trunk stability as subsequent feature epics are developed.

## Stories

- Story 1.5.1: Multi-Package Linting & Workspace Formatting in GitHub Actions
- Story 1.5.2: Multi-Package Automated Test Runner in GitHub Actions

## Requirements & Constraints

- Format validation must enforce code style across the entire repository root workspace (verifying server, client, and flutter Dart code), failing if any file produces diffs (`dart format --set-exit-if-changed .`).
- Static analysis must cover all three workspace packages (`string_theory_server`, `string_theory_client`, and `string_theory_flutter`), resolving dependencies via `flutter pub get` in the root workspace and treating warnings or info lints as fatal errors (`--fatal-infos`).
- Automated testing must run both the Serverpod backend suite (with embedded PostgreSQL persistence) and the Flutter client test suite (`string_theory_flutter/test/`), halting the pipeline and blocking pull request merges if any test in either package fails.
- CI workflows must trigger on push and pull requests targeting the `main` branch to support trunk-based development with zero merge commits.
- Pipeline execution should complete rapidly (~30–45s incremental addition) to maintain fast feedback loops for developers.

## Technical Decisions

- **CI Provider**: GitHub Actions using Ubuntu runners (`ubuntu-latest`) with `subosito/flutter-action@v2` pinned to Flutter 3.44.4.
- **Workspace Dependency Resolution**: Root-level `flutter pub get` resolves all packages in the workspace simultaneously before analysis or test execution.
- **Workspace Formatting**: Root-level `dart format --set-exit-if-changed .` replaces single-package directory targeting to validate all workspace packages in one command.
- **Static Analysis Scope**: Analysis executes across `string_theory_server`, `string_theory_client`, and `string_theory_flutter` with `--fatal-infos` enforced to prevent compiler warnings or stylistic lints from merging.
- **Automated Test Matrix**: 
  - Backend job caches embedded PostgreSQL binaries (`~/.cache/serverpod/pg-binaries`), installs Serverpod CLI 4.0.3, verifies code generation (`serverpod generate`), and executes `dart test` in `string_theory_server`.
  - Frontend job executes Flutter unit, BLoC, and widget tests via `flutter test` in `string_theory_flutter`.
- **Quality Gate Invariant**: All workflows (`format.yml`, `analyze.yml`, `tests.yml`) must pass green before merging to `main`.

## Cross-Story Dependencies

- Story 1.5.1 (formatting and static analysis) and Story 1.5.2 (automated tests) can be developed independently or in parallel, but both must pass for Epic 1.5 completion.
- Both stories depend on the existing baseline tests and code in `string_theory_server` and `string_theory_flutter` passing cleanly.
- Epics 2 through 5 depend on Epic 1.5's CI quality gates to automatically validate all future server endpoints, pure Dart `DecayEngine` calculations, BLoC logic, and UI widgets before merging into `main`.
