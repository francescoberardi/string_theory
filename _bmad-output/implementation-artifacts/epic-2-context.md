# Epic 2 Context: Dynamic Health Score, Composite Decay & On-Demand FutureCall Trigger

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Provide players and judges with real-time, scientifically grounded tennis string elasticity and tension decay tracking (0–100% Health Score). Calculates decay deterministically using a composite algorithm (70% court playtime hours + 30% static calendar shelf-life relaxation), visualizes string health via an animated 60fps glowing radial gauge with status tiers and tension drop text, and schedules automated daily backend decay via Serverpod FutureCalls with an on-demand trigger and aging simulator for judges.

## Stories

- Story 2.1: Pure Dart DecayEngine Domain Calculation & Unit Tests
- Story 2.2: Animated Radial Health Gauge Widget & Racquet Card Integration
- Story 2.3: Serverpod DailyDecayFutureCall & On-Demand Test Trigger
- Story 2.4: Time-Warp Aging Simulator (+30 Days Dev Control)

## Requirements & Constraints

- Deterministic composite decay formula:
  - $\text{DynamicPenalty} = (\text{hoursPlayed} / \text{maxRatedHours}) \times 70$
  - $\text{CalendarPenalty} = (\text{daysElapsed} / \text{shelfLife}) \times 30$
  - $\text{HealthScore} = \text{clamp}(100 - (\text{DynamicPenalty} + \text{CalendarPenalty}), 0, 100)$
- String category shelf life:
  - `coPoly`: 75 days
  - `multifilament` & `syntheticGut`: 180 days
  - `naturalGut`: 365 days
  - `hybrid`, `kevlar`, `other`: 120–180 days
- Secondary tension loss estimate displayed in both kg and lbs (e.g. `~1.5 kg / ~3.3 lbs drop`).
- Health status tiers:
  - Green ($\ge 70\%$): Healthy elastic pocketing
  - Amber ($40–69\%$): Moderate decay / tension drop
  - Red ($<40\%$): Dead stringbed / High arm shock risk banner
- Backend calculates static relaxation nightly at 00:00 UTC via Serverpod `DailyDecayFutureCall`, updating `StringJob.currentHealthScore`.
- Developer/judge demo controls:
  - `[⚡ Trigger FutureCall Decay]`: Runs backend daily decay worker on demand via RPC.
  - `[⏩ Fast-Forward 30 Days]`: Rewinds stringing date by 30 days to immediately demo decay.

## Technical Decisions

- **AD-1 (Shared Pure Domain Decay Engine):** Pure Dart `DecayEngine` calculates scores identically on Flutter client (optimistic 60fps animations) and Serverpod backend (authoritative persistence & daily FutureCall).
- **DecayEngine Architecture:** No external platform or Flutter-specific dependencies in core domain math; accepts `hoursPlayed`, `maxRatedHours`, `stringingDate`, `materialCategory`, and optional `now` DateTime for deterministic testability.
- **Serverpod FutureCalls:** Registered in `server.dart`, executed by Serverpod's built-in scheduler, transactional updates across active `StringJob` records.
- **TDD Requirement:** 100% test pass rate on unit boundary tests (0h, max hours, excessive aging, negative clamps) and widget tests.

## UX & Interaction Patterns

- **Radial Ring Gauge:** Custom painter or animated sweep gradient glowing Green (`#10B981`), Amber (`#F59E0B`), or Red (`#EF4444`).
- **Typography:** Barlow Condensed bold percentage in center, secondary tension loss helper text below.
- **Alert State:** Dead stringbed banner displays when health $<40\%$: *"Dead Stringbed — High Shock Risk"*.
- **Optimistic UI:** Gauge responds instantly to simulated matches or dev triggers without waiting for network round-trips.

## Cross-Story Dependencies

- Story 2.1 (`DecayEngine`) is the domain foundation required by Story 2.2 (Radial Health Gauge UI), Story 2.3 (`DailyDecayFutureCall`), Story 2.4 (Aging Simulator), and later Epic 3 (Match Logging).
- Story 2.2 consumes `DecayEngine` output to render the animated gauge on `RacquetCard`.
- Story 2.3 and 2.4 use `DecayEngine` on the server to recalculate health scores in PostgreSQL.
