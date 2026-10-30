---
title: 'TEA Test Design → BMAD Handoff Document'
version: '1.0'
workflowType: 'testarch-test-design-handoff'
inputDocuments:
  - _bmad-output/test-artifacts/test-design-architecture.md
  - _bmad-output/test-artifacts/test-design-qa.md
  - _bmad-output/planning-artifacts/epics.md
sourceWorkflow: 'testarch-test-design'
generatedBy: 'TEA Master Test Architect'
generatedAt: '2026-10-30'
projectName: 'string_theory'
---

# TEA → BMAD Integration Handoff

## Purpose

This document connects TEA's system-level test design to the Firebase v1 epics in `_bmad-output/planning-artifacts/epics.md`. Those epics were finalized before this test design, and most of their ACs already carry test obligations (positive and negative rules tests per shape, `fake_cloud_firestore` repository tests, engine fixtures). This handoff lists only the **additions and decisions** the test design asks for. Apply them to the epics (a light edit or `bmad-correct-course`) before Sprint Planning.

## TEA Artifacts Inventory

| Artifact | Path | BMAD Integration Point |
| --- | --- | --- |
| Test Design (Architecture) | `_bmad-output/test-artifacts/test-design-architecture.md` | Decisions D-1 to D-3 (decided), testability improvements, risk mitigation plans |
| Test Design (QA) | `_bmad-output/test-artifacts/test-design-qa.md` | P0–P3 scenarios (P0-001…P3-001), execution strategy, entry and exit criteria |
| Risk Assessment | Embedded in both documents | Epic quality gates, story priority |
| Coverage Strategy | Embedded in the QA document | Story test requirements |

## Epic-Level Integration Guidance

### Risk References

| Epic | Risks to carry as epic-level quality concerns |
| --- | --- |
| 1. Sign in with Google | R-01 (rules harness, user doc), R-04 (`auth_time` create rule), R-05 (flavor guard), R-14 (cleanup deletes tests) |
| 2. Live Virtual Bag | R-02 (schema drift), R-07 (decode drops racquets), R-10 (dates), R-15 (decay math) |
| 3. Log sessions | R-03 (offline loss or silent rejection), R-06 (logSession shape) |
| 4. Restring lifecycle | R-06 (restring and update shapes), R-03 (offline `arrayUnion`) |
| 5. Account and launch | R-04 (purge), R-05 (Play sign-in), R-12 (store review), R-13 (accessibility), R-11/R-17 (App Check) |

### Quality Gates

| Epic | Gate (in addition to the CI-required jobs) |
| --- | --- |
| 1 | `rules_test/` job required in CI; P0-001, P0-002, P0-015, P0-017 green |
| 2 | Fixture corpus in place; P0-003, P0-006, P0-018, P1-001 green; R-02 mitigated |
| 3 | P0-004, P0-007…P0-011 green; emulator CI job green (D-1) |
| 4 | Every AD-5 shape has at least one positive and one negative rules test (P0-005); P0-009 green |
| 5 | P0-012, P0-013, P0-016 and P1-020 recorded; R-01…R-05 mitigated before production promotion |

## Story-Level Integration Guidance

### P0/P1 Test Scenarios → Story Acceptance Criteria (additions only)

| Story | AC to add | Scenario |
| --- | --- | --- |
| 1.3 | Flavor resolution is a pure function with unit tests: missing define, Android mismatch, dev, prod | P0-015 |
| 1.3 (or 2.2) | A CI step fails when `cloud_firestore`, `firebase_auth` or `google_sign_in` is imported outside `lib/data/` | P1-016 |
| 1.5 | `FirebaseAuthRepository` takes `FirebaseAuth` and `GoogleSignIn` through its constructor | P1-005 |
| 1.5 | The rules CI job pins the `firebase-tools` version and a Java runtime; default-deny test included | P0-002 |
| 2.2 | Mappers take `(Map, {hasPendingWrites, isFromCache})`, not `DocumentSnapshot`; `fake_cloud_firestore` metadata fidelity is checked and recorded | P1-001 |
| 2.2 | A shared JSON fixture corpus (valid/invalid) drives both the Dart decode and `schema_bounds` tests and the rules tests | P0-006 |
| 2.3 | NFR-1/NFR-3 measured on the newest Pixel phone with the latest Android, profile build (D-2) | P2-005 |
| 2.4 | Date-sensitive tests also run in CI under one positive and one negative UTC offset; cases include 23:30 local | P1-009 |
| 2.4 / 3.3 | Unawaited commit errors go through one repository handler that is unit-tested with an injected failing future | P0-010 |
| 3.1 / 4.5 | The network-off emulator tests run as a CI `integration_test` job on headless Chrome, required before merge (D-1) | P0-008, P0-009 |
| 3.2 | The ≤ 3-tap widget test is the accepted SM-1 evidence; no timing telemetry (D-3) | — |
| Every UI story | Accessibility ACs are verified with `meetsGuideline` (tap target, labeled tap target, text contrast) and a 200 % text-scale widget test | P1-018 |

### Data-TestId Requirements

Flutter has no DOM `data-testid`. Use these instead:

- **Semantics labels first.** The UX spec already fixes labels such as `Log session for {racquet}`, `Restrung today: {racquet}` and `Open details`. Tests use `find.bySemanticsLabel(...)`, which also proves the accessibility contract.
- **`ValueKey`s only where the label is not unique or not stable:** `ValueKey('racquet-card-{id}')`, `ValueKey('duration-chip-{minutes}')`, `ValueKey('racquet-selector-{id}')`, `ValueKey('timeline-entry-{jobId}')`, `ValueKey('save-session')`, `ValueKey('keep-same-reset')`.
- Keep the key constants in one file (for example `lib/widgets/test_keys.dart`) so widget code and tests share them.

## Risk-to-Story Mapping

| Risk ID | Category | P×I | Recommended Story/Epic | Test Level |
| --- | --- | --- | --- | --- |
| R-01 | SEC | 2×3=6 | 1.5, 2.2, 2.4, 3.1, 4.2–4.5 | RULES, WIDGET |
| R-02 | DATA | 2×3=6 | 2.2, 2.4 (+ every rules story) | UNIT, RULES, CI |
| R-03 | DATA | 2×3=6 | 3.1, 3.3, 4.5, 1.6 | EMU, UNIT, BLOC |
| R-04 | SEC | 2×3=6 | 1.5, 5.1, 5.2, 5.9 | RULES, REPO, BLOC, MANUAL, EMU |
| R-05 | OPS | 2×3=6 | 1.3, 5.8 | UNIT, MANUAL |
| R-06 | DATA | 2×2=4 | 3.1, 4.2–4.5 | RULES, REPO, BLOC |
| R-07 | DATA | 2×2=4 | 2.2, 2.3, 3.4 | UNIT, WIDGET |
| R-08 | TECH | 2×2=4 | 1.5, 5.2 | BLOC |
| R-09 | PERF | 2×2=4 | 1.4, 1.6, 2.3 | UNIT, WIDGET, MANUAL |
| R-10 | DATA | 2×2=4 | 2.1, 2.4, 4.1, 4.6 | UNIT, WIDGET |
| R-11 | SEC | 2×2=4 | 5.7, 5.10 | MANUAL |
| R-12 | BUS | 2×2=4 | 1.4, 1.7, 5.3, 5.8 | CI, UNIT, MANUAL |
| R-13 | BUS | 2×2=4 | every UI story, 5.4, 5.6 | WIDGET, MANUAL |
| R-14 | TECH | 2×2=4 | 1.2, 1.7 | WIDGET |
| R-15 | DATA | 1×3=3 | 2.1, 2.3 | UNIT, BLOC |
| R-16 | SEC | 1×3=3 | 1.5, 1.6, 2.2 | WIDGET, REPO |
| R-17 | OPS | 1×3=3 | 5.10 | UNIT |
| R-18 | OPS | 1×2=2 | post-launch | RULES |

## Recommended BMAD → TEA Workflow Sequence

1. **TEA Test Design** (`TD`) → produced this handoff ✅
2. **Apply the AC additions** above to `epics.md` and decide D-1 to D-3 ✅ (2026-10-30)
3. **BMAD Sprint Planning** (`SP`) → readiness check and new `sprint-status.yaml`
4. **TEA ATDD** (`AT`) → red-phase acceptance tests per story (optional; Build already follows strict TDD per AGENTS.md)
5. **BMAD Build** (`BD`) → test-first implementation
6. **TEA Automate** (`TA`) / **Trace** (`TR`) → widen coverage, then a coverage gate before Play promotion

## Phase Transition Quality Gates

| From Phase | To Phase | Gate Criteria |
| --- | --- | --- |
| Test Design | Epic/Story Creation | All P0 risks have a mitigation strategy ✅ |
| Epic/Story Creation | ATDD / Build | AC additions above applied or explicitly declined; D-1 to D-3 decided or deferred to their story |
| ATDD | Implementation | Failing tests exist for the story's P0/P1 scenarios |
| Implementation | Test Automation | All acceptance tests pass; rules deployed to dev |
| Test Automation | Release | Trace shows ≥ 80 % coverage of P0/P1 requirements; R-01…R-05 mitigated |
