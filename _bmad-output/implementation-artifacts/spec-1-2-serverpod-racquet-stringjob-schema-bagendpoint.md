---
title: 'Story 1.2: Serverpod Racquet & StringJob Schema & BagEndpoint'
type: 'feature'
created: '2026-10-02'
status: 'done'
baseline_commit: 'fc9a9b51ff1161dcf7070e3a3a0065550b2828e6'
route: 'dispatch'
review_loop_iteration: 0
context:
  - 'AGENTS.md'
  - '_bmad-output/implementation-artifacts/epic-1-context.md'
  - '_bmad-output/test-artifacts/atdd-checklist-1-2-serverpod-racquet-stringjob-schema-bagendpoint.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The app requires authoritative persistence for tennis gear bags, racquets, and mounted string setups with strict multi-tenant row isolation by `userId: int`, atomic transaction guarantees, and RPC methods for querying, creating, setting primary, and deleting racquets.

**Approach:** Define Serverpod `.spy.yaml` data models for `StringMaterialCategory`, `Racquet`, and `StringJob` with `userId` indexes and relationships, generate and apply database migrations via Serverpod CLI/MCP, and implement `BagEndpoint` with authenticated multi-tenant operations wrapped in database transactions.

## Boundaries & Constraints

**Always:**
- Scope all database queries and writes by `session.authenticated.userId` (extracted from the authenticated session). Throw `ServerpodUnauthenticatedException` if unauthenticated.
- Declare models in `.spy.yaml` schemas under `string_theory_server/lib/src/models/` and run `serverpod generate` without manually editing generated code.
- Atomically create `Racquet` and its initial active `StringJob` within `session.db.transaction(...)`.
- When setting a racquet as primary via `setPrimary`, unset any other primary racquet for that user in the same transaction.
- Restrict `deleteRacquet` so users can only delete racquets they own; reject unauthorized attempts with an exception.
- Follow TDD by activating and passing tests in `string_theory_server/test/integration/bag_endpoint_test.dart`.

**Never:**
- Never perform unauthenticated database queries or allow cross-tenant data access.
- Never edit files in `lib/src/generated/` or `string_theory_client`.
- Never create a racquet without its initial active string job (no orphaned frames).
- Never allow multiple primary racquets per user.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Query Virtual Bag (Happy Path) | Authenticated user with 2 racquets | Returns `List<Racquet>` with `activeStringJob` eagerly loaded; only user's racquets returned | Empty list if user has no racquets |
| Query Virtual Bag (Unauthenticated) | Unauthenticated session | Request rejected | Throws `ServerpodUnauthenticatedException` |
| Multi-tenant Row Isolation | User 1 calls `getVirtualBag` while User 2 has racquets | Returns only User 1's racquets | Cross-tenant data filtered at SQL query level |
| Create Racquet & Job (Atomic) | Valid frame details, string specs, and tension | Creates `Racquet` and `StringJob`, links `activeStringJobId`, returns created `Racquet` | If either insert fails, transaction rolls back completely |
| Set Primary Racquet | Valid `racquetId` owned by user | Updates target racquet `isPrimary = true` and updates previous primary to `isPrimary = false` | If `racquetId` not owned by user, throws not found / unauthorized exception |
| Delete Racquet (Own) | Valid `racquetId` owned by user | Removes racquet and associated string jobs | Returns confirmation |
| Delete Racquet (Other User's) | `racquetId` owned by another user | Operation blocked; other user's racquet untouched | Throws unauthorized exception |

</frozen-after-approval>

## Code Map

- `string_theory_server/lib/src/models/string_material_category.spy.yaml` -- Enum defining string categories (`coPoly`, `multifilament`, `syntheticGut`, `naturalGut`, `hybrid`, `other`).
- `string_theory_server/lib/src/models/racquet.spy.yaml` -- Table `racquet` model with `userId`, `name`, `brand`, `model`, `isPrimary`, `createdAt`, `updatedAt`, `activeStringJob` relation, and `userId` index.
- `string_theory_server/lib/src/models/string_job.spy.yaml` -- Table `string_job` model with `userId`, `racquetId`, `materialCategory`, `brand`, `model`, `stringingDate`, `installedTension`, `maxRatedHours`, `totalCourtHours`, `currentHealthScore`, `isActive`, `createdAt`, and `userId` index.
- `string_theory_server/lib/src/endpoints/bag_endpoint.dart` -- Serverpod RPC endpoint exposing `getVirtualBag`, `createRacquet`, `setPrimary`, `deleteRacquet`.
- `string_theory_server/test/integration/bag_endpoint_test.dart` -- Integration test suite validating AC-1 through AC-6 using `withServerpod`.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_server/lib/src/models/string_material_category.spy.yaml` -- Create enum schema for string categories -- Provides type-safe string materials for presets and decay rates.
- [x] `string_theory_server/lib/src/models/racquet.spy.yaml` -- Create table schema for `Racquet` with `userId` index and relation to `StringJob` -- Establishes frame persistence with tenant isolation.
- [x] `string_theory_server/lib/src/models/string_job.spy.yaml` -- Create table schema for `StringJob` with `userId` index and foreign key to `Racquet` -- Tracks string installations, tensions, and health.
- [x] Code generation & database migration -- Run `serverpod generate` and `serverpod create-migration` -- Regenerates client/server protocol and creates SQL migration.
- [x] `string_theory_server/lib/src/endpoints/bag_endpoint.dart` -- Implement `BagEndpoint` with authenticated multi-tenant CRUD and transaction handling -- Exposes bag management to client.
- [x] `string_theory_server/test/integration/bag_endpoint_test.dart` -- Un-skip and activate all 6 ATDD test scaffolds -- Verifies green phase across all acceptance criteria.

**Acceptance Criteria:**
- Given Serverpod `.spy.yaml` models for `StringMaterialCategory`, `Racquet`, and `StringJob` with indexed `userId: int`, when code generation and migrations run, then the database tables `racquet` and `string_job` exist with foreign keys and indexes.
- Given an authenticated user session, when `BagEndpoint.getVirtualBag(session)` is called, then only racquets owned by `session.authenticated.userId` are returned with active string jobs.
- Given racquet details and initial string specifications, when `BagEndpoint.createRacquet(...)` is called, then both `Racquet` and `StringJob` are created atomically in a single database transaction.
- Given a user with an existing primary racquet, when `BagEndpoint.setPrimary(session, racquetId)` is called, then the specified racquet becomes `isPrimary = true` and the previous primary becomes `false`.
- Given a racquet owned by User 1, when User 2 attempts to delete it via `BagEndpoint.deleteRacquet`, then the request is rejected with an exception and User 1's racquet remains intact.

## Implementation Notes

- Defined `StringMaterialCategory` enum with `coPoly`, `multifilament`, `syntheticGut`, `naturalGut`, `hybrid`, `other`.
- Defined `Racquet` model with `userId` index and `activeStringJob: StringJob?, relation(optional)`.
- Defined `StringJob` model with `userId` index, `racquetId` foreign key with `onDelete=Cascade`, and setup specifications.
- Created `BagException` serializable exception for typed client error communication.
- Successfully generated migration `20261002171208637` adding tables `racquet` and `string_job` with foreign keys and indexes.
- Implemented `BagEndpoint` with `requireLogin => true` and multi-tenant row isolation scoped by `session.authenticated.userIdentifier`.
- Un-skipped and passed all 6 ATDD integration test scaffolds in `bag_endpoint_test.dart`, plus added unauthenticated rejection test. All 7 tests passed (100% green).


## Spec Change Log

## Review Triage Log

| Layer | Finding Claim | Verdict | Evidence / Action |
|-------|---------------|---------|-------------------|
| Blind Hunter / Edge Case | Volatile `String.hashCode` in `_resolveUserId` causes user ID changes across server restarts | high | Verified: Dart VM randomizes string hash seed on startup. Action: patch with stable 63-bit BigInt parse of UUID hex bytes. |
| Blind Hunter / Edge Case / Gap | `setPrimary` strips `activeStringJob` from returned `Racquet` | medium | Verified: `findById` does not eager load `activeStringJob`. Action: patch `setPrimary` to include `activeStringJob` on return. |
| Verification Gap | `getVirtualBag` activeStringJob eager loading is unasserted in test suite | medium | Pre-verified gap: add `expect(user1Bag.every((r) => r.activeStringJob != null), isTrue)` to AC-3. |
| Verification Gap | `createRacquet` with `isPrimary: true` unsetting previous primaries is unverified | medium | Pre-verified gap: add test creating secondary primary racquet and asserting primary swap. |
| Verification Gap | `setPrimary` cross-tenant authorization guard is unverified | medium | Pre-verified gap: add test verifying User 2 cannot call `setPrimary` on User 1's racquet. |
| Blind Hunter | Missing `kevlar` in `StringMaterialCategory` | low | Verified: `epic-1-context.md` mentions `Kevlar / Aramid`. Action: add `kevlar` value to enum. |
| Blind Hunter | Missing name whitespace validation in `createRacquet` | low | Verified: empty/whitespace racquet names should be rejected with 400. Action: add trim check. |
| Blind Hunter | `ON DELETE` on `racquet.activeStringJobId` should be `SetNull` | low | Verified: prevents FK violation if active string job is deleted directly. Action: add `onDelete=SetNull`. |
| Blind Hunter | Missing real-time WebSocket pub/sub broadcasting | false | Planned for Story 3.2 (`serverpod-real-time-websocket-streaming-bagstreammessage`). |
| Blind Hunter | Database rollbacks disabled in integration tests | false | Intended design: Serverpod requires `RollbackDatabase.disabled` for tests verifying transactions. |


- **Relations**: In Serverpod, `activeStringJob: StringJob?, relation(optional)` on `Racquet` allows eager inclusion during queries via `Racquet.include(activeStringJob: StringJob.include())`.
- **Atomic Creation**:
  ```dart
  return await session.db.transaction((tx) async {
    final racquet = await Racquet.db.insertRow(session, newRacquet, transaction: tx);
    final stringJob = await StringJob.db.insertRow(
      session,
      initialStringJob.copyWith(racquetId: racquet.id, userId: userId),
      transaction: tx,
    );
    return await Racquet.db.updateRow(
      session,
      racquet.copyWith(activeStringJobId: stringJob.id),
      transaction: tx,
    );
  });
  ```
- **Primary Swap**:
  ```dart
  await session.db.transaction((tx) async {
    final existingPrimaries = await Racquet.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.isPrimary.equals(true),
      transaction: tx,
    );
    for (final r in existingPrimaries) {
      await Racquet.db.updateRow(session, r.copyWith(isPrimary: false), transaction: tx);
    }
    final target = await Racquet.db.findById(session, racquetId, transaction: tx);
    if (target == null || target.userId != userId) {
      throw ServerpodClientException('Racquet not found or unauthorized', 404);
    }
    await Racquet.db.updateRow(session, target.copyWith(isPrimary: true), transaction: tx);
  });
  ```

## Verification

**Commands:**
- `dart analyze string_theory_server` -- expected: No issues found!
- `dart test test/integration/bag_endpoint_test.dart` -- expected: All 6 tests pass!
- `dart format string_theory_server` -- expected: Cleanly formatted files
