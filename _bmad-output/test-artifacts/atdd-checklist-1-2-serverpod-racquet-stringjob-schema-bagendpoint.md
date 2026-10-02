stepsCompleted:
  - 'step-01-preflight-and-context'
  - 'step-02-generation-mode'
  - 'step-03-test-strategy'
  - 'step-04c-aggregate'
  - 'step-05-validate-and-complete'
lastStep: 'step-05-validate-and-complete'
lastSaved: '2026-10-02'
workflowType: 'testarch-atdd'
storyId: '1.2'
storyKey: '1-2-serverpod-racquet-stringjob-schema-bagendpoint'
storyFile: '_bmad-output/planning-artifacts/epics.md'
atddChecklistPath: '_bmad-output/test-artifacts/atdd-checklist-1-2-serverpod-racquet-stringjob-schema-bagendpoint.md'
generatedTestFiles:
  - 'string_theory_server/test/integration/bag_endpoint_test.dart'
inputDocuments:
  - '_bmad-output/planning-artifacts/epics.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/ARCHITECTURE-SPINE.md'
  - '_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/SOLUTION-DESIGN.md'
  - '_bmad/tea/config.yaml'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/data-factories.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/component-tdd.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-quality.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-healing-patterns.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-levels-framework.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/test-priorities-matrix.md'
  - '.agent/skills/bmad-testarch-atdd/resources/knowledge/ci-burn-in.md'
acceptanceCriteria:
  - id: 'AC-1'
    idSource: 'generated'
    text: 'Serverpod .spy.yaml models for StringMaterialCategory, Racquet, and StringJob defined with indexed userId: int and relationships'
  - id: 'AC-2'
    idSource: 'generated'
    text: 'PostgreSQL database tables racquet and string_job created with foreign keys and indexes via Serverpod migrations'
  - id: 'AC-3'
    idSource: 'generated'
    text: 'BagEndpoint.getVirtualBag(session) returns only racquets owned by the authenticated session.authenticated.userId'
  - id: 'AC-4'
    idSource: 'generated'
    text: 'BagEndpoint.createRacquet(session, racquet, initialStringJob) atomically creates the racquet and active string job within a single database transaction'
  - id: 'AC-5'
    idSource: 'generated'
    text: 'BagEndpoint.setPrimary(session, racquetId) designates the primary racquet and unsets previous primaries for that user'
  - id: 'AC-6'
    idSource: 'generated'
    text: 'BagEndpoint.deleteRacquet(session, racquetId) soft-deletes or retires a racquet owned by the user, rejecting unauthorized access'
---

# ATDD Checklist: Story 1.2: Serverpod Racquet & StringJob Schema & BagEndpoint

**Date:** 2026-10-02
**Author:** Francesco
**Target Stack:** Backend (Serverpod 4.0.3 / Dart 3.x / PostgreSQL ORM)
**Story Key:** `1-2-serverpod-racquet-stringjob-schema-bagendpoint`
**Primary Test Level:** Integration / API (Serverpod Integration Tests with `withServerpod`)

---

## Story Summary

As a developer and system consumer,  
I want Serverpod database tables and an authoritative `BagEndpoint`,  
So that racquet frames and their mounted string installations are persisted safely with row-level tenant security.

**Requirements Covered:** FR-4, FR-6, FR-7, NFR-8, ARCH-1, ARCH-3

---

## Acceptance Criteria Registry

- **AC-1** (generated): Serverpod `.spy.yaml` models for `StringMaterialCategory`, `Racquet`, and `StringJob` defined with indexed `userId: int` and relationships.
- **AC-2** (generated): PostgreSQL database tables `racquet` and `string_job` created with foreign keys and indexes via Serverpod migrations.
- **AC-3** (generated): `BagEndpoint.getVirtualBag(session)` returns only racquets owned by the authenticated `session.authenticated.userId`.
- **AC-4** (generated): `BagEndpoint.createRacquet(session, racquet, initialStringJob)` atomically creates the racquet and active string job within a single database transaction.
- **AC-5** (generated): `BagEndpoint.setPrimary(session, racquetId)` designates the primary racquet and unsets previous primaries for that user.
- **AC-6** (generated): `BagEndpoint.deleteRacquet(session, racquetId)` soft-deletes or retires a racquet owned by the user, rejecting unauthorized access.

---

## Loaded Context & Preflight Status

- **Detected Stack:** Fullstack (Mobile client `string_theory_flutter` + Serverpod backend `string_theory_server`), target scope: `backend` (`string_theory_server`).
- **Test Framework:** `dart test` with `serverpod_test` integration test harness (`withServerpod`, `sessionBuilder`, `endpoints`).
- **Database Rollback Strategy:** `RollbackDatabase.afterEach` / `disabled` for transaction tests.
- **Multi-Tenant Authorization Strategy:** `userId: int` extracted from `session.authenticated.userId`.

---

## Generation Mode Selection

- **Selected Mode:** AI Generation
- **Rationale:** Story 1.2 focuses on backend database models (`Racquet`, `StringJob`), transactions, and `BagEndpoint` RPC operations. Acceptance criteria are standard CRUD, transaction isolation, and row-level multi-tenant security scenarios. No browser UI interaction or recording is required.

---

## Test Strategy & Scenarios Mapping

| Criterion | Level | Priority | Scenario Description | Primary Red Failure Point |
| :--- | :--- | :--- | :--- | :--- |
| **AC-1** | Unit / Schema | P0 | Model definitions exist for `StringMaterialCategory`, `Racquet`, and `StringJob` with `userId: int` | Model classes and enum do not exist in protocol/domain |
| **AC-2** | Integration | P0 | Database table migration and ORM table query verification | PostgreSQL tables `racquet` and `string_job` do not exist in DB schema |
| **AC-3** | Integration (API) | P0 | `BagEndpoint.getVirtualBag` returns only racquets owned by authenticated user (tenant isolation) | `endpoints.bag.getVirtualBag` does not exist |
| **AC-4** | Integration (API) | P0 | `BagEndpoint.createRacquet` atomically persists racquet and initial string job in a single transaction | `endpoints.bag.createRacquet` does not exist |
| **AC-5** | Integration (API) | P1 | `BagEndpoint.setPrimary` sets new primary racquet and unsets previous primary for user | `endpoints.bag.setPrimary` does not exist |
| **AC-6** | Integration (API) | P1 | `BagEndpoint.deleteRacquet` deletes/retires user's racquet and rejects unauthorized deletion | `endpoints.bag.deleteRacquet` does not exist |

### Red-Phase Isolation Guarantees

1. **Criterion-Defining Assertions**: Each test targets the specific endpoint method or database property first. The red state is guaranteed because `endpoints.bag` is not yet declared on Serverpod's endpoint dispatcher.
2. **Tenant Isolation**: Tests use `sessionBuilder.copyWith(authentication: AuthenticationOverride.authenticationInfo(userId, ...))` to simulate distinct authenticated users without relying on external auth providers.
3. **Transactional Safety**: Atomic creation is tested against rolled back scenarios and verified directly via database counts.

---

## Red-Phase Test Scaffolds Created

### Serverpod API / Integration Tests (6 tests)

**File:** `string_theory_server/test/integration/bag_endpoint_test.dart` (124 lines)

- 🔴 **Test:** [P0] AC-1 should define Racquet and StringJob models with indexed userId
  - **Status:** RED (scaffolded with `test.skip()`)
  - **Criterion:** AC-1 (Serverpod `.spy.yaml` models for `StringMaterialCategory`, `Racquet`, and `StringJob`)
  - **First Failure Point:** `Racquet`, `StringJob`, and `StringMaterialCategory` model definitions not found in protocol serialization manager.
- 🔴 **Test:** [P0] AC-2 should verify database tables racquet and string_job exist with foreign keys
  - **Status:** RED (scaffolded with `test.skip()`)
  - **Criterion:** AC-2 (PostgreSQL tables `racquet` and `string_job` created via migration)
  - **First Failure Point:** Database tables `racquet` and `string_job` missing from `information_schema.tables`.
- 🔴 **Test:** [P0] AC-3 should return only racquets owned by authenticated user from getVirtualBag
  - **Status:** RED (scaffolded with `test.skip()`)
  - **Criterion:** AC-3 (`BagEndpoint.getVirtualBag(session)` multi-tenant row isolation)
  - **First Failure Point:** `endpoints.bag` does not exist on Serverpod endpoint dispatcher.
- 🔴 **Test:** [P0] AC-4 should atomically create racquet and initial string job in a single transaction
  - **Status:** RED (scaffolded with `test.skip()`)
  - **Criterion:** AC-4 (`BagEndpoint.createRacquet` atomic transactional persistence)
  - **First Failure Point:** `endpoints.bag.createRacquet` does not exist.
- 🔴 **Test:** [P1] AC-5 should set designated racquet as primary and unset previous primaries for user
  - **Status:** RED (scaffolded with `test.skip()`)
  - **Criterion:** AC-5 (`BagEndpoint.setPrimary` state transition)
  - **First Failure Point:** `endpoints.bag.setPrimary` does not exist.
- 🔴 **Test:** [P1] AC-6 should delete user racquet and reject unauthorized deletion
  - **Status:** RED (scaffolded with `test.skip()`)
  - **Criterion:** AC-6 (`BagEndpoint.deleteRacquet` authorization & soft-delete)
  - **First Failure Point:** `endpoints.bag.deleteRacquet` does not exist.

### E2E Tests (0 tests)

- **Status:** N/A for Story 1.2. Story 1.2 is strictly a backend schema and endpoint story. Front-end UI and Patrol E2E tests are introduced in Story 1.5 (Virtual Bag Screen) and Epic 5.

---

## TDD Red-Phase Compliance Summary

- **Total Scaffolds:** 6 tests
- **All Tests Skipped:** YES (`test.skip(...)` with `skip: 'ATDD RED PHASE: ...'`)
- **Criterion Mapping:** 1:1 mapping for all 6 acceptance criteria (AC-1 through AC-6)
- **First Failure Point Isolated:** Each test asserts the exact newly promised property before secondary checks
- **Syntax & Type Check:** Verified with `dart analyze string_theory_server` (0 issues)
- **Test Runner Verification:** Verified with `dart test test/integration/bag_endpoint_test.dart` (6 skipped, 0 failed, 0 errors)

---

## Next Steps: Task-by-Task Implementation & Activation

During implementation of Story 1.2:

1. **Step 1 (AC-1):** Define `.spy.yaml` models:
   - `string_theory_server/lib/src/models/string_material_category.spy.yaml`
   - `string_theory_server/lib/src/models/racquet.spy.yaml`
   - `string_theory_server/lib/src/models/string_job.spy.yaml`
   - Run `serverpod generate`
   - Un-skip AC-1 in `bag_endpoint_test.dart` and verify green.
2. **Step 2 (AC-2):** Generate and apply migrations:
   - `serverpod create-migration` (or Serverpod MCP)
   - Un-skip AC-2 in `bag_endpoint_test.dart` and verify green.
3. **Step 3 (AC-3, AC-4, AC-5, AC-6):** Implement `BagEndpoint` in `string_theory_server/lib/src/endpoints/bag_endpoint.dart`:
   - Implement `getVirtualBag`, `createRacquet`, `setPrimary`, `deleteRacquet`
   - Run `serverpod generate`
   - Un-skip AC-3, AC-4, AC-5, AC-6 sequentially to turn each test green!

---

## Validation & Completion Summary

- **Workflow Status:** COMPLETE ✅
- **Story ID:** `1.2`
- **Story Key:** `1-2-serverpod-racquet-stringjob-schema-bagendpoint`
- **Story File:** `_bmad-output/planning-artifacts/epics.md`
- **ATDD Checklist:** `_bmad-output/test-artifacts/atdd-checklist-1-2-serverpod-racquet-stringjob-schema-bagendpoint.md`
- **Generated Test Scaffolds:**
  - `string_theory_server/test/integration/bag_endpoint_test.dart` (6 red-phase integration test scaffolds)
- **TDD Compliance:** 100% (All 6 criteria have isolated, red-phase skipped tests asserting expected Serverpod ORM and endpoint behavior)
- **Analyzer Status:** Clean (`dart analyze string_theory_server` passes with 0 issues)
- **Test Runner Status:** Clean (`dart test test/integration/bag_endpoint_test.dart` reports 6 skipped, 0 failures)
- **Next Recommended Workflow:** `/bmad-build` or `dev-story` to begin implementing Story 1.2 models, migrations, and `BagEndpoint`.




