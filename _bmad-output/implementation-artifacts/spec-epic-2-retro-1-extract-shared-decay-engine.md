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
