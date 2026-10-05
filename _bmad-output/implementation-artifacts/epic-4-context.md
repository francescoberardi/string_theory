# Epic 4 Context: Restringing Lifecycle & Historical Timeline

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Provide tennis players with seamless restringing lifecycle tracking when strings become dead (<40% health score), featuring in-app health alerts, an instantaneous 2-option "Restrung Today" action ([Keep Same & Reset] vs [Change Specs]) that resets health to 100% atomically in a database transaction, and an interactive historical timeline on the racquet detail screen archiving past stringbed setups with court hours and active days.

## Stories

- Story 4.1: Serverpod RestringEvent Schema & Transactional Restring Endpoint
- Story 4.2: "Restrung Today" 2-Option Decision Sheet & Toast Confirmation
- Story 4.3: Racquet Detail Screen & Restring History Timeline UI

## Requirements & Constraints

- **Multi-Tenant Scoping (ARCH-3):** `RestringEvent` table includes indexed `userId: int` column, validated against `session.authenticated.userId`.
- **Atomic Restring Operations (FR-16, NFR-5):** Archiving a retired `StringJob` and initializing a new active `StringJob` must execute within a single Serverpod database transaction to prevent orphan or corrupted racquets. If any step fails, the entire transaction rolls back cleanly.
- **Historical Stringbed Archival (FR-16):** Upon restringing, the retired `StringJob` is marked `isActive = false`, and a `RestringEvent` snapshot is persisted recording: `userId`, `racquetId`, `stringJobId`, `stringDescription`, `materialCategory`, `stringingDate`, `restringDate`, `finalCourtHours`, `finalDaysActive`, and `finalHealthScore`.
- **Fresh Stringbed Initialization (FR-15):** A new active `StringJob` is inserted with `totalCourtHours = 0`, `currentHealthScore = 100`, `isActive = true`, and `stringingDate = DateTime.now().toUtc()`. If "Keep Same", specifications (brand, model, tension, material category, gauge) carry over from the previous `StringJob`. If "Change Specs", new specifications provided by the player are applied.
- **Real-Time WebSocket Notification:** Publishing a `BagStreamMessage` (or bag stream update) ensures all connected client instances reflect the 100% health reset in real time without manual re-fetch.
- **Restring History Timeline (FR-17):** Players can view chronological timelines of retired stringbeds per racquet to evaluate durability and tension longevity.

## Technical Decisions

- **RestringEvent Model (`restring_event.spy.yaml`):**
  - Fields: `userId: int`, `racquetId: int` (relation parent `racquet`), `stringJobId: int` (relation parent `string_job`), `stringDescription: String`, `materialCategory: StringMaterialCategory`, `stringingDate: DateTime`, `restringDate: DateTime`, `finalCourtHours: double`, `finalDaysActive: int`, `finalHealthScore: int`, `createdAt: DateTime`.
  - Indexes: `restring_event_user_id_idx` on `userId`, `restring_event_racquet_id_idx` on `racquetId`.
- **BagEndpoint Restring RPC:**
  - Method `restringRacquet(Session session, int racquetId, {StringJob? newSpecs, bool keepSame = true})` (or typed payload matching requirements).
  - Enforces `session.authenticated.userId`.
  - Executes inside `session.db.transaction((tx) async { ... })`.
  - Calculates `finalDaysActive = restringDate.difference(stringingDate).inDays` (clamped to $\ge 0$).
  - Sets active `StringJob.isActive = false`.
  - Inserts `RestringEvent`.
  - Inserts new `StringJob` with `isActive = true`, `totalCourtHours = 0.0`, `currentHealthScore = 100`.
  - Broadcasts `BagStreamMessage` over `user_{userId}_bag` WebSocket channel.
  - Returns the updated `Racquet` with active `StringJob` attached.
- **Query Endpoint:**
  - Method on `BagEndpoint` to fetch restring history for a racquet: `getRestringHistory(Session session, int racquetId)` returning `List<RestringEvent>`.

## UX & Interaction Patterns

- **"Restrung Today" 2-Option Decision Sheet (UX-DR5):**
  - Triggered by `[Restrung Today]` button on Racquet Card.
  - Option 1: `[Keep Same & Reset]` — 1-tap reset using previous specs.
  - Option 2: `[Change Specs]` — expands fields for brand, model, tension, and material category.
  - Celebratory toast: *"Fresh stringbed mounted! Restrung to 100% health."*
- **Racquet Detail Timeline (UX-DR1):**
  - Chronological card/node timeline showing retired string jobs, hours played, days active, and final health score.

## Cross-Story Dependencies

- Story 4.1 establishes the database schema (`RestringEvent`), migrations, transactional `restringRacquet` endpoint, and `getRestringHistory` endpoint.
- Story 4.2 consumes the transactional endpoint in Flutter via `BagBloc` (`RestringRacquet` event) and presents the 2-option sheet and celebratory toast.
- Story 4.3 consumes `getRestringHistory` to build the Racquet Detail screen history timeline tab.
