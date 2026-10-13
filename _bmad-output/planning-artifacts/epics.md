---
stepsCompleted:
  - "step-01-validate-prerequisites"
  - "step-02-design-epics"
  - "step-03-create-stories"
  - "step-04-final-validation"
inputDocuments:
  - "_bmad-output/planning-artifacts/prds/prd-string_theory-2026-10-02/prd.md"
  - "_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/ARCHITECTURE-SPINE.md"
  - "_bmad-output/planning-artifacts/architecture/architecture-string_theory-2026-10-02/SOLUTION-DESIGN.md"
  - "_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/DESIGN.md"
  - "_bmad-output/planning-artifacts/ux/ux-string_theory-2026-10-02/EXPERIENCE.md"
  - "_bmad-output/implementation-artifacts/deferred-work.md"
---

# string_theory - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for string_theory, decomposing the requirements from the PRD, UX Design contracts, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

- **FR-1**: The system must generate an anonymous authenticated user session upon first launch via Serverpod's built-in auth mechanism without requiring email, password, or third-party OAuth.
- **FR-2**: The user can at any time link an email/password identity to their guest account from the Settings screen without losing data: the guest's racquets, string jobs, sessions and restring history move to the email account. (Google linking deferred to post-hackathon.)
- **FR-3**: The client must persist the authentication token securely on device storage (Keychain on iOS, Keystore on Android, secure web storage) and restore the active session on app relaunch.
- **FR-4**: The user can add a racquet with frame model, string material category, string model, stringing date, installed tension, and manufacturer max hours with smart defaults.
- **FR-5**: The Virtual Bag screen must display a scrollable list/grid of all registered racquets for the authenticated user, showing frame name, string model, stringing date, total hours logged, and an animated radial Health Score Gauge.
- **FR-6**: The user can update racquet details (frame nickname, photo/icon, notes) or soft-delete a retired racquet.
- **FR-7**: The user can mark one racquet as "Primary in Bag", causing it to be pre-selected by default in the session logging workflow.
- **FR-8**: The system must calculate HealthScore using the composite formula: 70% dynamic court hours penalty + 30% static calendar tension creep penalty calibrated by string material shelf-life.
- **FR-9**: The system must categorize Health Scores into three distinct states: Green (Optimal, >=70%), Amber (Degraded, 40-69%), and Red (Dead / High Risk, <40%).
- **FR-10**: The Serverpod backend must run a daily scheduled FutureCall that scans all active StringJobs, recalculates the calendar penalty, updates cached scores, and flags racquets crossing the <40% threshold.
- **FR-11**: The Flutter client must query the OS health subsystem (HealthKit on iOS, Health Connect on Android) for completed workout sessions with activity type tennis recorded since the last sync.
- **FR-12**: Tapping a detected workout opens a gear assignment sheet with 1-tap racquet selection and an expandable "Advanced options" accordion (split duration, court surface, notes).
- **FR-13**: From the Virtual Bag, tapping [+ Log Session] opens a modal allowing the user to select duration (quick chips: 30m, 1h, 1.5h, 2h), select racquet, and save in under 10 seconds.
- **FR-14**: When a session is saved, the Serverpod backend must broadcast an update through a real-time streaming endpoint (WebSocket) so connected Flutter clients update their gauges and play hours immediately.
- **FR-15**: Each racquet card must provide a [Restrung Today] action opening a quick sheet with [Keep Same & Reset] (1-tap reset to 100%) and [Change Specs] options.
- **FR-16**: Upon restringing, the retired StringJob is marked inactive and archived into a RestringEvent table recording total court hours, days active, and final health score.
- **FR-17**: The Racquet Detail screen must provide a "History" tab showing a chronological timeline of past stringbeds with performance stats.
- **FR-18**: The Flutter app must provide an accessible floating badge [🧪 Simulate Workout] on web/desktop environments that injects a simulated 90-minute tennis workout into the ingestion pipeline.
- **FR-19**: The dev menu must include a [Fast-Forward 30 Days] button for any selected racquet, advancing its stringing date by 30 days to immediately demonstrate calendar decay transitions and warning alerts.
- **FR-20**: On launch without a stored session, the app shows a sign-in screen offering email/password sign-in or sign-up and a "Continue as guest" action; a signed-in user can sign out from Settings and returns to the sign-in screen.

### NonFunctional Requirements

- **NFR-1**: Gauge animation transitions must render at 60 fps without frame drops on standard mobile devices.
- **NFR-2**: Serverpod streaming updates must reflect on the client within < 300 ms of session persistence.
- **NFR-3**: App cold-start to interactive Virtual Bag screen must be < 1.2 seconds using local cached state.
- **NFR-4**: If the player is on court without cellular data or Wi-Fi, the Flutter client must queue SessionLogs locally and sync automatically upon network reconnection.
- **NFR-5**: Archiving a retired StringJob and initializing a new active StringJob must execute within a single Serverpod database transaction to prevent orphan racquets.
- **NFR-6**: String Theory requests read-only access strictly for tennis workout data; no unrelated biometric or GPS coordinates requested.
- **NFR-7**: Apple Health workout parsing occurs locally on device; only the resulting SessionLog is transmitted to the Serverpod backend.
- **NFR-8**: All database entities must be declared in .spy.yaml schemas. No manual edits to generated code. Migrations generated via Serverpod MCP tools.
- **NFR-9**: Built-in Serverpod authentication module (serverpod_auth) utilized for session security, token management, and guest accounts.

### Additional Requirements

- **ARCH-1**: Monorepo structure using Serverpod 4.0.3 (string_theory_server, string_theory_client, string_theory_flutter) with PostgreSQL ORM.
- **ARCH-2**: Shared pure Dart `DecayEngine` domain class for client-side optimistic UI calculations and backend authoritative persistence.
- **ARCH-3**: Direct multi-tenant scoping: indexed `userId: int` on all 4 tables (Racquet, StringJob, SessionLog, RestringEvent) for row-level authorization.
- **ARCH-4**: BLoC pattern (`flutter_bloc`, `bloc_test`, `equatable`) for state management and Unidirectional Data Flow.
- **ARCH-5**: `HealthSyncService` strategy pattern separating `NativeHealthSyncService` from `SimulatedHealthSyncService`.
- **TEST-1**: Strict TDD Protocol (Red-Green-Refactor). Failing unit/bloc/endpoint tests must be written and committed before production implementation code.
- **TEST-2**: Patrol E2E Framework (`patrol`, `patrol_finders`) adopted as the official Flutter end-to-end testing harness, handling native OS permissions headlessly.

### UX Design Requirements

- **UX-DR1**: Court Midnight visual identity: dark graphite background (#121516), surface (#1A1E20), electric tennis volt (#C6F10E), Barlow Condensed headings & Inter body.
- **UX-DR2**: Animated Radial Health Gauge Component: glowing circular ring arc with color transitions (Green >=70%, Amber 40-69%, Red <40%) and center percentage + secondary tension loss text.
- **UX-DR3**: Responsive Adaptive Layout: Mobile (<600dp) uses bottom navigation bar + 1-column list; Tablet (600-1024dp) uses NavigationRail + 2-column grid; Desktop/Web (>1024dp) uses persistent drawer + multi-column grid.
- **UX-DR4**: Progressive Disclosure Quick-Log Sheet: collapsed 1-tap racquet selector + expandable "Advanced options" accordion (duration split, surface, notes).
- **UX-DR5**: "Restrung Today" 2-option sheet: [Keep Same & Reset] (1-tap reset) vs [Change Specs] (expandable specs form) + Toast notification.
- **UX-DR6**: Multi-platform input accommodations: >=48dp touch targets on mobile + keyboard shortcuts (L = Log, N = New, S = Simulate, Esc = Close) and mouse hover states on web.

### Technical Debt & Production Hardening Requirements

- **TD-1**: In `BagBloc`, decouple the mutation RPC (`addRacquet`, `deleteRacquet`, `setPrimaryRacquet`, `fastForwardRacquetAge`) from the subsequent `getVirtualBag` refresh so a failed refresh never misreports a successful creation as failed.
- **TD-2**: `VirtualBagScreen.onRefresh` must await the asynchronous `BagLoaded` / `BagError` resolution rather than firing-and-forgetting `LoadBag`.
- **TD-3**: In `BagBloc`, handle HTTP 401 unauthorized errors explicitly instead of routing them to the transient offline queue with the "saved offline" toast.
- **TD-4**: Observe `AppLifecycleState.resumed` to trigger workout sync when the user returns to the app, with debounce/concurrency locking and a 60-second cooldown gate against simultaneous plugin queries.
- **TD-5**: Buffer workouts arriving while the assignment modal or bag loading is active, allowing sequential assignment rather than discarding unhandled items.
- **TD-6**: Detect and surface missing Health Connect or denied permissions in the UI; persist seen external workout IDs to prevent re-alerting on cold start.
- **TD-7**: Non-blocking PostgreSQL advisory locks (`pg_try_advisory_lock(7421893)`) inside `DailyDecayService` to prevent concurrent execution between cron FutureCalls and dev triggers.
- **TD-8**: Optimistic conditional score updates on `totalCourtHours` in decay batches (`WHERE id = @jobId AND "totalCourtHours" = @readCourtHours`), skipping jobs concurrently updated by user sessions.
- **TD-9**: Delta-gated live WebSocket broadcasts (`BagStreamMessage`) when decay changes scores by >= 1%.
- **TD-10**: Clean data schema: migrate `userId` across `Racquet`, `StringJob`, `SessionLog`, and `RestringEvent` to `UuidValue` with database indices, add composite unique index `(userId, externalWorkoutId)` on `SessionLog`, and refactor `TenantResolver` to natively return `UuidValue` without hashing.
- **TD-11**: Replace `SessionsPlaceholder` with a dedicated, interactive Sessions history screen with direct quick-log shortcuts.
- **TD-12**: Relocate `RacquetPreset` and `StringCategoryDefaults` from UI widgets into pure domain models in the domain layer.
- **TD-13**: Serverpod auth secrets and IDP password environment variables match consistently across CI test matrices, with directory-scoped `git diff --exit-code` checks.
- **TD-14**: Fake `serverpod_auth_core` status caller in `auth_service_test.dart` to verify valid-session and guest fallback branches deterministically without real network timeouts.
- **TD-15**: A fresh clone can create `string_theory_server/config/passwords.yaml` with one documented command that generates random development and test secrets and never overwrites an existing file.
- **TD-16**: Multi-window session behavior on web is verified and documented: whether two tabs of one browser profile share an identity, and how a reviewer opens a second, independent account.

### FR Coverage Map

- **FR-1**: Epic 1 — Anonymous Guest Session (instant auth without login wall)
- **FR-2**: Epic 1 (stub) & Epic 6 — Account Linking / Upgrade (link email identity, guest data merged)
- **FR-3**: Epic 1 — Auth token persistence and secure re-hydration
- **FR-4**: Epic 1 — Add racquet with string setup and category smart defaults
- **FR-5**: Epic 1 — Multi-racquet responsive Virtual Bag display
- **FR-6**: Epic 1 — Racquet editing and soft-deletion
- **FR-7**: Epic 1 — Primary racquet designation in bag
- **FR-8**: Epic 2 — Composite decay formula (70% court hours + 30% calendar shelf-life)
- **FR-9**: Epic 2 — Health score status tiers (Green >=70%, Amber 40-69%, Red <40%)
- **FR-10**: Epic 2 — Serverpod scheduled background decay worker (FutureCalls) + on-demand test trigger
- **FR-11**: Epic 3 — Apple Health / Health Connect tennis workout detection
- **FR-12**: Epic 3 — 1-tap gear assignment sheet with progressive disclosure accordion
- **FR-13**: Epic 3 — Sub-10-second manual quick-log modal with duration chips
- **FR-14**: Epic 3 — Real-time WebSocket streaming updates across clients
- **FR-15**: Epic 4 — 1-tap "Restrung Today" reset action ([Keep Same] vs [Change Specs])
- **FR-16**: Epic 4 — Historical StringJob archival into RestringEvent table
- **FR-17**: Epic 4 — Restring history timeline view on racquet detail screen
- **FR-18**: Epic 3 & Epic 5 — One-click tennis workout simulator for judges and web testers
- **FR-19**: Epic 2 & Epic 5 — Fast-forward 30 days time-warp aging simulator
- **FR-20**: Epic 6 — Email sign-in screen, Continue as guest, real sign-out
- **TD-1 through TD-16**: Epic 6 — Technical Debt, Concurrency & Production Polish

## Epic List

### Epic 1: Zero-Friction Onboarding, Pre-Seeded Demo Bag & Racquet Setup
Players can launch String Theory, authenticate instantly as a guest without a login wall, load an instant sample bag or add custom racquets with smart string defaults, and view their Virtual Bag in the Court Midnight athletic dark theme.
**FRs covered:** FR-1, FR-2, FR-3, FR-4, FR-5, FR-6, FR-7

### Epic 1.5: DevOps — Multi-Package CI/CD Pipeline Automation
Developers and CI systems have automated linting, formatting, and unit/widget test verification running across all workspace packages (`string_theory_server`, `string_theory_client`, and `string_theory_flutter`), guarding the repository quality gate on every commit and pull request.
**Requirements covered:** TEST-1, ARCH-1, NFR-8

### Epic 2: Dynamic Health Score, Composite Decay & On-Demand FutureCall Trigger
Players see a real-time, scientifically grounded Health Score (0-100%) for every racquet, visualized via a glowing 60fps radial ring gauge with secondary tension loss text and color-coded status tiers, supported by a daily Serverpod FutureCall background decay scheduler and an on-demand trigger for judges.
**FRs covered:** FR-8, FR-9, FR-10, FR-19

### Epic 3: Effortless Match Logging, Real-Time Sync & In-App Workout Generator
Players capture court playtime in under 10 seconds through automated Apple Health / Health Connect tennis workout detection (with a 1-tap assignment sheet and progressive disclosure accordion), a rapid 3-tap manual logger, and an in-app mock workout simulator, with instant multi-device sync over Serverpod WebSockets.
**FRs covered:** FR-11, FR-12, FR-13, FR-14, FR-18

### Epic 4: Restringing Lifecycle & Historical Timeline
When strings go dead (<40%), players receive clear in-app alerts and can execute a 1-tap "Restrung Today" action ([Keep Same & Reset] vs [Change Specs]), instantly resetting their gauge to 100% and archiving past stringbeds into an interactive performance history timeline.
**FRs covered:** FR-15, FR-16, FR-17

### Epic 5: Hackathon Polish, Multi-Platform Adaptations & Judge Showcase Controls
Hackathon judges and web testers can evaluate the complete system across mobile, tablet, and desktop/web with responsive layouts (NavigationRail on tablet/web), keyboard shortcuts (L, N, S, Esc), and unified demo controls.
**UX/NFRs covered:** UX-DR3, UX-DR6, NFR-1, NFR-2, NFR-3

### Epic 6: Technical Debt, Concurrency & Production Polish
The system eliminates pre-release technical debt and concurrency vulnerabilities: aligns native UUID tenant identifiers across all Serverpod models and endpoints, secures daily decay background workers with PostgreSQL advisory locks and optimistic score writes, broadcasts live WebSocket health decay updates, decouples BLoC mutation errors from background reloads, hardens health workout queueing and lifecycle sync, delivers a dedicated Sessions history screen, adds real email sign-in with guest-account linking so the app can be tested across windows and accounts, and establishes CI parity and deterministic authentication tests.
**Requirements covered:** FR-2, FR-20, TD-1, TD-2, TD-3, TD-4, TD-5, TD-6, TD-7, TD-8, TD-9, TD-10, TD-11, TD-12, TD-13, TD-14, TD-15, TD-16

---

## Epic 1: Zero-Friction Onboarding, Pre-Seeded Demo Bag & Racquet Setup

Players can launch String Theory, authenticate instantly as a guest without a login wall, load an instant sample bag or add custom racquets with smart string defaults, and view their Virtual Bag in the Court Midnight athletic dark theme.

### Story 1.1: Anonymous Guest Authentication & Token Rehydration

As a tennis player or hackathon judge,  
I want to enter the app immediately upon launch as an authenticated guest,  
So that I can manage my gear bag without friction or mandatory account creation walls.

**Requirements Covered:** FR-1, FR-2, FR-3, NFR-9, ARCH-3

**Acceptance Criteria:**
- **Given** a user launches the app for the first time without credentials,
- **When** the app initializes,
- **Then** the Serverpod backend creates an anonymous authenticated user session via `serverpod_auth_idp` and returns an auth token,
- **And** the Flutter client persists the token securely on device storage (Keychain/Keystore/secure storage),
- **And** relaunching the app silently rehydrates the existing session without prompting for login,
- **And** the Settings screen provides a stubbed `[Link Google / Email]` option to upgrade the guest account (FR-2).

### Story 1.2: Serverpod Racquet & StringJob Schema & BagEndpoint

As a developer and system consumer,  
I want Serverpod database tables and an authoritative `BagEndpoint`,  
So that racquet frames and their mounted string installations are persisted safely with row-level tenant security.

**Requirements Covered:** FR-4, FR-6, FR-7, NFR-8, ARCH-1, ARCH-3

**Acceptance Criteria:**
- **Given** Serverpod `.spy.yaml` models for `StringMaterialCategory`, `Racquet`, and `StringJob` with indexed `userId: int`,
- **When** migrations are created and applied via Serverpod MCP tools,
- **Then** the PostgreSQL database tables `racquet` and `string_job` are created with foreign keys and indexes,
- **And** `BagEndpoint.getVirtualBag(session)` returns only racquets owned by the authenticated `session.authenticated.userId`,
- **And** `BagEndpoint.createRacquet(session, racquet, initialStringJob)` creates the racquet and active string job within a single database transaction,
- **And** `BagEndpoint.setPrimary(session, racquetId)` designates the primary racquet and unsets previous primaries for that user.

### Story 1.3: Court Midnight Theme & BagBloc Reactive State Foundation

As a tennis player,  
I want a responsive athletic dark theme and rock-solid state management,  
So that the app feels like a high-performance sports dashboard and never stutters.

**Requirements Covered:** ARCH-4, UX-DR1, UX-DR3

**Acceptance Criteria:**
- **Given** the Flutter application initialized with `flutter_bloc` and `google_fonts`,
- **When** the app renders,
- **Then** the Court Midnight theme is applied (graphite `#121516`, surface `#1A1E20`, electric volt `#C6F10E`, Barlow Condensed headers & Inter body per `DESIGN.md`),
- **And** `BagBloc` is implemented with events (`LoadBag`, `AddRacquet`, `DeleteRacquet`, `SetPrimaryRacquet`) and states (`BagLoading`, `BagLoaded`, `BagError`),
- **And** unit tests written with `bloc_test` verify state transitions with 100% pass rate.

### Story 1.4: Add Racquet Form with String Category Smart Defaults & Presets

As a tennis player,  
I want to add a racquet with automated smart defaults and popular presets,  
So that I don't have to look up manufacturer play hours or string technicalities.

**Requirements Covered:** FR-4, UX-DR1

**Acceptance Criteria:**
- **Given** a user opens the `[Add Racquet]` modal,
- **When** the user selects String Material Category `Co-Polyester`,
- **Then** Manufacturer Max Hours automatically pre-populates to `20.0 hrs`,
- **And** selecting `Multifilament` pre-populates to `35.0 hrs`, `Synthetic Gut` to `30.0 hrs`, and `Natural Gut` to `50.0 hrs` (all user-editable),
- **And** a 1-tap preset button `[Popular Poly: Babolat RPM Blast @ 52 lbs]` fills frame, string model, and tension instantly,
- **And** submitting the form dispatches `AddRacquet` to `BagBloc` and persists via Serverpod.

### Story 1.5: Virtual Bag Responsive Screen & Instant Demo Bag Seeder

As a hackathon judge or new player,  
I want to see my racquets in a responsive grid and have an instant "Sample Bag" button on empty state,  
So that I can test the full app immediately without typing mock data.

**Requirements Covered:** FR-5, UX-DR3

**Acceptance Criteria:**
- **Given** a user opens the Virtual Bag screen,
- **When** no racquets exist,
- **Then** an empty state appears with `[+ Add Racquet]` and a prominent `[⚡ Load Sample Bag]` button,
- **And** tapping `[⚡ Load Sample Bag]` seeds 3 realistic racquets (Wilson Blade @ 76% green, Babolat Pure Drive @ 58% amber, Head Radical @ 34% red) via Serverpod,
- **And** on mobile (<600dp) racquets display as a single-column card list with a bottom navigation bar, while on tablet/desktop (>600dp) they display in an adaptive 2-column grid.

---

## Epic 1.5: DevOps — Multi-Package CI/CD Pipeline Automation

Ensure full CI/CD quality gate enforcement across the entire Dart workspace, preventing client, server, or frontend regressions as Epics 2 through 5 are developed.

### Story 1.5.1: Multi-Package Linting & Workspace Formatting in GitHub Actions

As a DevOps engineer and developer,  
I want GitHub Actions to run format checks and static analysis across all workspace packages,  
So that stylistic inconsistencies and compiler warnings are caught immediately in CI before merge.

**Requirements Covered:** TEST-1, ARCH-1

**Acceptance Criteria:**
- **Given** `.github/workflows/format.yml`,
- **When** triggered on push or PR to `main`,
- **Then** `dart format --set-exit-if-changed .` runs across the entire repository root workspace (verifying server, client, and flutter code).
- **Given** `.github/workflows/analyze.yml`,
- **When** triggered on push or PR to `main`,
- **Then** dependencies are resolved via `flutter pub get` in the root workspace,
- **And** static analysis runs with fatal infos across `string_theory_server`, `string_theory_client`, and `string_theory_flutter` (`flutter analyze --fatal-infos` or matrix analysis),
- **And** any analysis warning or unformatted code fails the workflow.

### Story 1.5.2: Multi-Package Automated Test Runner in GitHub Actions

As a DevOps engineer and developer,  
I want `.github/workflows/tests.yml` to run tests for both the Serverpod backend and Flutter client,  
So that regressions in server endpoints, embedded PostgreSQL persistence, BLoC state logic, or widget rendering fail fast in CI.

**Requirements Covered:** TEST-1, ARCH-1

**Acceptance Criteria:**
- **Given** `.github/workflows/tests.yml`,
- **When** triggered on push or PR to `main`,
- **Then** Job 1 installs dependencies, runs Serverpod code generation check, and executes embedded PostgreSQL backend tests (`cd string_theory_server && dart test`),
- **And** Job 2 executes Flutter unit and widget tests (`cd string_theory_flutter && flutter test`),
- **And** failure in either backend or frontend test suites halts the pipeline and blocks PR merge.

---

## Epic 2: Dynamic Health Score, Composite Decay & On-Demand FutureCall Trigger

Players see a real-time, scientifically grounded Health Score (0-100%) for every racquet, visualized via a glowing 60fps radial ring gauge with secondary tension loss text and color-coded status tiers, supported by a daily Serverpod FutureCall background decay scheduler and an on-demand trigger for judges.

### Story 2.1: Pure Dart DecayEngine Domain Calculation & Unit Tests

As a developer and tennis player,  
I want a deterministic, shared `DecayEngine` calculation class,  
So that health decay and tension loss estimates are computed identically across client and server with 100% test coverage.

**Requirements Covered:** FR-8, FR-9, ARCH-2

**Acceptance Criteria:**
- **Given** string parameters (hours played, max rated hours, stringing date, string material category),
- **When** `DecayEngine.calculateHealth(...)` executes,
- **Then** it returns an integer `HealthScore` ($0–100\%$) based on:
  - $\text{DynamicPenalty} = (\text{hoursPlayed} / \text{maxRatedHours}) \times 70$
  - $\text{CalendarPenalty} = (\text{daysElapsed} / \text{shelfLife}) \times 30$
  - Where shelf life is: 75 days (Co-Poly), 180 days (Multifilament/Synthetic), 365 days (Natural Gut),
- **And** it calculates secondary tension loss text (e.g. `~1.5 kg / ~3.3 lbs drop`),
- **And** unit tests verify boundary cases (0 hours, max hours, 400 days elapsed, negative clamps) with 100% pass rate.

### Story 2.2: Animated Radial Health Gauge Widget & Racquet Card Integration

As a tennis player,  
I want a glowing, color-coded circular health gauge on each racquet card,  
So that I can assess my stringbed's elasticity at a glance in under 1 second.

**Requirements Covered:** FR-9, UX-DR2, NFR-1

**Acceptance Criteria:**
- **Given** a racquet card rendering in the Virtual Bag,
- **When** the health score changes or card loads,
- **Then** a circular radial ring gauge smoothly animates to the score at 60 fps,
- **And** the ring glows Green (`#10B981`) for $\ge 70\%$, Amber (`#F59E0B`) for $40–69\%$, and Red (`#EF4444`) for $<40\%$,
- **And** the center displays the bold percentage in Barlow Condensed with secondary tension loss helper text below,
- **And** racquets with $<40\%$ health display a cautionary badge: *"Dead Stringbed — High Shock Risk"*.

### Story 2.3: Serverpod DailyDecayFutureCall & On-Demand Test Trigger

As a system maintainer and hackathon judge,  
I want Serverpod to calculate static tension relaxation daily and offer an on-demand test trigger,  
So that strings decay realistically in the background and judges can observe the worker executing live.

**Requirements Covered:** FR-10, NFR-8

**Acceptance Criteria:**
- **Given** a Serverpod `DailyDecayFutureCall` registered in `server.dart`,
- **When** scheduled to run nightly at 00:00 UTC,
- **Then** it scans active `StringJob` records, recalculates calendar penalty via `DecayEngine`, and updates the database,
- **And** `BagEndpoint.triggerDailyDecayNow(session)` is exposed as an RPC endpoint,
- **And** tapping a dev button `[⚡ Trigger FutureCall Decay]` in the app executes the worker immediately and logs execution to the console.

### Story 2.4: Time-Warp Aging Simulator (+30 Days Dev Control)

As a hackathon judge or tester,  
I want to fast-forward a racquet's age by 30 days with a single tap,  
So that I can witness the health score drop and warning threshold transitions without waiting weeks.

**Requirements Covered:** FR-19

**Acceptance Criteria:**
- **Given** a racquet detail screen or dev controls panel,
- **When** the user taps `[⏩ Fast-Forward 30 Days]`,
- **Then** the Serverpod backend shifts the active `StringJob.stringingDate` 30 days into the past,
- **And** the health score immediately recalculates, visibly shifting the radial gauge and triggering the warning state if dropping below 40%.

---

## Epic 3: Effortless Match Logging, Real-Time Sync & In-App Workout Generator

Players capture court playtime in under 10 seconds through automated Apple Health / Health Connect tennis workout detection (with a 1-tap assignment sheet and progressive disclosure accordion), a rapid 3-tap manual logger, and an in-app mock workout simulator, with instant multi-device sync over Serverpod WebSockets.

### Story 3.1: Serverpod SessionLog Schema, SessionEndpoint & Idempotency

As a developer and tennis player,  
I want Serverpod to store session logs with unique external workout IDs,  
So that tennis play hours increment the racquet's active string job accurately with zero risk of duplicate counts.

**Requirements Covered:** FR-12, FR-13, ARCH-3, NFR-8

**Acceptance Criteria:**
- **Given** Serverpod model `SessionLog` with `userId: int`, `racquetId: int`, and unique index on `externalWorkoutId`,
- **When** `SessionEndpoint.logSession(session, log)` is called,
- **Then** the session is inserted into `session_log`,
- **And** the racquet's active `StringJob.totalCourtHours` is incremented by the session duration,
- **And** `DecayEngine` recalculates `StringJob.currentHealthScore`,
- **And** calling `logSession` with the same `externalWorkoutId` acts idempotently without double-counting hours.

### Story 3.2: Serverpod Real-Time WebSocket Streaming & BagStreamMessage

As a tennis player with multiple devices (or a hackathon judge),  
I want changes to reflect immediately across all open screens via WebSockets,  
So that I see live gauge animations without pulling to refresh.

**Requirements Covered:** FR-14, NFR-2, ARCH-4

**Acceptance Criteria:**
- **Given** a Serverpod streaming channel `user_{userId}_bag`,
- **When** a session is logged or gear is restrung,
- **Then** Serverpod broadcasts a `BagStreamMessage(eventType, racquetId, healthScore)` over WebSockets,
- **And** connected Flutter clients receive the event in $<300\text{ ms}$,
- **And** `BagBloc` updates state and animates the corresponding racquet gauge without full page reload.

### Story 3.3: HealthSyncService Strategy Pattern & Judge Simulation Generator

As a hackathon judge or mobile player,  
I want an abstracted health sync service with an instant `[🧪 Simulate Workout]` button,  
So that judges can test on web/desktop without a physical smartwatch, while mobile users can sync Apple Health.

**Requirements Covered:** FR-11, FR-18, ARCH-5

**Acceptance Criteria:**
- **Given** the abstract `HealthSyncService` interface,
- **When** running on iOS/Android, it binds `NativeHealthSyncService` querying completed tennis workouts from HealthKit / Health Connect,
- **And** when running on Web or Desktop, it binds `SimulatedHealthSyncService`,
- **And** tapping a floating badge `[🧪 Simulate Workout]` triggers a simulated 90-minute tennis workout event immediately,
- **And** the app compiles and runs on Flutter Web with zero platform plugin crashes.

### Story 3.4: Progressive Disclosure Workout Assignment Sheet & 3-Tap Quick Logger

As a tennis player walking off the court,  
I want a 1-tap gear selector with an expandable "Advanced options" accordion,  
So that common logging takes under 3 seconds while letting me customize surface and split time when needed.

**Requirements Covered:** FR-12, FR-13, UX-DR4

**Acceptance Criteria:**
- **Given** a detected or simulated tennis workout,
- **When** the bottom sheet opens,
- **Then** the primary racquet is pre-selected and tapping `[Confirm]` logs the session in $\le 2$ taps,
- **And** tapping `[+ Advanced Options]` expands an accordion revealing court surface chips (`Hard`, `Clay`, `Grass`) and session notes,
- **And** tapping the FAB `[+ Log Session]` opens a quick logger with duration chips (`30m`, `1h`, `1.5h`, `2h`) that saves in $<10$ seconds.

### Story 3.5: Offline Session Queue with Auto-Reconnection Sync

As a player on a court without cellular reception,  
I want to log matches offline and have them sync automatically later,  
So that I never lose workout logs due to bad network connectivity.

**Requirements Covered:** NFR-4

**Acceptance Criteria:**
- **Given** the device has no internet connection,
- **When** a session is logged,
- **Then** the session is stored in a local device queue and the UI applies optimistic gauge decay immediately,
- **And** when connectivity is restored, the queue automatically posts pending sessions to Serverpod and reconciles the state.

---

## Epic 4: Restringing Lifecycle & Historical Timeline

When strings go dead (<40%), players receive clear in-app alerts and can execute a 1-tap "Restrung Today" action ([Keep Same & Reset] vs [Change Specs]), instantly resetting their gauge to 100% and archiving past stringbeds into an interactive performance history timeline.

### Story 4.1: Serverpod RestringEvent Schema & Transactional Restring Endpoint

As a developer and tennis player,  
I want restringing operations to execute atomically within a database transaction,  
So that retired strings are preserved permanently in history without the risk of orphaned or corrupted racquets.

**Requirements Covered:** FR-15, FR-16, NFR-5, ARCH-3

**Acceptance Criteria:**
- **Given** Serverpod model `RestringEvent` with `userId: int`, `racquetId: int`, `stringJobId: int`, `finalCourtHours`, and `finalDaysActive`,
- **When** `BagEndpoint.restringRacquet(session, racquetId, newSpecs, keepSame)` executes,
- **Then** within a single Serverpod database transaction:
  - The active `StringJob.isActive` is set to `false`,
  - A `RestringEvent` snapshot is inserted with final hours and active days,
  - A new `StringJob` is inserted with `totalCourtHours = 0`, `currentHealthScore = 100`, and `isActive = true`,
- **And** if any database step fails, the entire transaction rolls back cleanly (NFR-5).

### Story 4.2: "Restrung Today" 2-Option Decision Sheet & Toast Confirmation

As a tennis player getting fresh strings,  
I want to reset my racquet in 1 tap if I kept the same strings, or update specs if I switched string models,  
So that resetting my equipment is instant and celebrates my fresh stringbed.

**Requirements Covered:** FR-15, UX-DR5

**Acceptance Criteria:**
- **Given** a user taps `[Restrung Today]` on any racquet card,
- **When** the sheet opens,
- **Then** it presents two clear options:
  - `[Keep Same & Reset]`: 1-tap action that resets the gauge to 100% today using previous specs,
  - `[Change Specs]`: Accordion expanding fields for string brand, model, tension, and material category,
- **And** submitting dispatches `RestringRacquet` to `BagBloc`,
- **And** a celebratory green toast notification displays: *"Fresh stringbed mounted! Restrung to 100% health."*

### Story 4.3: Racquet Detail Screen & Restring History Timeline UI

As a tennis player,  
I want to see my racquet's full history of string setups,  
So that I can track how many hours different strings lasted and find my optimal setup.

**Requirements Covered:** FR-17, UX-DR1

**Acceptance Criteria:**
- **Given** a user navigates into a Racquet Detail screen,
- **When** viewing the "History" tab,
- **Then** it renders a chronological timeline of past string jobs (e.g. *"Aug 10 – Oct 2 • Babolat RPM Blast 1.25 • 18.5 court hours • 53 days active"*),
- **And** each past stringbed displays its retired health score and installed tension.

---

## Epic 5: Hackathon Polish, Multi-Platform Adaptations & Judge Showcase Controls

Hackathon judges and web testers can evaluate the complete system across mobile, tablet, and desktop/web with responsive layouts (NavigationRail on tablet/web), keyboard shortcuts (L, N, S, Esc), and unified demo controls.

### Story 5.1: Multi-Platform Responsive Layout (NavigationRail & Desktop Grid)

As a hackathon judge evaluating on desktop web or iPad,  
I want the layout to adapt smoothly from mobile bottom bars to side navigation and multi-column grids,  
So that the application looks like a first-class native desktop/web experience.

**Requirements Covered:** UX-DR3, NFR-1

**Acceptance Criteria:**
- **Given** the app running in a browser or desktop window,
- **When** window width is $<600\text{dp}$,
- **Then** it renders a touch-friendly bottom navigation bar and single-column cards,
- **And** when window width is between $600\text{dp}$ and $1024\text{dp}$, it transforms into a side `NavigationRail` with a 2-column card grid,
- **And** when window width is $>1024\text{dp}$, it displays an expanded navigation drawer and a 3-column card grid.

### Story 5.2: Keyboard Shortcuts & Desktop Mouse Hover States

As a web or desktop user,  
I want keyboard accelerators and responsive hover micro-interactions,  
So that navigating the app with mouse and keyboard is effortless.

**Requirements Covered:** UX-DR6

**Acceptance Criteria:**
- **Given** the app running on web or desktop,
- **When** the player hovers the cursor over a racquet card,
- **Then** the card elevates slightly and the border glow brightens,
- **And** pressing `L` opens the Quick Logger,
- **And** pressing `N` opens the Add Racquet modal,
- **And** pressing `S` triggers the workout simulator,
- **And** pressing `Esc` closes any open dialog or sheet.

### Story 5.3: End-to-End Demo Script & Verification Walkthrough

As a hackathon presenter and developer,  
I want an end-to-end automated verification test and demo sequence,  
So that the judge walkthrough is 100% stable, repeatable, and completes in under 90 seconds.

**Requirements Covered:** SM-3, NFR-3

**Acceptance Criteria:**
- **Given** a fresh browser session,
- **When** following the demo path:
  1. Guest Auth initializes seamlessly,
  2. Tap `[⚡ Load Sample Bag]`,
  3. Tap `[🧪 Simulate Workout]` (90m match assigned to Wilson Blade),
  4. Wilson Blade gauge visibly drops from 76% to 67% over WebSockets,
  5. Tap `[Restrung Today]` on Head Radical (34% red) $\rightarrow$ resets to 100% green and archives to timeline,
- **Then** the entire sequence executes without errors in $<90$ seconds,
- **And** `dart analyze` and `dart test` pass with 0 errors across server and client.

### Story 5.4: Patrol Headless End-to-End Test Automation in CI

As a DevOps engineer and QA developer,  
I want automated Patrol integration tests running in CI,  
So that end-to-end user flows, native dialogs, and simulated workouts are verified on automated builds.

**Requirements Covered:** TEST-2, NFR-8

**Acceptance Criteria:**
- **Given** a commit or pull request targeting the `main` branch,
- **When** GitHub Actions executes the E2E verification stage,
- **Then** the Patrol E2E test suite runs headlessly against the Flutter client,
- **And** it verifies the critical path (guest onboarding, virtual bag rendering, and sample workout simulation),
- **And** any failure in the Patrol integration run blocks PR merge.

---

## Epic 6: Technical Debt, Concurrency & Production Polish

The system eliminates pre-release technical debt and concurrency vulnerabilities: aligns native UUID tenant identifiers across all Serverpod models and endpoints, secures daily decay background workers with PostgreSQL advisory locks and optimistic score writes, broadcasts live WebSocket health decay updates, decouples BLoC mutation errors from background reloads, hardens health workout queueing and lifecycle sync, delivers a dedicated Sessions history screen, adds real email sign-in with guest-account linking so the app can be tested across windows and accounts, and establishes CI parity and deterministic authentication tests.

### Story 6.1: State Management Resilience (Mutation Refresh Decoupling, Async Pull-to-Refresh & Auth 401 Routing)

As a tennis player,  
I want racquets added, deleted, made primary, or aged without false error SnackBars when network reloads fluctuate, and pull-to-refresh to wait for the latest bag data,  
So that I have total confidence in my virtual gear bag's state and interactions.

**Requirements Covered:** TD-1, TD-2, TD-3

**Acceptance Criteria:**
- **Given** the player performs `AddRacquet`, `DeleteRacquet`, `SetPrimaryRacquet`, or `FastForwardRacquetAge`,
- **When** the backend mutation RPC succeeds but the subsequent `getVirtualBag` reload fails or times out,
- **Then** `BagBloc` does NOT emit an error SnackBar claiming the operation failed; it retains the updated state and schedules a background re-sync,
- **And** when the player pulls to refresh on `VirtualBagScreen`, `RefreshIndicator.onRefresh` awaits the asynchronous emission of `BagLoaded` or `BagError` (with an 8-second safety timeout) before dismissing the spinner,
- **And** when `logSession` encounters an HTTP 401 Unauthorized, `BagBloc` treats it as permanent authentication expiry, prompts re-authentication immediately, and does NOT queue the session with the "saved offline" toast.

### Story 6.2: Health Ingestion Hardening (Lifecycle Resumed Sync, Workout Arrival Queue & Permission Feedback)

As a tennis player with an Apple Watch or WearOS device,  
I want matches detected immediately when returning to the app without dropping multi-match batches,  
So that all on-court hours are captured effortlessly into my string decay tracking.

**Requirements Covered:** TD-4, TD-5, TD-6

**Acceptance Criteria:**
- **Given** `NativeHealthSyncService` attached to the virtual bag,
- **When** the application transitions from background to foreground (`AppLifecycleState.resumed`),
- **Then** workout sync executes automatically, provided at least 60 seconds have elapsed since the prior sync (cooldown gate),
- **And** `syncWorkouts()` enforces a 5-second timeout and guarantees `_isSyncing = false` in a `finally` block,
- **And** when multiple tennis sessions arrive in a single batch, or workouts arrive while an assignment sheet is active, `BagBloc` buffers them in a FIFO pending queue and presents each sequentially upon sheet completion or dismissal,
- **And** when Health Connect or HealthKit permissions are missing or denied, the UI surfaces clear informational guidance rather than a silent empty list,
- **And** processed or dismissed workout IDs are stored in persistent storage so app restarts do not re-alert on previously handled workouts.

### Story 6.3: Native UUID Tenant Migration, Backend Concurrency & Live Updates

As a backend engineer and system architect,  
I want clean UUID tenant identifiers, non-blocking advisory locking, and optimistic concurrency for decay updates,  
So that the database schema is production-ready, race conditions are eliminated, and live clients receive real-time decay broadcasts.

**Requirements Covered:** TD-7, TD-8, TD-9, TD-10

**Acceptance Criteria:**
- **Given** Serverpod models `Racquet`, `StringJob`, `SessionLog`, and `RestringEvent`,
- **When** the schema is migrated,
- **Then** all `userId` columns are typed as `UuidValue` with database indices,
- **And** `SessionLog` includes a composite unique index `(userId, externalWorkoutId)` isolating tenants,
- **And** `TenantResolver` returns `session.authenticated?.authUserId` directly without custom hash or modulus workarounds,
- **And** `DailyDecayService` acquires a non-blocking PostgreSQL advisory lock (`pg_try_advisory_lock(7421893)`); if busy, dev triggers return 409 and background cron exits gracefully,
- **And** decay batch updates execute optimistic conditional writes (`WHERE id = @jobId AND "totalCourtHours" = @readCourtHours`), skipping jobs concurrently updated by user sessions,
- **And** when stringbed health score changes by >= 1%, `DailyDecayService` publishes a `BagStreamMessage` to the user's stream channel,
- **And** `SessionEndpoint.logSession` validates `1 <= durationMinutes <= 360` and `startTime <= now() + 5 minutes`.

### Story 6.4: Dedicated Sessions History Screen & Domain Model Extraction

As a tennis player,  
I want a dedicated Sessions tab showing my full match and practice history with quick-logging shortcuts,  
So that I can review all logged court hours and gear usage in one organized view.

**Requirements Covered:** TD-11, TD-12

**Acceptance Criteria:**
- **Given** the app navigation (BottomNav, NavigationRail, and Drawer),
- **When** the player selects the "Sessions" tab,
- **Then** the app renders a dedicated `SessionsScreen` (replacing the temporary `SessionsPlaceholder`),
- **And** it displays a chronological list of logged sessions with date, duration, racquet name, and court hours added,
- **And** it provides a prominent `[+ Log Session]` action button,
- **And** `RacquetPreset` and `StringCategoryDefaults` are relocated from UI widgets into pure domain models in the domain layer, with presentation files referencing the domain contracts.

### Story 6.6: Real Email Sign-In for Multi-Window Testing

As a hackathon judge and tennis player,
I want to sign in with an email account (or continue as a guest), link my guest bag to an email later, and sign out for real,
So that I can open the same account in two windows and watch health scores sync live, and confirm a second account gets its own empty bag.

**Requirements Covered:** FR-2, FR-20, TD-15, TD-16

**Acceptance Criteria:**

*Sign-in screen & auth gate*
- **AC-1** — **Given** no stored session, **When** the app launches, **Then** it shows a sign-in screen in the Court Midnight theme with email/password sign-in and sign-up (Serverpod `EmailIdp` flow, including the verification-code step) and a prominent `[Continue as guest]` action; the bag is not shown until the user is authenticated.
- **AC-2** — **Given** a stored valid session, **When** the app launches, **Then** the sign-in screen is skipped and the Virtual Bag opens directly (NFR-3 unchanged).
- **AC-3** — **Given** `[Continue as guest]`, **When** tapped, **Then** an anonymous session is created exactly once (existing in-flight dedupe kept) and the bag opens; offline failure shows a retry message on the sign-in screen instead of the old post-launch SnackBar.
- **AC-4** — **Given** a fresh email sign-up, **When** the account is created, **Then** the user lands on an empty bag (no racquets from any other tenant).

*Sign-out*
- **AC-5** — **Given** any signed-in user (guest or email), **When** they confirm Sign Out in Settings, **Then** the device token is removed, the bag stream subscription is closed, the BagBloc state is cleared, and the app returns to the sign-in screen. The guest sign-out dialog warns that the guest bag becomes unreachable unless linked first. The "Re-authenticate Guest" action is removed.

*Guest → email linking (FR-2)*
- **AC-6** — **Given** a guest with a bag, **When** they tap `[Continue with Email]` in Settings and complete email sign-up or sign-in, **Then** the guest's `Racquet`, `StringJob`, `SessionLog` and `RestringEvent` rows are owned by the email account, and the bag shows the same racquets and health scores as before. Racquet IDs are unchanged, so queued offline sessions still apply.
- **AC-7** — **Given** the server, **When** linking runs, **Then** it goes through `AccountEndpoint.createGuestClaim()` (while authenticated as the guest) and `AccountEndpoint.claimGuestBag(secret)` (as the email user). Serverpod's `AccountMerger.merge` runs inside one transaction with an `applicationMergeHandler` registered in `initializeAuthServices`. The claim secret is single-use, stored hashed, expires after 15 minutes, and is valid only if its user is still anonymous-only. Reused, expired, foreign or unauthenticated claims are rejected with no rows changed.
- **AC-8** — **Given** the email account already has racquets, **When** a guest bag is merged in, **Then** guest racquets are appended, the email account's primary racquet is kept (guest `isPrimary` cleared), guest `SessionLog` rows conflicting on `(userId, externalWorkoutId)` are dropped, and a `BagStreamMessage` is published to the email user's channel so other open windows refresh.
- **AC-9** — **Given** Settings, **When** rendered, **Then** the "Continue with Google" option is gone; for an email user, Settings shows the account email instead of the guest banner and link option.

*Fresh-clone setup*
- **AC-10** — **Given** a fresh clone, **When** the developer runs `string_theory_server/tool/init_passwords.sh`, **Then** `config/passwords.yaml` is created with random `development` and `test` values for every key `server.dart` and `config/test.yaml` need (`database`, `serviceSecret`, `emailSecretHashPepper`, `jwtHmacSha512PrivateKey`, `jwtRefreshTokenHashPepper`), it refuses to overwrite an existing file, and `serverpod start` then boots. CI env vars in `tests.yml` are unchanged.

*Multi-window behavior*
- **AC-11** — **Given** web, **When** the app is opened in two tabs of the same browser profile, **Then** the story records (by running it, not assuming it) whether the tabs share one identity. If they do, signing out in one tab sends the other to the sign-in screen on its next authenticated call (401 path from 6.1), never to the offline queue. The README states the result and tells reviewers to use a private window or second browser profile for the second account.
- **AC-12** — **Given** one email account open in two windows, **When** a session is logged in window A, **Then** window B's gauge updates live without reload; **And** a second email account in a separate profile sees an empty bag and receives no updates from the first.

*Cleanup*
- **AC-13** — The unused template screens `sign_in_screen.dart` and `greetings_screen.dart` are replaced by the new sign-in screen or deleted. No dead auth UI remains.

**Tests (TDD, red first):**
- Server (`dart test`): `AccountEndpoint` tests for successful merge of all four tables, single use, expiry, foreign or non-anonymous claim rejection, unauthenticated rejection, unique-index conflict drop, primary-racquet conflict, `BagStreamMessage` published to the keeper's channel only, and rollback leaving rows untouched on failure.
- Flutter unit/BLoC: `AuthService` (no automatic guest at `initialize`, `continueAsGuest`, `signOut` clears state, the linking sequence calls claim before and after the identity switch), and clearing BagBloc on sign-out.
- Flutter widget: auth gate (no token → sign-in screen, token → bag), sign-in screen guest path and email path entry, Settings (no Google option, email button starts the linking flow, the email user sees their email).
- Patrol E2E: update the existing suite to tap `[Continue as guest]`; add a guest → email linking happy path if the embedded server setup allows it, otherwise cover it with widget tests and note why.

**Definition of Done:**
- All ACs met, all tests green locally and in CI, `dart analyze` and `dart format` clean, migration created and applied through MCP.
- **README "Test it (for reviewers)"** rewritten from what shipped (the "🚧 Coming in Story 6.6" note removed). It covers: (1) sign up with an email and get the verification code from the `serverpod start` output; (2) open the same account in a second window and watch a logged session update both; (3) sign in with a second email in a private window or second profile and confirm the bag is empty; (4) the AC-11 tab-sharing result.
- **README "Start"** replaces the hand-written passwords note with `tool/init_passwords.sh`.
- **DEMO_SCRIPT refresh:** Step 1 shows the sign-in screen and `[Continue as guest]`; a Sessions history beat is added (Story 6.4); a live two-window sync beat is added (Stories 3.2 and 6.3); timings still fit about 90 seconds or the header is honestly updated.
- README and DEMO_SCRIPT checked and updated where affected, describing only behavior verified on `main`.

### Story 6.5: CI Environment Parity & Deterministic Auth Testing

As a developer and CI engineer,  
I want CI workflows to run with consistent auth environment configurations and deterministic unit tests,  
So that pull requests are verified without flakiness or network timeouts.

**Requirements Covered:** TD-13, TD-14

**Acceptance Criteria:**
- **Given** GitHub Actions workflow definitions,
- **When** automated test steps execute across `string_theory_server` and `string_theory_flutter`,
- **Then** Serverpod auth secrets and IDP password environment variables match consistently across test matrices,
- **And** `git diff --exit-code` checks are scoped to individual package directories to prevent spurious drift alerts,
- **And** `auth_service_test.dart` introduces a fake/mock `serverpod_auth_core` status caller,
- **And** both valid-session and guest fallback branches are verified deterministically without awaiting live socket timeouts.

