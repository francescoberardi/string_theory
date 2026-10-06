---
title: 'Add dedicated unit tests for TenantResolver'
type: 'chore'
created: '2026-10-06'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `resolveUserId` (`string_theory_server/lib/src/util/tenant_resolver.dart`) maps every auth identifier to the `userId` that scopes all tenant data (ARCH-3), but has no dedicated tests. Endpoint tests only exercise plain numeric identifiers (`'1'`, `'2'`). The UUID path (the one Serverpod 4 auth IDs actually take), the FNV-1a fallback and the boundary cases are untested, so a silent change could re-key every user's data. Unauthenticated endpoint calls are rejected by `requireLogin` first, so the 401 `BagException` branch is never reached either. Source: Epic 4 retro action item 11 (`epic-4-retro-item-11-add-dedicated-unit-tests-for-tenantresol`).

**Approach:** Split the string-to-int mapping into a pure, Session-free function (`resolveUserIdFromIdentifier(String)`) and have `resolveUserId(Session)` call it. Production behavior stays exactly the same. Then pin its behavior with characterization tests: numeric pass-through (including `0`, negative and int64-max values), deterministic and non-negative UUID mapping (with and without hyphens, golden values), overflowing digit strings falling through to the hex path, and the FNV fallback for non-hex strings (deterministic, non-negative, distinct per input, golden values). Add a small `withServerpod` test for the Session wrapper: an unauthenticated session gets a `BagException` with status 401, and an authenticated session goes through the pure function. Mark the sprint-status action item done.

</frozen-after-approval>

## Implementation Notes

- Decision: characterize, don't change. Existing rows are keyed by the current outputs, so the mapping's quirks are pinned and left as they are, not fixed: negative numeric IDs pass through as negative, `int.tryParse` accepts `' 5'` and `'0x10'`, and short hex-looking strings such as `'cafe'` take the hex path, not FNV. The FNV loop multiplies an unbounded `BigInt` with no 64-bit mask, so it is not standard FNV-1a-64. Its doc comment will be corrected to say so; the algorithm stays the same.
- Files: `string_theory_server/lib/src/util/tenant_resolver.dart` (extract the pure function, fix the comment), `string_theory_server/test/unit/util/tenant_resolver_test.dart` (new, pure tests), `string_theory_server/test/integration/tenant_resolver_test.dart` (new, Session wrapper), `_bmad-output/implementation-artifacts/sprint-status.yaml` (item 11 → done).
- TDD: the unit suite failed to load before the extraction (red: `resolveUserIdFromIdentifier` undefined), then passed after it (green). Golden values were computed from a verbatim copy of the old mapping before the refactor. `dart analyze` clean; full server `dart test` passed (94 tests after review patches).
- Verified in `serverpod_auth_core_server` 4.0.3 (`authentication_info_extension.dart`, `UuidValue.withValidation(userIdentifier)`) that real auth identifiers are UUIDs, so the numeric and FNV paths are reached only from tests.

## Review Triage Log

- Numeric and hex ranges collide (`'3'` and the all-`f` UUID both map to 3): low, real but existed before this change and is unreachable in production (auth IDs are always UUIDs). Patched: noted in the doc comment and pinned by a test. Fixing it would re-key tenants.
- Session-wrapper test compared `resolveUserId` with `resolveUserIdFromIdentifier`, so it checked the code against itself: low, patched to assert the golden value.
- Doc comment left out quirks, and the inline comment said "UUID only": low, patched (sign/whitespace/`0x`, all hyphens stripped, case-insensitive hex, overflowing digits, UTF-16 hashing).
- No test for the empty identifier: low, patched with a golden test.
- Hex case-insensitivity not pinned: low, patched (`CAFE`, upper-case UUID).
- Loop variable `byte` is really a UTF-16 code unit, and non-ASCII input was not pinned: low, patched (renamed to `codeUnit`; golden tests for `josé` and a surrogate pair).
- int64 min and negative overflow not tested: low, patched (both pinned).
- Unmasked BigInt hash grows quadratically with identifier length: low, rejected. Only reachable with non-hex identifiers, and auth issues UUIDs, so it never runs in production.
- Spec status contradicts the tracker: false. The spec had not been finalized when the review ran.
- Spec has no `baseline_commit` / empty `context`, `chore` type, single commit instead of a test/refactor split: low, rejected. The template has no `baseline_commit` field, other retro specs use `chore`, and the red state was verified as `AGENTS.md` allows ("commit or verify red state").
- "Deterministic across repeated calls" test adds nothing over the golden values: low, patched (removed).
- How the golden values were derived is not auditable: low, patched with a header comment naming baseline commit `fdf1401`.
