# Epic 1 Context: Zero-Friction Onboarding, Pre-Seeded Demo Bag & Racquet Setup

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Provide immediate user access upon launch via anonymous guest authentication, set up the multi-tenant core data models (Racquet and StringJob) in Serverpod, establish the Flutter reactive foundation (Court Midnight theme tokens and BagBloc), and deliver a responsive Virtual Bag screen with an instant sample bag seeder so judges and players can test without manual setup.

## Stories

- Story 1.1: Anonymous Guest Authentication & Token Rehydration
- Story 1.2: Serverpod Racquet & StringJob Schema & BagEndpoint
- Story 1.3: Court Midnight Theme & BagBloc Reactive State Foundation
- Story 1.4: Add Racquet Form with String Category Smart Defaults & Presets
- Story 1.5: Virtual Bag Responsive Screen & Instant Demo Bag Seeder

## Requirements & Constraints

- First app launch must automatically provision an anonymous authenticated session without blocking login screens or OAuth gates.
- Auth token must be stored securely across relaunches using flutter_secure_storage (iOS Keychain, Android Keystore, web secure storage).
- Guest accounts can later be linked with email/password or Google identity in settings without data loss.
- Core Serverpod models (`Racquet`, `StringJob`) must be multi-tenant, explicitly indexed by `userId: int`, and queried strictly via authenticated session (`session.authenticated`).
- Racquet setup must support string material categories (`Poly / Co-Poly`, `Multifilament`, `Synthetic Gut`, `Natural Gut`, `Kevlar / Aramid`, `Hybrid`) with smart defaults for installed tension and recommended lifespan.
- Virtual Bag must provide an accessible one-tap `[⚡ Load Sample Bag]` button to populate 3 pre-configured racquets (Fresh, Playing, Dead) for instant testing and evaluation.

## Technical Decisions

- Serverpod 4.0.3 built-in auth (`serverpod_auth`) manages user IDs and tokens.
- Frontend uses `flutter_bloc` with `bloc_test` for reactive state, dependency injection, and clean separation between UI and Serverpod client calls.
- Pure Dart `DecayEngine` shared logic will calculate initial string health values for display.
- Database models defined in `.spy.yaml` schemas under `string_theory_server/lib/src/models/`. Never edit generated code in client or server. Migrations created via Serverpod MCP tools.
- TDD invariants: Red-Green-Refactor with unit/BLoC/endpoint tests created first.

## UX & Interaction Patterns

- **Court Midnight Theme**: Dark graphite canvas (`#121516`), card surfaces (`#1A1E20`), border accents (`#2A3034`), electric tennis volt highlight (`#C6F10E`), alert red (`#FF453A`), alert amber (`#FF9F0A`).
- **Typography**: Barlow Condensed for high-impact metric headers and frame nicknames; Inter for legible specs and body copy.
- **Responsive Layout**: Mobile uses bottom navigation bar + 1-column card stack; Tablet uses NavigationRail + 2-column grid; Desktop uses multi-column grid.

## Cross-Story Dependencies

- Story 1.1 establishes the authenticated `SessionManager` that all subsequent stories (Story 1.2+ endpoints) depend on for `userId`.
- Story 1.2 establishes the Serverpod data models and client SDK consumed by Story 1.3 (BagBloc) and Story 1.4 (Add Racquet form).
- Story 1.3 theme and BLoC foundations feed into Story 1.4 form UI and Story 1.5 Virtual Bag screen.
