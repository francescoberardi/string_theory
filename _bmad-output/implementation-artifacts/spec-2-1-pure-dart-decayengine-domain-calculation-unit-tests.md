---
title: 'Story 2.1: Pure Dart DecayEngine Domain Calculation & Unit Tests'
type: 'feature'
created: '2026-10-04'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context:
  - 'AGENTS.md'
  - '_bmad-output/implementation-artifacts/epic-2-context.md'
  - '_bmad-output/test-artifacts/atdd-checklist-2-1-pure-dart-decayengine-domain-calculation-unit-tests.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Tennis strings lose elasticity and tension continuously through court impact hours and static calendar shelf-life creep in the bag. We need a deterministic, shared domain calculation engine (`DecayEngine`) to calculate identical health scores and tension loss estimates across the Flutter client (for optimistic 60fps UI animations) and the Serverpod backend (for authoritative DB persistence and daily scheduled cron updates).

**Approach:** Implement `DecayEngine` in both `string_theory_server/lib/src/domain/decay_engine.dart` and `string_theory_flutter/lib/domain/decay_engine.dart` calculating composite health scores based on $70\%$ dynamic court hours penalty and $30\%$ calendar shelf-life decay with category-specific shelf lives, secondary tension loss text formatting, and boundary clamping, passing unit test suites on both backend and frontend with 100% test coverage.

</frozen-after-approval>

## Implementation Notes

- Implemented `DecayEngine` in `string_theory_server/lib/src/domain/decay_engine.dart` and `string_theory_flutter/lib/domain/decay_engine.dart` (identical logic, different generated-model imports).
- Kevlar shelf life set to 120 days (not specified in the story; hybrid/other fall back to 180).
- Tension loss model: max 25% of installed tension lost at 0% health (assumption, not in the story).
- Red-phase `skip` flags removed from both test suites; 10 tests each, all green.
- Review patches: millisecond-precision elapsed days; kevlar, exact tension values and zero `maxRatedHours` tests.

## Review Triage Log

- Health tier classification missing — low/defer: real, but consumed by Story 2.2; logged in deferred-work.
- `.inHours` truncation — medium: patched to millisecond precision.
- NaN/Infinity inputs — false: no caller can produce them (inputs come from validated forms/DB); failing loudly is correct.
- Kevlar shelf life untested — medium: patched.
- Weak tension test assertions — medium: patched with exact values (50% and 0%).
- Private constructor on static class — low: rejected, cosmetic.
- Duplicated engine across packages — medium/defer: needs a shared package; logged in deferred-work.
- Penalty breakdown not exposed — false: not required by any AC; speculative API.
- Default `now` and zero `maxRatedHours` untested — low/medium: zero guard patched; default `now` rejected as trivial.

### Review Findings (Code Review 2026-10-04)

- [x] [Review][Patch] Clamp negative installedTensionLbs to 0.0 in calculateTensionLossText [`string_theory_server/lib/src/domain/decay_engine.dart:57`, `string_theory_flutter/lib/domain/decay_engine.dart:57`]
- [x] [Review][Patch] Isolate 400 days elapsed boundary test with 0 court hours played [`string_theory_server/test/unit/domain/decay_engine_test.dart`, `string_theory_flutter/test/domain/decay_engine_test.dart`]
- [x] [Review][Defer] Add shared health tier classification (green/amber/red) to DecayEngine — deferred: scheduled for Story 2.2 UI integration
- [x] [Review][Defer] Extract shared domain package to eliminate duplicate DecayEngine — deferred: planned for multi-package architecture refactor

### Rejected Findings

- Status inconsistency between spec frontmatter and sprint tracking: False (workflow sets status: 'done' on spec completion per step-oneshot.md line 90 before moving to review).
- NaN/Infinity input crashing `round()`: Low (inputs are strictly type-checked and validated at form and DB layer; failing loudly on illegal non-finite states is standard Dart behavior).
- Structured tension loss breakdown / locale formatting: Low (out of scope for Story 2.1 AC-2, which requires formatted string `~1.5 kg / ~3.3 lbs drop`).
- Max rated hours <= 0 fallback to 1.0 hour: Low (safeguards against divide-by-zero on malformed inputs).
- Double precision health score: Low (AC-1 explicitly requires integer return type 0-100%).
- Test suite Given/When/Then comment drift: Low (cosmetic difference in test comment formatting).
