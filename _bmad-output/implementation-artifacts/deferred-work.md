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
