---
title: 'Fix sample bag health resetting to 100% after the first logged session'
type: 'bugfix'
created: '2026-10-13'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** After "Load Sample Bag", logging the first session makes every racquet's health jump to ~100% instead of only lowering the selected racquet. The seeded court hours and health (5h/76%, 9h/58%, 25h/34%) are only overlaid in client memory by `BagBloc._onSeedSampleBag`. The server stores every seeded string job at `totalCourtHours: 0.0, currentHealthScore: 100`, so the post-log `getVirtualBag()` reload (and any later reload, stream event, or daily decay run) replaces the overlay with the real server values.

**Approach:** Persist the seeded state on the server. Add an optional `initialCourtHours` parameter to `BagEndpoint.createRacquet`. The endpoint computes the initial `currentHealthScore` with the shared `DecayEngine` from those hours, `maxRatedHours`, `stringingDate`, and the material category, instead of hardcoding 100. The sample bag seeder passes the demo hours and drops its client-side overlay.

**Decisions:**
- The seeded health comes from `DecayEngine`, not hardcoded numbers, so it stays consistent with later recalculations. The sample bag now shows ~78% / ~59% / ~39%. That's the same Green / Amber / Red tiers as the old 76 / 58 / 34.
- `initialCourtHours` defaults to 0. A negative or non-finite value is rejected with `BagException` 400.
- Computing the initial health from `stringingDate` also corrects racquets added through the form with a past stringing date, which used to show 100% until the next daily decay run. A racquet strung now with 0 hours still gets 100.
- Sample bags already loaded in an existing database are not migrated. Clear and reload the bag to see the fix.

</frozen-after-approval>

## Implementation Notes

- Files: `string_theory_server/lib/src/endpoints/bag_endpoint.dart` (createRacquet param + DecayEngine), regenerated client and test tools (`serverpod generate`), `string_theory_flutter/lib/bloc/bag_bloc.dart` (seed passes hours, overlay removed).
- Tests first (TDD): a server integration test in `bag_endpoint_test.dart` for persisted hours and computed health (plus 400 on negative hours), and a bloc test in `bag_bloc_test.dart` checking that the seed passes `initialCourtHours` and emits the reloaded server data unchanged. Update existing `createRacquet` mocks for the new named param.
- `decay_concurrency_test.dart` AC-4 assumed `createRacquet` stored 100 for a 30-day-old date. It now creates the racquet "strung now" and backdates the row directly without rescoring it, so the lock-held assertion can still tell whether decay ran.
- Added a server test pinning calendar decay at creation (past date, no hours => 88). Updated `docs/DEMO_SCRIPT.md` numbers to the engine-computed sample bag (78 / 59 / 39; Wilson 78 -> 72 after 90 min).
- Verified: `dart analyze` clean in server and flutter; `dart test` server 102/102; `flutter test` 431/431. Serverpod MCP log tailing was unavailable in this session.

## Review Triage Log

- Demo script shows old 76/67/34 numbers — medium, patched in `docs/DEMO_SCRIPT.md`. Older done specs (5-3, 5-4, 1-5) are historical records and stay unedited.
- No upper cap on initialCourtHours — low, rejected: the value is tenant-scoped and an absurd value only clamps the user's own health to 0.
- NaN / infinity / 0.0 boundary untested — low, rejected: JSON can't carry NaN or infinity from the generated client, and 0 hours is covered by the default path tests.
- Behaviour change for form-added racquets untested — medium, patched with a past-date, no-hours => 88 test.
- Seeded hours have no SessionLog rows — low, rejected: the old client overlay had no sessions either, and no code reconciles hours from logs.
- Form can't set initialCourtHours — deferred (feature idea).
- `[DecayEngine]` doc link unresolved in the generated client — low, patched to backticks.
- Future stringingDate accepted — deferred (pre-existing).
- Seeding is three non-atomic calls — deferred (pre-existing).
- Spec status and verification missing — false: the spec was mid-workflow, and is finalized here.
