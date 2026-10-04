# Epic 3 Context: Effortless Match Logging, Real-Time Sync & In-App Workout Generator

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Enable players to capture court playtime in under 10 seconds through automated Apple Health / Health Connect workout detection (with a rapid assignment sheet and progressive disclosure accordion), a rapid manual logger, and an in-app mock workout simulator for judges. Updates synchronize across devices instantly via Serverpod WebSockets, incrementing active stringbed court hours and recalculating dynamic string decay idempotently without double-counting.

## Stories

- Story 3.1: Serverpod SessionLog Schema, SessionEndpoint & Idempotency
- Story 3.2: Serverpod Real-Time WebSocket Streaming & BagStreamMessage
- Story 3.3: HealthSyncService Strategy Pattern & Judge Simulation Generator
- Story 3.4: Progressive Disclosure Workout Assignment Sheet & 3-Tap Quick Logger
- Story 3.5: Offline Session Queue with Auto-Reconnection Sync

## Requirements & Constraints

- **Multi-Tenant Security (ARCH-3):** All `SessionLog` entries are scoped directly with indexed `userId: int` column, validated against `session.authenticated.userId`.
- **Idempotency & Deduplication (FR-13, ARCH-3):** Unique index on `externalWorkoutId` ensures repeated or re-synced workouts from HealthKit/Health Connect never double-count play hours. Calling `SessionEndpoint.logSession` with an already-logged `externalWorkoutId` returns the existing record idempotently.
- **Atomic String Job Updates (FR-12):** When a session is logged, the racquet's active `StringJob.totalCourtHours` is incremented by session duration (converted to hours: `durationMinutes / 60.0`), and `DecayEngine` recalculates `StringJob.currentHealthScore`.
- **Real-Time WebSocket Updates (FR-14, ARCH-4, NFR-2):** Serverpod broadcasts `BagStreamMessage(eventType, racquetId, healthScore)` over `user_{userId}_bag` channel; clients receive updates in $<300$ ms and update state without manual refresh.
- **Health Platform Abstraction (FR-11, ARCH-5):** Strategy pattern for `HealthSyncService`:
  - `NativeHealthSyncService` on iOS/Android querying HealthKit / Health Connect tennis workouts locally.
  - `SimulatedHealthSyncService` on Web / Desktop with an instant `[🧪 Simulate Workout]` trigger generating a 90-minute tennis workout.
- **Privacy (NFR-7):** Apple Health workout parsing occurs strictly on-device; only the minimal `SessionLog` payload (timestamp, duration, racquet ID, surface, source) is transmitted to the server.
- **Offline Resilience (NFR-4):** Offline sessions are queued locally and synchronized automatically when network connection is re-established.

## Technical Decisions

- **SessionLog Model (`session_log.spy.yaml`):**
  - Fields: `userId: int`, `racquetId: int` (relation parent `racquet`), `startTime: DateTime`, `durationMinutes: int`, `courtSurface: String?`, `notes: String?`, `source: String`, `externalWorkoutId: String?`, `createdAt: DateTime`.
  - Unique index: `session_log_external_id_idx` on `externalWorkoutId`.
- **SessionEndpoint (`session_endpoint.dart`):**
  - `logSession(Session session, SessionLog log)`: requires auth, enforces `log.userId = session.authenticated.userId`, checks for existing `externalWorkoutId` (idempotent no-op/return existing), transactionally inserts `SessionLog`, fetches active `StringJob` for `racquetId`, increments `totalCourtHours`, recalculates health via `DecayEngine.calculateHealth`, updates `StringJob`, and publishes WebSocket message.
- **Shared Pure Dart DecayEngine:** Reused on the server to recalculate `currentHealthScore` on `StringJob` update.

## UX & Interaction Patterns

- **Assignment Sheet:** 1-tap confirmation with pre-selected primary racquet ($\le 2$ taps total).
- **Progressive Disclosure Accordion:** Expandable accordion reveals court surface chips (`Hard`, `Clay`, `Grass`) and session notes without cluttering default flow.
- **Quick Logger FAB:** Duration selector chips (`30m`, `1h`, `1.5h`, `2h`) allowing match logging in $<10$ seconds.
- **Judge Dev Trigger:** In-app badge `[🧪 Simulate Workout]` on Web/Desktop to test logging without mobile smartwatch setup.

## Cross-Story Dependencies

- Story 3.1 (`SessionLog` schema, `SessionEndpoint`, and idempotency) establishes the persistence layer and backend RPC required by Story 3.2 (WebSocket messaging), Story 3.3 (health sync abstraction), Story 3.4 (assignment UI), and Story 3.5 (offline queue sync).
- Story 3.2 connects `SessionEndpoint` modifications to real-time client UI streams.
- Story 3.3 feeds detected or simulated workouts into Story 3.4's assignment sheet.
