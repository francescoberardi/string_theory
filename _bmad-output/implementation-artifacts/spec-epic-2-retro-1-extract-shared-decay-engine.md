---
title: 'Extract Shared Pure Dart Package for DecayEngine & Health Tiers'
type: 'refactor'
created: '2026-10-06'
status: 'done'
baseline_commit: '3e5f46a2e71fc25adb8f3c91ad0d8fc4eac2c901'
route: 'dispatch'
review_loop_iteration: 0
context:
  - 'AGENTS.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `DecayEngine` domain calculation logic and string material defaults are currently duplicated across `string_theory_server` and `string_theory_flutter`, while health-tier thresholds (70% and 40%) are hardcoded independently across UI widgets and server routines.

**Approach:** Extract shared pure Dart decay calculation logic into a dedicated workspace package `string_theory_decay_engine` containing `DecayEngine`, `HealthTier`, `StringCategoryDefaults`, and string category lookup helpers, and consume it across `string_theory_server` and `string_theory_flutter`.

## Boundaries & Constraints

**Always:**
- Keep `string_theory_decay_engine` as a pure Dart package with zero external framework dependencies (no Serverpod server, no Flutter SDK).
- Support polymorphic `Enum` inputs for `materialCategory` so both server-generated and client-generated `StringMaterialCategory` enums work seamlessly without manual conversion.
- Maintain 100% test parity for all existing `DecayEngine` unit tests in both server and flutter packages, plus add dedicated domain unit tests in `string_theory_decay_engine`.
- Maintain typed `StringMaterialCategoryExtension` in `string_theory_flutter` backed by decay engine defaults to avoid global `Enum` extension pollution.
- Follow strict TDD Red-Green-Refactor protocol and Conventional Commits.

**Never:**
- Never edit generated files in `string_theory_server/lib/src/generated/` or `string_theory_client/`.
- Never introduce a dependency from `string_theory_decay_engine` to `serverpod` or `flutter`.
- Never modify Serverpod `.spy.yaml` database models or migrations for this refactoring.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Health Tier - Optimal | `healthScore >= 70` | `HealthTier.optimal` (semantics: 'Optimal condition') | Clamped to 0..100 |
| Health Tier - Degraded | `40 <= healthScore < 70` | `HealthTier.degraded` (semantics: 'Degraded condition') | Clamped to 0..100 |
| Health Tier - Critical | `healthScore < 40` | `HealthTier.critical` (semantics: 'Critical condition, high shock risk') | Clamped to 0..100 |
| Dynamic & Calendar Decay | 10h played of 20h, 75 days elapsed on Co-Poly (shelf life 75d) | Dynamic = 35%, Calendar = 30%, Total = 65% penalty -> Health = 35 (Critical) | Clamped to [0, 100] |
| Polymorphic Enum Category | Server `StringMaterialCategory.coPoly` or Client `StringMaterialCategory.coPoly` | Same shelf life (75 days) and max hours (20.0) resolved via `asNameMap()` | Fallback to `other` (180 days, 20.0h) for unrecognized enums |
| Tension Loss Text | Health = 100%, installed = 52.0 lbs | `'~0.0 kg / ~0.0 lbs drop'` | Handled directly |
| Zero / Negative Bounds | `hoursPlayed = -5`, `maxRatedHours = 0` | Effective hours = 0, effective max = 1.0 -> no crash, clamped health | Handled gracefully |

</frozen-after-approval>

## Code Map

- `pubspec.yaml` -- Workspace root: register `string_theory_decay_engine` package in `workspace:`.
- `string_theory_decay_engine/pubspec.yaml` -- Pure Dart package definition (`resolution: workspace`).
- `string_theory_decay_engine/lib/string_theory_decay_engine.dart` -- Public library barrel export.
- `string_theory_decay_engine/lib/src/decay_engine.dart` -- Pure Dart `DecayEngine` calculation and tier classification.
- `string_theory_decay_engine/lib/src/health_tier.dart` -- `HealthTier` enum (optimal, degraded, critical) with thresholds, predicates, and semantic descriptions.
- `string_theory_decay_engine/lib/src/string_category_defaults.dart` -- Category shelf life, default max hours, and display name lookups.
- `string_theory_decay_engine/test/decay_engine_test.dart` -- Dedicated unit test suite for the shared decay engine package.
- `string_theory_server/pubspec.yaml` -- Add `string_theory_decay_engine` workspace dependency.
- `string_theory_server/lib/src/domain/decay_engine.dart` -- Re-export `package:string_theory_decay_engine/string_theory_decay_engine.dart`.
- `string_theory_server/lib/src/future_calls/daily_decay_future_call.dart` -- Verify scheduled worker uses shared decay engine.
- `string_theory_flutter/pubspec.yaml` -- Add `string_theory_decay_engine` workspace dependency.
- `string_theory_flutter/lib/domain/decay_engine.dart` -- Re-export decay engine package and provide typed `StringMaterialCategoryExtension`.
- `string_theory_flutter/lib/widgets/radial_health_gauge.dart` -- Consume `HealthTier` for status colors and semantics labels.
- `string_theory_flutter/lib/widgets/racquet_card.dart` -- Consume `HealthTier.critical` instead of hardcoded `< 40`.
- `string_theory_flutter/lib/screens/racquet_detail_screen.dart` -- Consume `HealthTier.critical` instead of hardcoded `< 40`.
- `string_theory_flutter/lib/widgets/add_racquet_modal.dart` -- Use shared `StringCategoryDefaults` from decay engine.
- `.github/workflows/tests.yml` -- Add `decay-engine-tests` CI job for `string_theory_decay_engine`.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_decay_engine/pubspec.yaml` -- Initialize pure Dart package -- Create isolated decay engine package in workspace.
- [x] `pubspec.yaml` -- Add `string_theory_decay_engine` to workspace members -- Allow unified workspace resolution.
- [x] `string_theory_decay_engine/lib/src/health_tier.dart` -- Implement `HealthTier` enum, thresholds, and descriptions -- Standardize green/amber/red classification.
- [x] `string_theory_decay_engine/lib/src/string_category_defaults.dart` -- Implement category shelf life, max hours defaults, and display names via `asNameMap()` -- Centralize decay rules.
- [x] `string_theory_decay_engine/lib/src/decay_engine.dart` -- Implement shared `DecayEngine` -- Unify composite health & tension calculations.
- [x] `string_theory_decay_engine/lib/string_theory_decay_engine.dart` -- Export public decay engine API -- Barrel export for consumers.
- [x] `string_theory_decay_engine/test/decay_engine_test.dart` -- Add decay engine unit test suite -- Verify calculations, edge cases, and polymorphic enums.
- [x] `string_theory_server/pubspec.yaml` -- Add `string_theory_decay_engine` dependency -- Connect backend to decay engine package.
- [x] `string_theory_server/lib/src/domain/decay_engine.dart` -- Re-export decay engine package -- Preserve existing server imports without breakage.
- [x] `string_theory_flutter/pubspec.yaml` -- Add `string_theory_decay_engine` dependency -- Connect Flutter client to decay engine package.
- [x] `string_theory_flutter/lib/domain/decay_engine.dart` -- Re-export decay engine package and typed extension -- Preserve existing Flutter domain imports.
- [x] `string_theory_flutter/lib/widgets/radial_health_gauge.dart` -- Adopt `HealthTier` in status colors and accessibility labels -- Eliminate duplicate thresholds.
- [x] `string_theory_flutter/lib/widgets/racquet_card.dart` -- Adopt `HealthTier` in dead stringbed alert -- Eliminate hardcoded `< 40` check.
- [x] `string_theory_flutter/lib/screens/racquet_detail_screen.dart` -- Adopt `HealthTier` in dead stringbed banner -- Eliminate hardcoded `< 40` check.
- [x] `string_theory_flutter/lib/widgets/add_racquet_modal.dart` -- Use domain `StringCategoryDefaults` -- Eliminate duplicated local defaults.
- [x] `.github/workflows/tests.yml` -- Add `decay-engine-tests` CI job -- Ensure CI validates shared decay engine tests.

**Acceptance Criteria:**
- Given a stringbed calculation request, when `DecayEngine.calculateHealth` is invoked with either server or flutter `StringMaterialCategory`, then it computes identical composite health scores.
- Given any health score (0-100), when `DecayEngine.getHealthTier` is called, then it returns `optimal` (>=70), `degraded` (40-69), or `critical` (<40).
- Given `RadialHealthGauge`, `RacquetCard`, and `RacquetDetailScreen`, when rendering health scores, then they derive color, critical alert banner, and semantics directly from `HealthTier`.
- Given the entire workspace, when `dart analyze` and `dart test` are executed across all packages, then zero analyzer warnings and 100% test pass rate are maintained.

### Review Findings

Code review 2026-10-06 of `3e5f46a..07ed33d` (blind-hunter, edge-case-hunter, verification-gap, acceptance-auditor).

- [x] [Review][Patch] (high) Server Docker image can no longer be built: `Dockerfile` builds a minimal workspace containing only `string_theory_server`, but the server now has a sourceless `string_theory_decay_engine:` dependency. Reproduced: `dart pub get` fails with "could not find package string_theory_decay_engine". Fix: `COPY string_theory_decay_engine` and add it to the generated `workspace:` list [string_theory_server/Dockerfile:9]
- [x] [Review][Patch] (medium) Compile-time exhaustiveness lost and nothing replaces it: a value added to `string_material_category.spy.yaml` silently gets `other` defaults (180d / 20h / "Other") on the server cron, the endpoints and the Flutter optimistic UI. No test feeds the real generated server/client enums through `fromEnum` (this also covers AC1 parity). Fix: in the server and flutter `decay_engine_test.dart`, loop over `StringMaterialCategory.values` and assert each name is in `DomainStringMaterialCategory.values.asNameMap()`, plus equal counts [string_theory_decay_engine/lib/src/string_category_defaults.dart:19]
- [x] [Review][Patch] (low) I/O matrix row "Dynamic & Calendar Decay" (10h/20h, 75d Co-Poly → 35, Critical) is not tested anywhere [string_theory_decay_engine/test/decay_engine_test.dart]
- [x] [Review][Patch] (low) The `hoursPlayed == infinity → maxFinite` branch is redundant (the `!totalPenalty.isFinite` guard already returns 0) and causes a bug: infinite hours with infinite max hours gives `maxFinite / infinity = 0` and reports 100% health. Fix: delete the branch [string_theory_decay_engine/lib/src/decay_engine.dart:36]
- [x] [Review][Patch] (low) Dead guard `rawShelfLife <= 0 ? 180.0`: every shelf life is a positive constant from an exhaustive switch, and the guard is an unnamed second copy of the `other` default. Fix: delete it [string_theory_decay_engine/lib/src/decay_engine.dart:57]
- [x] [Review][Patch] (low) The class doc still hardcodes the 70% / 40% thresholds that this refactor centralised in `HealthTier`. Fix: reference `HealthTier.optimalThreshold` / `degradedThreshold` [string_theory_flutter/lib/widgets/radial_health_gauge.dart:10]

**Rejected**

- low: No red `test(...)` commit (tests landed with the implementation in `0456f9d` / `6fb99cf`). A real TDD-protocol violation, but the fix would rewrite `main` history, which the trunk rules forbid.
- low: `materialCategory: Enum` accepts any enum (e.g. `HealthTier`). The spec mandates polymorphic `Enum` input, and the fix would change that design.
- low: The same lookup is exposed four ways (DecayEngine / StringCategoryDefaults / domain enum getter / flutter extension). All delegate to one switch, so no caller can diverge.
- low: `getHealthTierOrNull` and the flutter extension's `defaultMaxHours` / `shelfLifeDays` are unused. No named harm.
- low: UI strings (`description`, `displayName`) live in the domain package. The app has no localization, and the fix is a cross-package move.
- low: Non-finite guards change behaviour (NaN → 100, early returns). NaN previously crashed in `.round()`, and the early returns equal the old clamp results.
- low: `maxRatedHours = infinity` never decays. Pre-existing (old code identical), the UI validates `isFinite`, and the fix adds a guard.
- false: "RacquetCard critical styling untested". `racquet_card_test.dart` covers scores 34 and 39.
- false: "CI job needlessly installs Flutter". Root `pub get` resolves the whole workspace, including the Flutter package, so it needs the Flutter SDK.
- false: "Daily decay future call not verified". It calls the shared engine via the re-export (`daily_decay_future_call.dart:34`), and the workspace analyzes clean.
- false: "AC4 not verifiable". `dart analyze`: no issues. Decay engine package: 18/18 tests pass.
- Spec edit: tests are duplicated across three packages. The spec mandates test parity.
- Spec edit: the Implementation Notes and Spec Change Log sections are empty.

## Implementation Notes

## Spec Change Log

## Review Triage Log

- 2026-10-06 -- Spec Review by research subagent:
  - Polymorphic enum resolution: Use `asNameMap()[category.name] ?? other` instead of `try/catch(byName)` -- accepted and incorporated.
  - Extension namespace pollution: Avoid defining `extension on Enum` globally; provide typed extension on client enum in flutter domain layer while decay engine package provides lookup methods -- accepted and incorporated.
  - Missing file: Include `racquet_detail_screen.dart` alongside `racquet_card.dart` for `HealthTier` adoption -- accepted and incorporated.
  - CI job: Add dedicated `decay-engine-tests` job to `.github/workflows/tests.yml` -- accepted and incorporated.
- 2026-10-06 -- User feedback:
  - Renamed package from `string_theory_domain` to `string_theory_decay_engine` to be specifically scoped to the decay engine.
- 2026-10-06 -- Implementation Code Review:
  - `string_theory_decay_engine/lib/src/decay_engine.dart`: low -- non-finite checks for `hoursPlayed`, `maxRatedHours`, `installedTensionLbs` and zero shelfLife guard -- patch.
  - `string_theory_decay_engine/analysis_options.yaml`: low -- add missing package analysis_options.yaml with package:lints/recommended.yaml -- patch.
  - `string_theory_decay_engine/lib/src/string_category_defaults.dart`: low -- avoid circular enum map lookup in DomainStringMaterialCategory getters -- patch.
  - `string_theory_flutter/lib/domain/decay_engine.dart`: low -- add defaultMaxHours and shelfLifeDays getters on StringMaterialCategoryExtension -- patch.
  - `string_theory_decay_engine/lib/src/decay_engine.dart`: low -- add getHealthTierOrNull(int? score) helper -- patch.
  - `string_theory_decay_engine/test/decay_engine_test.dart`: low -- add tests for DomainStringMaterialCategory instance getters, getHealthTierOrNull, and default now -- patch.
  - `.github/workflows/tests.yml`: false -- analyze and format workflows already cover the entire workspace recursively at root.
  - `string_theory_decay_engine/lib/src/decay_engine.dart`: false -- numeric tension drop methods are out of scope and not required.
  - `string_theory_flutter/test/screens/racquet_detail_screen_test.dart`: low -- verification gap: assert critical vs non-critical CTA button in detail screen -- patch.
  - `string_theory_flutter/test/widgets/radial_health_gauge_test.dart`: low -- verification gap: assert semanticsLabel description for HealthTier -- patch.

## Design Notes

Polymorphic enum resolution using `asNameMap()`:
```dart
enum DomainStringMaterialCategory {
  coPoly,
  multifilament,
  syntheticGut,
  naturalGut,
  kevlar,
  hybrid,
  other;

  static final Map<String, DomainStringMaterialCategory> _nameMap =
      DomainStringMaterialCategory.values.asNameMap();

  static DomainStringMaterialCategory fromEnum(Enum category) =>
      _nameMap[category.name] ?? DomainStringMaterialCategory.other;
}
```

## Verification

**Commands:**
- `dart test` in `string_theory_decay_engine` -- expected: All decay engine unit tests pass green
- `dart test` in `string_theory_server` -- expected: All 35+ backend tests pass green
- `flutter test` in `string_theory_flutter` -- expected: All 79+ flutter tests pass green
- `dart analyze` -- expected: 0 errors/warnings across entire workspace
