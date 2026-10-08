- source_spec: `_bmad-output/implementation-artifacts/spec-1-1-anonymous-guest-authentication-token-rehydration.md`
  summary: Align multi-tenant model schemas in Story 1.2 to use UuidValue/String for userId to match Serverpod 4.0.3 AuthUser authUserId rather than legacy int.
  evidence: Serverpod 4.0.3 `serverpod_auth_idp_server` uses `UuidValue` for `session.authenticated?.authUserId` instead of legacy Serverpod 2.x `int`.

- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-pure-dart-decayengine-domain-calculation-unit-tests.md`
  summary: Add a shared health-tier classification (green/amber/red) to DecayEngine so the gauge UI and server cron do not duplicate thresholds.
  evidence: Reviewer noted no tier API exists; real gap, but tiers are consumed by Story 2.2 (gauge) and not required by Story 2.1 ACs.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-pure-dart-decayengine-domain-calculation-unit-tests.md`
  summary: Eliminate the duplicated DecayEngine between string_theory_server and string_theory_flutter via a single shared source.
  evidence: The two files are identical apart from imports, so formulas can drift; consolidating needs a new shared package, which is beyond Story 2.1's scope.

- source_spec: `_bmad-output/implementation-artifacts/spec-2-2-animated-radial-health-gauge-widget-racquet-card-integration.md`
  summary: Await asynchronous BagLoaded or BagError emission in VirtualBagScreen pull-to-refresh.
  evidence: Reviewer noted RefreshIndicator.onRefresh resolves prematurely because Bloc.add(LoadBag()) is synchronous fire-and-forget; existing behavior from Story 1.5.

- source_spec: `_bmad-output/implementation-artifacts/spec-2-2-animated-radial-health-gauge-widget-racquet-card-integration.md`
  summary: Extract RacquetPreset and StringCategoryDefaults domain models out of add_racquet_modal.dart into domain layer.
  evidence: Pre-existing presentation file declared domain constants and defaults during Story 1.4; should be placed in pure domain models.

- source_spec: `_bmad-output/implementation-artifacts/spec-2-3-serverpod-dailydecayfuturecall-on-demand-test-trigger.md`
  summary: Add database pagination and chunked batch writes to DailyDecayService for large-scale deployments.
  evidence: Background worker queries all active string jobs into memory in a single query; acceptable for hackathon scale, but requires chunking/streaming for high volume production.

- source_spec: `_bmad-output/implementation-artifacts/spec-2-3-serverpod-dailydecayfuturecall-on-demand-test-trigger.md`
  summary: Implement rate limiting or distributed lock on on-demand triggerDailyDecayNow RPC endpoint.
  evidence: FutureCalls cron already uses Serverpod claim tables, but dev RPC endpoint allows unconstrained concurrent calls in multi-tenant environments.

- source_spec: `_bmad-output/implementation-artifacts/spec-3-1-serverpod-sessionlog-schema-sessionendpoint-idempotency.md`
  summary: Scope the SessionLog externalWorkoutId unique index per user with a composite (userId, externalWorkoutId) index.
  evidence: The global index makes the 409 at session_endpoint.dart reveal that another account owns an ID, and whoever claims an ID first blocks every other user; low risk with random HealthKit/Health Connect UUIDs, but needs a schema migration beyond Story 3.1.

- source_spec: `_bmad-output/implementation-artifacts/spec-3-1-serverpod-sessionlog-schema-sessionendpoint-idempotency.md`
  summary: Extract the duplicated _resolveUserId tenant resolver from BagEndpoint and SessionEndpoint into one shared helper.
  evidence: The two copies are identical; if they drift, the same user resolves to a different userId in one endpoint and every scoped query returns 404.

- source_spec: `_bmad-output/implementation-artifacts/spec-3-1-serverpod-sessionlog-schema-sessionendpoint-idempotency.md`
  summary: Tighten logSession input validation for startTime, durationMinutes upper bound, and racquetId mismatch on dedup hits.
  evidence: Only durationMinutes > 0 is checked; future startTime and unbounded durations are accepted (one huge session drives health to 0), and a duplicate externalWorkoutId sent for a different racquet silently returns the original row.

- source_spec: `_bmad-output/implementation-artifacts/spec-3-2-serverpod-real-time-websocket-streaming-bagstreammessage.md`
  summary: Publish BagStreamMessage from DailyDecayFutureCall, fastForwardRacquetAge, and racquet CRUD so open clients stay live for every health/bag change, not only session logging.
  evidence: Story 3.2 intent limited publishing to sessionLogged (restrung comes in 4.1); review noted the nightly decay cron is the main source of score changes yet pushes nothing to connected clients.

- source_spec: `_bmad-output/implementation-artifacts/spec-3-2-serverpod-real-time-websocket-streaming-bagstreammessage.md`
  summary: Add a stringJobId to BagStreamMessage (or refetch on restrung) before Story 4.1 publishes restrung events.
  evidence: BagBloc._onBagStreamReceived patches whichever activeStringJob is in its current state; a restrung message would overwrite the old job's score/hours instead of swapping in the new job.

- source_spec: `_bmad-output/implementation-artifacts/spec-3-2-serverpod-real-time-websocket-streaming-bagstreammessage.md`
  summary: Configure Redis before running more than one server instance so bag updates reach subscribers on every instance.
  evidence: No `redis` block exists in string_theory_server/config/*.yaml; MessageScope.auto then delivers in-process only, so a client connected to another instance never receives the message.

- source_spec: `_bmad-output/implementation-artifacts/spec-3-3-healthsyncservice-strategy-pattern-judge-simulation-generator.md`
  summary: Re-run health sync when the app returns to the foreground (and coalesce concurrent syncs) so matches finished while the app is backgrounded are detected without a cold start.
  evidence: VirtualBagScreen._bindHealthSyncService syncs once per service bind and nothing in lib/ observes AppLifecycleState; the human chose launch-only sync for Story 3.3 (2026-10-04). Adding a resume trigger makes concurrent syncWorkouts() calls reachable, which the Android plugin's single pending result does not tolerate.

- source_spec: `_bmad-output/implementation-artifacts/spec-3-3-healthsyncservice-strategy-pattern-judge-simulation-generator.md`
  summary: Verify on device (Patrol) that Android Health Connect permissions in AndroidManifest.xml match PluginHealthGateway.authorizationTypesFor and that the permission flow works with FlutterFragmentActivity.
  evidence: Only Dart-side type lists are unit-tested with a mocked Health; dropping a manifest permission or reverting MainActivity passes every test while syncWorkouts() silently returns [] on device. No Patrol or integration_test setup exists yet.

- source_spec: `_bmad-output/implementation-artifacts/spec-3-3-healthsyncservice-strategy-pattern-judge-simulation-generator.md`
  summary: Surface health-access status to the user (Health Connect not installed, permission denied) instead of a silent empty sync.
  evidence: NativeHealthSyncService only debugPrints on denial or plugin errors (per Story 3.3's frozen intent); there is no getHealthConnectSdkStatus() check and no Settings entry, so "no tennis workouts" and "not connected" look identical.

- source_spec: `_bmad-output/implementation-artifacts/spec-3-3-healthsyncservice-strategy-pattern-judge-simulation-generator.md`
  summary: Reconcile detected workouts against already-logged SessionLogs (or persist seen ids) so each cold start does not re-detect the last 7 days as new.
  evidence: _seenIds and _lastSync are in-memory by Story 3.3 decision; every launch re-emits workouts the server already holds under the unique externalWorkoutId index. Story 3.4 consumes pendingWorkouts and must filter them.

## Deferred from: code review of spec-3-4-progressive-disclosure-workout-assignment-sheet-3-tap-quick-logger.md (2026-10-04)

- Raw exception text (`'Failed to ...: $e'`) is surfaced verbatim in user-facing SnackBars/BagError across all `BagBloc` handlers (`string_theory_flutter/lib/bloc/bag_bloc.dart`). Map known failures (unstrung racquet, invalid duration, offline) to friendly messages and log the rest. Pre-existing pattern.
- Detected workouts that cannot be opened immediately become unreachable: only `batch.first` of a multi-workout sync gets the sheet/Assign; detections arriving while an assignment sheet is open are skipped (Assign SnackBar expires under the modal barrier); detections arriving while the bag is loading never auto-open and Assign wrongly says "add a racquet" (`string_theory_flutter/lib/screens/virtual_bag_screen.dart:167`). Options: sequential queue drained on sheet close / bag load, or a pending-workouts list. Reason: out of scope for 3-4, handle in story 3.5.

## Deferred from: code review of spec-4-1-serverpod-restringevent-schema-transactional-restring-endpoint.md (2026-10-05)

- `resolveUserId` (`string_theory_server/lib/src/util/tenant_resolver.dart`) derives the `int` tenant id from `userIdentifier` by UUID mod 2^63-1 or an FNV-1a hash fallback, accepts negative integer strings, has no unit tests, and throws a domain `BagException` from a generic util. Pre-existing logic moved verbatim from `SessionEndpoint` in Story 4.1; collision odds are negligible. Revisit the identity-to-`userId` mapping when auth is reworked.
- Add tests that another user's `bagUpdates` stream receives no `restrung` message from someone else's restring, and that a failed `postMessage` does not fail a committed restring (`string_theory_server/test/integration/bag_endpoint_test.dart` or `bag_stream_test.dart`). The success path is already verified.

## Deferred from: code review of spec-epic-3-retro-3-decompose-virtualbagscreen-and-assignmentsheet.md (2026-10-05)

- `SessionsPlaceholder` still tells users "Session logging & Apple Health sync coming soon in Epic 2." (`string_theory_flutter/lib/widgets/bag/sessions_placeholder.dart:46`). It exposes internal planning vocabulary and is stale now that session logging has shipped. Pre-existing copy moved verbatim; replace it with real copy or a real Sessions screen.
- The Bag/Sessions/Account destinations are defined twice, in `BagBottomNav` and `BagNavigationRail`, and the tab index order is implicit. Adding a tab (likely in Epic 5) means editing both and keeping indices aligned with `_onNavigationTapped`. Pre-existing duplication; extract a shared destinations constant when a tab is added.
- Info SnackBar icon (`cloud_off_outlined` for pending sync vs `cloud_done_outlined`) and error SnackBar `healthCritical` background are not asserted (`string_theory_flutter/lib/widgets/bag/bag_snack_bars.dart`). Visual-only; message text is already verified in `test/virtual_bag_screen_test.dart`.

- source_spec: `_bmad-output/implementation-artifacts/spec-4-2-restrung-today-2-option-decision-sheet-toast-confirmation.md`
  summary: Make the tablet grid card height flexible instead of the fixed `gridCardExtent` so larger system text scales do not overflow.
  evidence: `BagRacquetList` uses a fixed `mainAxisExtent` (140 before, 176 now with the Restrung Today button); only default text scale is tested, and a large font or long name overflows the cell.

- source_spec: `_bmad-output/implementation-artifacts/spec-4-3-racquet-detail-screen-restring-history-timeline-ui.md`
  summary: Unconstrained wide-screen layout on tablet/desktop for RacquetDetailScreen.
  evidence: On tablet/desktop viewports, stat cards and headers stretch to window bounds; deferred to Epic 5 (Story 5.1 Responsive Layout & Desktop Grid).

- source_spec: `_bmad-output/implementation-artifacts/spec-epic-3-retro-2-map-raw-exceptions-in-bagbloc.md`
  summary: Surface an expired session (401) on log session instead of queueing it offline with the "Session saved offline" toast.
  evidence: `isPermanentSessionRejection` treats 401 as transient, so `BagBloc._onLogSession` queues the session and the mapper's session-expired copy is never shown for this operation; the queue keeps retrying until the app restarts and re-provisions the guest. Pre-existing routing, left unchanged by the friendly-errors story.

- source_spec: `_bmad-output/implementation-artifacts/spec-epic-3-retro-2-map-raw-exceptions-in-bagbloc.md`
  summary: Separate the post-mutation `getVirtualBag` refresh from the mutation in `_onAddRacquet`, `_onDeleteRacquet`, `_onSetPrimaryRacquet` and `_onFastForwardRacquetAge` so a failed refresh is not reported as a failed mutation.
  evidence: The create/delete/setPrimary RPC and the refresh share one try/catch in `string_theory_flutter/lib/bloc/bag_bloc.dart`; if the RPC succeeds and the refresh throws, the user sees "Couldn't add ..." and retrying creates a duplicate racquet. `_onLogSession` already splits these.
- source_spec: `_bmad-output/implementation-artifacts/spec-epic-5-retro-1-fix-fake-endpoint-null-safety-in-auth-test.md`
  summary: Add a fake serverpod_auth_core status caller to auth_service_test so the valid-session and server-rejected-session (guest login fallback) paths are tested without any real network I/O.
  evidence: The tests now rely on a dead port (127.0.0.1:1) making validation fail, so `isSignedIn() == true` and the signOut→loginAsGuest fallback in `AuthService.initialize()` are never deliberately exercised.
- source_spec: `_bmad-output/implementation-artifacts/spec-epic-5-retro-1-fix-fake-endpoint-null-safety-in-auth-test.md`
  summary: Correct the `AuthService.initialize()` doc comment, which claims restore happens "without network blocking" although it awaits server validation (up to 2s).
  evidence: `string_theory_flutter/lib/services/auth_service.dart:36-39` vs serverpod_auth_core_client 4.0.3 `ClientAuthSessionManager.initialize()` awaiting `validateAuthentication(timeout: 2s)`.
- source_spec: `_bmad-output/implementation-artifacts/spec-epic-4-retro-13-update-stale-sessions-placeholder-copy.md`
  summary: Add an action to the Sessions placeholder (switch to the Bag tab or open the session logger) or replace it with a real session history screen.
  evidence: The Epic 4 retro suggested linking to active session logs. The copy fix only gives instructions, so users must navigate by hand.

- source_spec: `_bmad-output/implementation-artifacts/spec-epic-2-retro-2-add-batch-pagination-dailydecayfuturecall.md`
  summary: Make DailyDecayService score writes conditional on the hours/active state read with the page (or lock rows) so a concurrent logSession or restring is not overwritten by a stale score.
  evidence: The service computes the score from `totalCourtHours` read with the page and writes it later; a session logged in between gets its lower score replaced by the stale higher one until the next run.

- source_spec: `_bmad-output/implementation-artifacts/spec-epic-2-retro-2-add-batch-pagination-dailydecayfuturecall.md`
  summary: Add tests for DailyDecayService's per-job calculation error boundary and its row-by-row fallback after a failed batch write.
  evidence: Both paths are untested because DecayEngine never throws and the batch write has no injectable seam to force a failure.

- source_spec: `_bmad-output/implementation-artifacts/spec-epic-2-retro-2-add-batch-pagination-dailydecayfuturecall.md`
  summary: Prevent overlapping DailyDecayService runs (scheduled cron vs. triggerDailyDecayNow), e.g. with a Postgres advisory lock.
  evidence: Concurrent runs scan and write the same rows, which widens the stale-score race.

- source_spec: `_bmad-output/implementation-artifacts/spec-epic-2-retro-2-add-batch-pagination-dailydecayfuturecall.md`
  summary: Publish BagStreamMessage health updates to affected users when the daily decay run changes scores.
  evidence: Session logging pushes new health scores over the bag stream, but the cron writes silently, so connected clients show stale scores until they reload.

- source_spec: `_bmad-output/implementation-artifacts/spec-6-3-native-uuid-tenant-migration-backend-concurrency-live-update.md`
  summary: Decay advisory lock lives on an idle transaction for the whole run, so a production idle_in_transaction_session_timeout could kill it mid-run and let a second run start (unverified, would be medium).
  evidence: performDecayCalculation holds pg_try_advisory_xact_lock on a transaction left idle while pages run on other connections; settle by checking the production Postgres idle_in_transaction_session_timeout or adding SET LOCAL idle_in_transaction_session_timeout = 0.
- source_spec: `_bmad-output/implementation-artifacts/spec-6-3-native-uuid-tenant-migration-backend-concurrency-live-update.md`
  summary: The row-by-row fallback in DailyDecayService._updatePage (conditional updateWhere, written-only count and publish) has no test.
  evidence: No test forces the batch unsafeQuery to fail; reverting the fallback to an unconditional updateRow would pass the suite. Needs a seam to make the batch write throw.
- source_spec: `_bmad-output/implementation-artifacts/spec-6-3-native-uuid-tenant-migration-backend-concurrency-live-update.md`
  summary: Tenant userId columns on racquet, string_job, session_log and restring_event have no foreign key to serverpod_auth_core_user, so deleting an auth user leaves orphan rows.
  evidence: The int userId had no FK before Story 6.3 either; the UUID retype makes an FK with ON DELETE CASCADE possible.
- source_spec: `_bmad-output/implementation-artifacts/spec-6-1-state-management-resilience-mutation-refresh-decoupling-async-pull-to-refresh-auth-401-routing.md`
  summary: After the 401 "Sign in" re-auth, BagBloc's bag-updates stream may stay bound to the expired identity, so live updates stop until restart (unverified, medium).
  evidence: `_subscribeToBagUpdates` no-ops while `_bagUpdatesSubscription` is non-null. To settle it, confirm in the running app whether Serverpod errors or closes the streaming connection on 401 or on an auth key change.
