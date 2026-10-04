---
title: 'Story 2.3: Serverpod DailyDecayFutureCall & On-Demand Test Trigger'
type: 'feature'
created: '2026-10-04'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context:
  - 'AGENTS.md'
  - '_bmad-output/implementation-artifacts/epic-2-context.md'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Tennis strings continuously lose tension and elasticity while sitting idle in a player's bag, but without background calculation or test triggers, string health remains static and judges cannot observe decay progression in real time.

**Approach:** Implement Serverpod `DailyDecayFutureCall` scheduled nightly at 00:00 UTC using `DecayEngine.calculateHealth` to update active `StringJob.currentHealthScore` in the database, expose `BagEndpoint.triggerDailyDecayNow(session)` RPC endpoint to execute the decay scan immediately on demand, and add a dev button `[⚡ Trigger FutureCall Decay]` in the Flutter client logging execution to the console.

</frozen-after-approval>

## Implementation Notes

- Implemented `DailyDecayFutureCall` and `DailyDecayService` in `string_theory_server/lib/src/future_calls/daily_decay_future_call.dart` adhering to Serverpod 4 FutureCall requirements (`Future<void> execute(Session session)`).
- `DailyDecayService.performDecayCalculation` scans all active `StringJob` records, recalculating composite health scores via `DecayEngine.calculateHealth` and updating modified scores with per-job error logging boundaries.
- Scheduled nightly recurring execution via cron `0 0 * * *` on `pod.futureCalls.callRecurring(identifier: 'dailyDecayFutureCall')` in `server.dart`.
- Added `triggerDailyDecayNow(session)` RPC endpoint method in `BagEndpoint`, requiring authentication and executing the decay scan on demand.
- Ran `serverpod generate` to generate client API and FutureCall dispatcher wrappers.
- Added "DEVELOPER & JUDGE CONTROLS" section in `SettingsScreen` with button `[⚡ Trigger FutureCall Decay]` (`key: Key('dev_trigger_decay_button')`), displaying progress spinner while decaying, debouncing duplicate taps, logging `[DevControl] DailyDecayFutureCall executed: X active string jobs updated` to console, providing styled SnackBar feedback, and dispatching `LoadBag` to reload the virtual bag.
- Added comprehensive integration tests in `daily_decay_future_call_test.dart` and widget tests in `settings_screen_test.dart`. 28 backend tests and 70 Flutter tests passing with zero analyzer warnings.

## Review Triage Log

- Missing Database Transaction and Error Boundary in `DailyDecayService` — low/patch: added per-job try-catch error boundary with error logging so a single failure doesn't abort the batch.
- Missing Pagination / Chunking and N+1 Sequential Writes in Background Decay — low/defer: logged in `deferred-work.md`.
- Global Multi-Tenant Exposure and Discarded User Identity in `BagEndpoint.triggerDailyDecayNow` — false: on-demand triggering of the system-wide background worker is the explicit specification requirement for hackathon judges and maintainers in Story 2.3 AC.
- Missing Concurrency Control / Mutex Guard Against Overlapping Decay Executions — low/defer: cron is protected by Serverpod claim tables; dev RPC concurrency lock logged in `deferred-work.md`.
- Missing Real-Time Stream / WebSocket Notification on Score Updates — false: WebSocket streaming is explicitly scheduled for Epic 3, Story 3.2.
- Missing Loading State and Re-entrancy Debouncing in `SettingsScreen` — medium/patch: converted `SettingsScreen` to `StatefulWidget` with `_isDecaying` state, progress indicator, and disabled state during RPC calls.
- Missing `BagBloc` Fallback Resolution in `SettingsScreen` — low/patch: added fallback to `context.read<BagBloc>()` if constructor parameter is omitted.
- Inconsistent Error SnackBar Theming and Formatting in `SettingsScreen` — low/patch: implemented `_showErrorFeedback` styled with signature error theme and formatted messages.
- Superficial Assertions in Integration Test `daily_decay_future_call_test.dart` (AC-2) — medium/patch: updated test to seed an active job needing decay and verify persistence of updated health score.
- Missing Test Coverage for `DailyDecayFutureCall` Class and Idempotency — medium/patch: added AC-4 test covering `DailyDecayFutureCall().execute(session)` and verifying 0 updates on immediate repeat run.
- Missing Error Handling Widget Test in `settings_screen_test.dart` — low/patch: added widget test verifying error feedback when RPC fails.

### Review Findings (Code Review 2026-10-04)

- [x] [Review][Patch] Add per-job try-catch error boundary and error logging in `DailyDecayService` [`daily_decay_future_call.dart:33`]
- [x] [Review][Patch] Convert `SettingsScreen` to `StatefulWidget` with loading state, debouncing, and disabled state [`settings_screen.dart:11`]
- [x] [Review][Patch] Add `BagBloc` fallback resolution from `BuildContext` in `SettingsScreen` [`settings_screen.dart:245`]
- [x] [Review][Patch] Implement `_showErrorFeedback` with styled SnackBar in `SettingsScreen` [`settings_screen.dart:233`]
- [x] [Review][Patch] Assert database persistence in `daily_decay_future_call_test.dart` AC-2 [`daily_decay_future_call_test.dart:112`]
- [x] [Review][Patch] Add `DailyDecayFutureCall.execute` and idempotency test (AC-4) [`daily_decay_future_call_test.dart:129`]
- [x] [Review][Patch] Add RPC error handling widget test in `settings_screen_test.dart` [`settings_screen_test.dart:310`]
- [x] [Review][Defer] Add database pagination and chunked batch writes to DailyDecayService [`daily_decay_future_call.dart:28`]
- [x] [Review][Defer] Implement rate limiting or distributed lock on on-demand `triggerDailyDecayNow` RPC [`bag_endpoint.dart:234`]

### Rejected Findings

- Global multi-tenant execution in `triggerDailyDecayNow`: False (the endpoint is specifically designed to invoke the background cron worker on demand for judges and system maintainers as defined in Story 2.3 AC).
- Missing WebSocket / stream message: False (real-time WebSocket streaming is explicitly slated for Story 3.2 in Epic 3).
