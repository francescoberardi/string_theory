# String Theory — Solution Design & System Architecture
**Built for the Serverpod Hackathon: "Build Something Real"**

## 1. System Context & Architecture Overview

String Theory is designed as a reactive, low-latency mobile and web application that monitors tennis gear degradation and string health in real time. The solution bridges on-device health sensor ingestion with Serverpod's high-performance Dart backend.

```mermaid
C4Context
    title System Context Diagram — String Theory
    Person(player, "Tennis Player", "Logs sessions, views string health gauges, restrings gear.")
    Person(judge, "Hackathon Judge", "Evaluates system via Flutter Web / macOS Simulator.")
    
    System_Boundary(c1, "String Theory Platform") {
        System(flutter_app, "String Theory Flutter Client", "Flutter iOS/Android/Web app powered by BLoC state.")
        System(serverpod_server, "Serverpod 4.0 Backend", "RPC Endpoints, Real-Time Streams, FutureCall Workers.")
        SystemDb(postgres_db, "PostgreSQL Database", "Stores Users, Racquets, StringJobs, Sessions, Restring Logs.")
    }

    System_Ext(healthkit, "Apple Health / Health Connect", "Smartwatch tennis workout detection.")

    Rel(player, flutter_app, "Views gauges, logs playtime in <10s", "Touch / UI")
    Rel(judge, flutter_app, "Simulates workouts & tests live streams", "Web Browser")
    Rel(healthkit, flutter_app, "Discovered Tennis Workouts", "HealthKit / Health Connect API")
    Rel(flutter_app, serverpod_server, "RPC Calls & WebSocket Streams", "HTTPS / WSS")
    Rel(serverpod_server, postgres_db, "Reads / Writes ORM Entities", "PostgreSQL TCP")
```

---

## 2. Core Entity Relationship Diagram (ERD)

The database schema guarantees row-level multi-tenant security by indexing `userId` across every core table, while maintaining clean 1:1 and 1:N relations.

```mermaid
erDiagram
    SERVERPOD_USER ||--o{ RACQUET : "owns"
    SERVERPOD_USER ||--o{ STRING_JOB : "owns"
    SERVERPOD_USER ||--o{ SESSION_LOG : "plays"
    SERVERPOD_USER ||--o{ RESTRING_EVENT : "logs"

    RACQUET ||--o{ STRING_JOB : "installed on"
    RACQUET ||--o{ SESSION_LOG : "assigned to"
    RACQUET ||--o{ RESTRING_EVENT : "history of"
    STRING_JOB ||--o| RESTRING_EVENT : "archived into"

    RACQUET {
        int id PK
        int userId FK "Indexed tenant key"
        string name "Frame model (e.g. Wilson Blade 98)"
        string brand "Manufacturer"
        string model "Generation"
        boolean isPrimary "Default in bag"
        timestamp createdAt
        timestamp updatedAt
    }

    STRING_JOB {
        int id PK
        int userId FK "Indexed tenant key"
        int racquetId FK "Belongs to racquet"
        string materialCategory "coPoly | multifilament | syntheticGut | naturalGut"
        string brand "String Brand (e.g. Babolat)"
        string model "String Model (e.g. RPM Blast 1.25)"
        timestamp stringingDate "Strung timestamp"
        float installedTension "lbs or kg"
        float maxRatedHours "Defaults: CoPoly=20h, Multi=35h"
        float totalCourtHours "Accumulated play time"
        int currentHealthScore "0-100% computed score"
        boolean isActive "True for current mounted strings"
        timestamp createdAt
    }

    SESSION_LOG {
        int id PK
        int userId FK "Indexed tenant key"
        int racquetId FK "Racquet used"
        timestamp startTime "Session start"
        int durationMinutes "Played duration"
        string courtSurface "hard | clay | grass | carpet"
        string notes "Match notes"
        string source "apple_health | health_connect | manual | simulator"
        string externalWorkoutId UK "UUID to guarantee idempotency"
        timestamp createdAt
    }

    RESTRING_EVENT {
        int id PK
        int userId FK "Indexed tenant key"
        int racquetId FK "Racquet restrung"
        int stringJobId FK "Retired string job"
        string stringDescription "Snapshot of string setup"
        string materialCategory "String category"
        timestamp stringingDate "When installed"
        timestamp restringDate "When retired"
        float finalCourtHours "Total court hours logged"
        int finalDaysActive "Total calendar days"
        int finalHealthScore "Health score when retired"
        timestamp createdAt
    }
```

---

## 3. End-to-End Sequence Diagrams

### 3.1 Post-Match Workout Ingestion & Real-Time Sync Flow

This flow illustrates how an Apple Watch workout flows into String Theory, triggers a 1-tap assignment, and updates client gauges live over Serverpod streaming.

```mermaid
sequenceDiagram
    autonumber
    actor Player as 🎾 Tennis Player
    participant Watch as Apple Watch / WearOS
    participant App as String Theory App (BLoC)
    participant Server as Serverpod Server
    participant DB as PostgreSQL
    participant PubSub as Serverpod Messages

    Player->>Watch: Ends Tennis Match
    Watch-->>App: Syncs HKWorkout (Tennis, 90 min)
    App->>App: HealthSyncService detects new workout
    App->>Player: Triggers Local Alert: "1h 30m Tennis Match Detected!"
    Player->>App: Taps Notification -> Selects [Wilson Blade 98] (1 tap)
    
    Note over App,Server: Optimistic UI: Gauge animates drop locally via DecayEngine
    
    App->>Server: SessionEndpoint.logSession(racquetId, 90m, workoutUUID)
    activate Server
    Server->>DB: INSERT into session_log (ON CONFLICT externalWorkoutId DO NOTHING)
    Server->>DB: SELECT StringJob WHERE racquetId = :id AND isActive = true
    Server->>Server: DecayEngine.recalculate(totalHours + 1.5, daysElapsed)
    Server->>DB: UPDATE string_job SET totalCourtHours += 1.5, currentHealthScore = :newScore
    Server->>PubSub: postMessage("user_123_bag", BagStreamMessage(racquetId, newScore))
    Server-->>App: Return updated StringJob payload
    deactivate Server

    PubSub-->>App: WebSocket Push: BagStreamMessage
    App->>App: BagBloc reconciles server state (State: BagLoaded)
```

---

### 3.2 Scheduled Background Tension Decay (`FutureCalls`)

How Serverpod handles passive calendar creep while racquets sit inside the tennis bag.

```mermaid
sequenceDiagram
    autonumber
    participant Cron as DailyDecayFutureCall (Serverpod)
    participant DB as PostgreSQL
    participant PubSub as Serverpod Messages
    participant Push as Notification Gateway

    Note over Cron: Fires Daily at 00:00 UTC
    Cron->>DB: SELECT * FROM string_job WHERE isActive = true
    loop For each active StringJob
        Cron->>Cron: Calculate CalendarAgePenalty (daysElapsed / shelfLife)
        Cron->>DB: UPDATE string_job SET currentHealthScore = :recalculatedScore
        alt Score crossed below 40% (Dead Stringbed Alert)
            Cron->>Push: Dispatch alert: "⚠️ Stringbed exhausted. High elbow strain risk."
            Cron->>PubSub: postMessage("user_{userId}_bag", WarningMessage)
        end
    end
    Cron->>Cron: Schedule next execution in 24 hours
```

---

### 3.3 The 1-Tap "Restrung Today" Lifecycle Flow

```mermaid
sequenceDiagram
    autonumber
    actor Player as 🎾 Tennis Player
    participant App as String Theory App (BLoC)
    participant Server as Serverpod Server
    participant DB as PostgreSQL

    Player->>App: Taps [Restrung Today] on Racquet Card
    App->>Player: Presents Quick Sheet: [Keep Same: RPM Blast @ 52 lbs] or [Change Specs]
    Player->>App: Taps [Keep Same & Reset]
    
    App->>Server: BagEndpoint.restringRacquet(racquetId, keepSame = true)
    activate Server
    Note over Server,DB: Executed within a single DB Transaction
    Server->>DB: UPDATE string_job SET isActive = false WHERE id = :oldId
    Server->>DB: INSERT into restring_event (archived stats, hours, final health)
    Server->>DB: INSERT into string_job (new active setup, hours=0, healthScore=100)
    Server-->>App: Return fresh Racquet + StringJob
    deactivate Server

    App->>App: Gauge animates to 100% Solid Green
    App->>Player: Toast: "Racquet refreshed! Previous cycle saved to History."
```

---

## 4. Frontend BLoC Architecture (`string_theory_flutter`)

```mermaid
stateDiagram-v2
    [*] --> BagLoading
    BagLoading --> BagLoaded: BagFetched / StreamOpened
    BagLoaded --> BagSyncing: LogSessionSubmitted(racquetId, duration)
    BagSyncing --> BagLoaded: SessionPersisted / StreamMessageReceived
    BagLoaded --> BagRestringing: RestringSubmitted(racquetId, specs)
    BagRestringing --> BagLoaded: RestringCompleted
    BagLoaded --> BagError: NetworkFailure / ServerError
    BagError --> BagLoading: RetryTapped
```

### Key BLoC Events & States:
* **`BagBloc`:**
  * Events: `LoadBag`, `SessionLogged`, `RestringRequested`, `BagStreamReceived`, `SimulatedWorkoutTriggered`.
  * States: `BagLoading`, `BagLoaded(racquets, activeWorkouts)`, `BagActionInProgress`, `BagError`.
* **Strategy Ingestion:**
  * `HealthSyncService` abstract interface resolves:
    * `NativeHealthService` on physical iOS/Android.
    * `SimulatedHealthService` on Web, Simulator, and Desktop demo environments.

---

## 5. Hackathon Value & Evaluation Highlights

| Feature | Hackathon Demonstration Impact |
|---|---|
| **Zero-Friction Guest Auth** | Judges test immediately with no sign-up wall via Serverpod anonymous authentication. |
| **Instant Real-Time Stream** | Logging a session immediately updates connected web and mobile screens over Serverpod WebSockets. |
| **Automated Decay Worker** | Serverpod `FutureCalls` demonstrate enterprise background task scheduling for tension relaxation. |
| **Judge Workout Simulator** | Floating `[🧪 Simulate Workout]` button lets judges experience the full smartwatch detection loop on web/desktop. |
| **Clean Architecture & Tests** | Comprehensive test suite leveraging `serverpod_test` for backend endpoints and `bloc_test` for Flutter state. |
