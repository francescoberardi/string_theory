---
title: 'Story 3.2: Serverpod Real-Time WebSocket Streaming & BagStreamMessage'
type: 'feature'
created: '2026-10-04'
status: 'done'
baseline_commit: '00f17deb719db46aeb23caf2c91065ceb0a5a1ea'
route: 'dispatch'
review_loop_iteration: 0
context:
  - '_bmad-output/implementation-artifacts/epic-3-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** When a session is logged, other open screens (another device, a judge's browser tab) keep showing stale gauges and court hours until a manual reload, so the "live gauge drop" demo of FR-14 / NFR-2 cannot happen.

**Approach:** Add a non-persisted `BagStreamMessage` model, a Serverpod streaming method that subscribes the authenticated user to channel `user_{userId}_bag`, and publish a `sessionLogged` message from `SessionEndpoint.logSession` after its transaction commits. `BagBloc` subscribes after the bag loads and patches the affected racquet's health score and court hours in place, so `RadialHealthGauge` animates without a refetch.

## Boundaries & Constraints

**Always:**
- Channel name is exactly `user_{userId}_bag`, where `userId` comes from the server-side resolution of `session.authenticated` (same algorithm as the endpoints already use); the client never supplies a channel or user id.
- The streaming method requires login.
- Publish only after the `logSession` transaction has committed, and only when a new `SessionLog` was inserted (idempotent replays and 409/400/404 paths publish nothing).
- A publish failure is logged and swallowed — it never fails `logSession`.
- `BagStreamMessage` fields: `eventType: String`, `racquetId: int?`, `healthScore: int?`, `totalCourtHours: double?`, `timestamp: DateTime`. (`totalCourtHours` extends the architecture model so the card's hours label stays correct.)
- `BagBloc` ignores messages for racquets not in its current `BagLoaded` state and ignores messages while not in `BagLoaded`.
- `BagBloc` cancels its subscription in `close()`; a stream error or done clears the subscription so the next `LoadBag` re-subscribes. No retry loop.

**Never:**
- No database table or migration for `BagStreamMessage`.
- No publishing from `fastForwardRacquetAge` or `DailyDecayFutureCall` in this story; restring publishing belongs to Story 4.1 (it reuses the same channel helper with `eventType: 'restrung'`).
- No automatic reconnection / offline queue (Story 3.5).
- No session-logging UI (Story 3.4).
- Never edit generated code or the `string_theory_client` package by hand.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Live update | User 1 subscribed; user 1 logs 90 min on racquet R | Subscriber receives `BagStreamMessage(eventType: 'sessionLogged', racquetId: R, healthScore: <new score>, totalCourtHours: <new hours>)` within 300 ms | N/A |
| Tenant isolation | User 2 subscribed; user 1 logs a session | User 2 receives nothing | N/A |
| Idempotent replay | Same `externalWorkoutId` logged twice | Exactly one message delivered | N/A |
| Failed log | `logSession` throws (400/404/409) | No message delivered | Exception propagates as before |
| Unauthenticated subscribe | No auth on stream call | Stream not opened | Serverpod login requirement rejects the call |
| Bloc patch | `BagLoaded` with racquet R; message for R | New `BagLoaded` where R's `activeStringJob.currentHealthScore` and `totalCourtHours` equal message values; other racquets unchanged | N/A |
| Unknown racquet / not loaded | Message for id not in state, or state not `BagLoaded` | No state emitted | N/A |
| Stream error | Subscription emits error | No `BagError`; subscription cleared; next `LoadBag` re-subscribes | Logged via `debugPrint` |

</frozen-after-approval>

## Code Map

- `string_theory_server/lib/src/models/bag_stream_message.spy.yaml` -- NEW. `class: BagStreamMessage`, no `table`.
- `string_theory_server/lib/src/messaging/bag_channels.dart` -- NEW. `BagChannels.forUser(int userId) => 'user_${userId}_bag'` plus event-type constants (`sessionLogged`; `restrung` reserved for 4.1).
- `string_theory_server/lib/src/endpoints/bag_endpoint.dart` -- Add `Stream<BagStreamMessage> bagUpdates(Session session)` that resolves the user with the existing `_resolveUserId` and returns `session.messages.createStream<BagStreamMessage>(BagChannels.forUser(userId))`. Endpoint already has `requireLogin => true`. Don't touch other methods.
- `string_theory_server/lib/src/endpoints/session_endpoint.dart` -- `_insertSession` currently returns only `SessionLog`. Make it also report whether a row was inserted plus the updated `StringJob` (e.g. a Dart record `(SessionLog log, StringJob? updatedJob)`; `updatedJob == null` means idempotent hit). In `logSession`, after a successful insert, call `session.messages.postMessage(...)` inside try/catch that logs with `session.log(..., level: LogLevel.warning)`. The `DatabaseUniqueViolationException` race branch returns the existing row and must not publish. Keep all existing validation and ordering.
- `string_theory_server/test/integration/bag_stream_test.dart` -- NEW. Uses `withServerpod` with user 1 and user 2 sessions built the same way as `session_endpoint_test.dart` (`AuthenticationOverride.authenticationInfo('1', {})`). Streaming methods are exposed through `endpoints.bag.bagUpdates(sessionBuilder)` in the generated test tools.
- `string_theory_flutter/lib/bloc/bag_event.dart` -- Add `BagStreamReceived(BagStreamMessage message)` (name from SOLUTION-DESIGN.md §4).
- `string_theory_flutter/lib/bloc/bag_bloc.dart` -- Hold a `StreamSubscription<BagStreamMessage>?`. Subscribe to `client.bag.bagUpdates()` after `_onLoadBag` emits `BagLoaded`, only if not already subscribed; forward each message as `add(BagStreamReceived(msg))`. `_onBagStreamReceived` patches via `racquet.copyWith(activeStringJob: job.copyWith(...))`, following the existing map-and-replace pattern in `_onFastForwardRacquetAge`. Override `close()` to cancel.
- `string_theory_flutter/test/bag_bloc_test.dart` -- Existing mocktail `MockClient`/`MockEndpointBag` setup. Existing `LoadBag` tests will now call `bagUpdates()`, so stub it in `setUp` to return `const Stream.empty()` by default.
- `string_theory_flutter/lib/widgets/radial_health_gauge.dart` -- Already animates on value change; reuse it, don't modify it.

## Tasks & Acceptance

**Execution:**
- [x] `string_theory_server/lib/src/models/bag_stream_message.spy.yaml` -- create model -- message contract for the channel.
- [x] `string_theory_server/lib/src/messaging/bag_channels.dart` -- create channel/event constants -- single source for channel naming.
- [x] `string_theory_server` -- run `serverpod generate` (no migration: no table) -- produces the model, the client streaming method, and the test tools.
- [x] `string_theory_server/test/integration/bag_stream_test.dart` -- write failing tests first (TDD red) for the five server rows of the I/O matrix (live update + latency < 300 ms, tenant isolation, idempotent replay, failed log, unauthenticated subscribe).
- [x] `string_theory_server/lib/src/endpoints/bag_endpoint.dart` -- add `bagUpdates` streaming method.
- [x] `string_theory_server/lib/src/endpoints/session_endpoint.dart` -- publish after commit on a new insert only.
- [x] `string_theory_flutter/test/bag_bloc_test.dart` -- write failing `bloc_test` cases first: subscribes after load, patches the matching racquet, ignores unknown racquet / non-loaded state, stream error clears the subscription without emitting `BagError`, `close()` cancels.
- [x] `string_theory_flutter/lib/bloc/bag_event.dart`, `string_theory_flutter/lib/bloc/bag_bloc.dart` -- implement the event, subscription, and patch handler.

**Acceptance Criteria:**
- Given two authenticated clients of the same user with the bag loaded, when one logs a session through `SessionEndpoint.logSession`, then the other's `BagBloc` emits a `BagLoaded` with the new health score and court hours without calling `getVirtualBag` again.
- Given the server is running without Redis, when a message is published, then it is delivered locally (`MessageScope.auto`) and no error is logged.

## Implementation Notes

- Generated code via `serverpod generate` (CLI); the agent had no `serverpod` MCP tools. No migration (no table).
- `_insertSession` returns `(SessionLog log, StringJob? updatedJob)`; `logSession` publishes via `_publishSessionLogged` only when `updatedJob != null`, after the transaction resolves. The unique-violation race branch returns early without publishing.
- `BagBloc` patches a racquet only when it has an `activeStringJob`; null message fields keep the current values.
- Bloc tests use a broadcast `StreamController` (allows re-subscription after an error) and field matchers, because Serverpod models compare by identity.

## Spec Change Log

## Review Triage Log

| Finding | Verdict | Route | Evidence |
|---------|---------|-------|----------|
| onDone re-subscribe path untested | medium | patch | Pre-verified gap: only the error path is driven in `bag_bloc_test.dart`; removing `onDone` fails no test. |
| Race-branch (`DatabaseUniqueViolationException`) no-publish rule has no stream assertion | medium | patch | Pre-verified gap: concurrent test in `session_endpoint_test.dart` never subscribes; stream replay test only hits the in-transaction idempotent path. |
| `postMessage` returning `false` is not logged | low | patch | `MessageCentral._postGlobal` returns `redisController.publish(...)` result; a Redis failure yields `false` with no throw, so the catch-only logging misses it. |
| Update lost between `getVirtualBag` and subscribe / dropped during `BagLoading` | low | rejected | Real but a millisecond window; frozen intent orders subscribe-after-load and ignore-while-not-loaded; a fix needs buffering. Resync on reconnect belongs to Story 3.5. |
| Stale / out-of-order messages overwrite newer state | low | rejected | Requires two concurrent sessions publishing out of commit order for one racquet; fix needs per-racquet timestamp tracking. |
| `eventType` ignored; no `stringJobId`; restrung would patch old job | false | rejected | Only `sessionLogged` is published today and active jobs only change via `createRacquet`; restring handling is Story 4.1's scope. |
| `eventType` should be an enum | false | rejected | No consumer branches on it yet; no named harm. |
| Stream end leaves updates silently paused | false | rejected | Frozen intent: no retry loop; reconnection is Story 3.5. |
| Latency test measures logSession + delivery; may flake | low | rejected | End-to-end measurement is intended by Design Notes; local runs pass with wide margin. |
| Fixed 200 ms `settle()` sleeps in stream tests | low | rejected | Negative assertions need a bounded wait; flakiness unobserved. |
| Publish-failure path, Redis-less AC, two-client e2e untested | low | rejected | Failure path hard to induce in harness; local delivery exercised by every stream test (no Redis in test config); two-client flow covered by server + bloc tests. |
| CRUD / fast-forward / daily decay do not publish | medium | defer | Frozen intent excludes them for this story; daily decay changing scores without live push is a real product gap. |
| Multi-instance delivery unverified (no explicit scope) | false | rejected | `MessageScope.auto` publishes via Redis when enabled, locally otherwise (`message_central.dart:69-73`). |
| Tenant isolation rests on lossy userId hashing | low | rejected | Pre-existing; same collision would already merge DB scoping; 63-bit collision probability negligible. |
| Bloc emits when values unchanged | low | rejected | Server only publishes on a real change; gauge tween to the same value is invisible. |
| Racquet without activeStringJob drops message | false | rejected | Server publishes only for an active job and racquets are always created with one. |
| `cancel()` throwing in `close()` skips `super.close()` | low | rejected | No evidence the client stream's cancel throws; fix adds a guard. |

## Design Notes

Server publish point (after the transaction future resolves, outside it):

```dart
final (log, updatedJob) = await _insertSession(...);
if (updatedJob != null) {
  await _publishSessionLogged(session, userId, log.racquetId, updatedJob);
}
return log;
```

The serverpod_test harness wraps each test in a rolled-back transaction, but message delivery is in-process and independent of it, so the stream assertions are valid there. In the latency test, start the stopwatch before `logSession` and stop it on the first stream event (`stream.first.timeout(...)`), so the measurement covers persistence plus delivery.

## Verification

**Commands:**
- `dart analyze` in the repo root -- expected: No issues found
- `dart format --set-exit-if-changed .` in `string_theory_server` and `string_theory_flutter` -- expected: no changes
- `dart test` in `string_theory_server` -- expected: all tests pass, including `bag_stream_test.dart`
- `flutter test` in `string_theory_flutter` -- expected: all tests pass, including the new `bag_bloc_test.dart` cases

**Manual checks:**
- With `serverpod start` running, open the Flutter web app in two browser tabs signed into the same guest. Log a session via `SessionEndpoint` (curl or a test RPC). Both tabs' gauges should animate to the new score with no reload.
