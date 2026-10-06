---
title: 'Add cross-tenant bagUpdates stream isolation test for restringing'
type: 'chore'
created: '2026-10-06'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** `BagEndpoint.restringRacquet` publishes a `restrung` `BagStreamMessage` to `user_{userId}_bag` after its transaction commits. However, the multi-tenant isolation test in `test/integration/bag_stream_test.dart` only covers `sessionLogged` events from `logSession`. No test proves that a restring on user A's racquet never reaches user B's open `bagUpdates` stream. If a regression published to the wrong channel (or to a shared channel), another tenant would see an event about a racquet they do not own. Source: Epic 4 retro action item 12 (`epic-4-retro-item-12-add-cross-tenant-bagupdates-stream-isola`).

**Approach:** Add integration tests to the existing `Given BagEndpoint.bagUpdates real-time stream` group in `bag_stream_test.dart`, reusing its `collect`/`settle` helpers and its user 1 and user 2 sessions. (1) Both users own a racquet and subscribe. User 1 restrings their racquet. User 1 receives exactly one `restrung` message for that racquet, and user 2 receives nothing. (2) User 2 tries to restring user 1's racquet, gets a 404 `BagException`, and neither subscriber receives anything. This is test-only, with no production change. Mark the sprint-status action item done.

</frozen-after-approval>

## Implementation Notes

- Files: `string_theory_server/test/integration/bag_stream_test.dart` (two new tests), `_bmad-output/implementation-artifacts/sprint-status.yaml` (item 12 → done).
- The tests use the default rollback mode, the same as the existing Story 4.1 AC-2 test in `bag_endpoint_test.dart`, which already receives a `restrung` event under that mode.
- TDD: the tests passed on first run because production is already correct. Red was checked by mutation: pointing `_publishRestrung` at `BagChannels.forUser(2)` failed the restring isolation test. Reverted afterwards. `dart analyze` clean; full server `dart test` passed (99 tests).

## Review Triage Log

- Empty-stream assertions could pass if the other user's subscription were dead (no positive control): medium, patched. Test 1 now has user 2 restring their own racquet and receive exactly one message. Test 2 now has user 1 restring afterwards and receive exactly one message.
- Unused user 2 racquet in test 1: low, patched. It is now the positive-control restring, which also makes the isolation symmetric.
- Hardcoded `'restrung'` instead of `BagChannels.restrung`: low, patched.
- Fixed 200 ms `settle()` could miss a late misrouted message: low, partly addressed by the positive control, which settles after a later event. Polling with a timeout was rejected because it would differ from every sibling test in the group.
- `restrung` payload (health 100, hours 0) and NFR-2 timing not asserted: low, rejected. Story 4.1 AC-2 in `bag_endpoint_test.dart` already covers the payload, and this item is about isolation.
- 404 test doesn't check the racquet is unchanged: low, rejected. The ownership check throws inside the restring transaction, so any earlier write rolls back, and AC-6 owns the 404 contract.
- Spec status contradicts the tracker: false. The spec had not been finalized when the review ran.
- `last_updated` in sprint-status not bumped: false. The previous retro-item commits (`7333a99`, `0ba399f`) flip only the status line, so that is the convention.
- Spec `type: 'chore'` vs a `test` commit: low, accepted for the commit (`test(server)`). The spec type matches the sibling retro specs.
- Older test named generically and without `try/finally` cleanup: low. Patched the rename (now says `sessionLogged`). Rejected the cleanup change, which is outside this item.
