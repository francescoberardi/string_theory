# String Theory — Tennis String Decay & Health Tracker

String Theory is a tennis equipment decay and stringbed health monitoring app designed for the Serverpod Hackathon ("Build Something Real").
It combines a Flutter frontend (mobile, tablet, web) with a Serverpod 4.0.3 backend (PostgreSQL ORM, WebSocket streams, scheduled FutureCalls, built-in auth).

## Core Domain & Architecture
- **Problem**: Co-poly tennis strings lose elasticity and tension quickly through court impact hours and static calendar relaxation in the bag. Dead stringbeds lose pocketing and shock absorption, transferring harsh vibrations directly into the player's arm, causing lateral epicondylitis ("tennis elbow").
- **Solution**: Virtual gear bag tracking multiple racquets with dynamic Health Scores (0-100%, Green >=70%, Amber 40-69%, Red <40%), composite decay calculations (70% court hours + 30% calendar shelf-life), automated Apple Health / Health Connect workout ingestion (<3s gear assignment), real-time WebSocket updates, and 1-tap "Restrung Today" resets.
- **Shared Domain**: Pure Dart `DecayEngine` calculates scores identically on frontend (optimistic UI) and backend (authoritative persistence & daily cron).
- **Multi-Tenant**: All core tables (`Racquet`, `StringJob`, `SessionLog`, `RestringEvent`) are scoped by `userId: int` using Serverpod's built-in authentication.

## Git Workflow & Repository Rules
1. **Trunk-Based Development**:
   - The `main` branch is the single source of truth and must remain deployable and green at all times.
   - Work directly on `main` via small, frequent, atomic commits or short-lived story branches (< 1 day lifespan).
2. **Rebase Over Merge (Zero Merge Commits)**:
   - NEVER create merge commits. Merges with `--no-ff` or standard branch merges that generate merge commits are strictly prohibited.
   - Always rebase when updating from upstream: `git pull --rebase origin main` and `git rebase main`.
   - Maintain a clean, strictly linear commit history.
3. **Conventional Commits**:
   - Every commit message MUST follow the Conventional Commits specification: `<type>(<scope>): <description>`
   - **Allowed Types**:
     - `feat`: A new feature for the user
     - `fix`: A bug fix
     - `test`: Adding missing tests or correcting existing tests (TDD red/green steps)
     - `refactor`: Code changes that neither fix a bug nor add a feature
     - `chore`: Build tasks, config changes, dependency bumps, or tooling
     - `ci`: CI configuration changes (e.g. GitHub Actions workflows)
     - `docs`: Documentation updates only
     - `perf`: Code changes improving performance
   - **Common Scopes**: `server`, `flutter`, `client`, `decay`, `health`, `auth`, `bag`, `session`, `restring`, `ci`
   - **Format Rules**: Use imperative, present tense ("add", not "added" or "adds"). Lowercase summary, no trailing period.
4. **TDD Protocol (Test-Driven Development)**:
   - Follow strict Red-Green-Refactor cycle.
   - Write failing unit, BLoC, or endpoint tests FIRST. Commit or verify red state (`test(...)`), then write minimal implementation code to turn green (`feat(...)`), followed by refactoring (`refactor(...)`).
   - Use Patrol (`patrol`, `patrol_finders`) for integration/E2E testing.

## Serverpod & MCP Instructions

The user starts the server and Flutter app with `serverpod start`. There is no need to check if the server is running: make the changes and call the `serverpod` MCP tools as needed. If the server is not running, an informative error message will be received from the MCP server. Then STOP and ask the user to start it. NEVER start the server yourself. The Flutter app is started along with it, or can be launched from the MCP tool `spawn_flutter_app`.

While running, `serverpod start` watches for file changes to run incremental code generation and hot reload both the server and the Flutter app.

Calling `serverpod generate` directly is not needed, but might be useful to troubleshoot when an incremental generation fails.

ALWAYS use the MCP server instead of the command line. Use the MCP server to:

- `create_migration` and `apply_migrations` for database (after you change data models).
- `create_repair_migration` if the database has drifted out of sync with the migrations.
- `tail_server_logs` to read logs from the server.
- `tail_flutter_logs` to read the raw stdout/stderr of the Flutter app.
- `hot_reload` / `hot_restart` to reload or restart the server and the Flutter app. ALWAYS call `hot_restart` after doing changes in the Flutter app that may not work with normal hot reload (which is automatically applied).
- `spawn_flutter_app` to start a Flutter app declared under `serverpod: flutter_apps:` in the server `pubspec.yaml`.
- `get_flutter_app_dtd` (Dart tooling daemon) for connecting to the app through the `dart` MCP.

NEVER edit generated code. The server's `lib/src/generated/` directory and the whole `string_theory_client` package are rewritten by the code generator. Change the `.spy.yaml` models, the endpoints, or `lib/server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Only when the server cannot be started at all, fall back to the CLI in the server package:

- `serverpod generate` to regenerate the client and the generated server code.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). It only writes the migration; `serverpod start` applies pending migrations when it boots the server.

Tests need no Docker. `config/test.yaml` sets `database.dataPath`, so Serverpod starts and manages the test database (an embedded PostgreSQL) itself, and the project's `docker-compose.yaml` is not used for it. Just run `dart test` in the server package.

## Checklist After Changes
Checklist after doing changes, in this order:

1. `dart analyze` (CLI)
2. `dart format` (CLI)
3. `create_migration` and `apply_migrations` (MCP - only if necessary)
4. Do `serverpod` MCP `hot_restart` if required (hot reload is done automatically). Will also hot restart Flutter app
5. Run tests, if applicable (`dart test` in the server package)
6. Check `serverpod` MCP `tail_server_logs` and `tail_flutter_logs` for any issues.

If the user asks you to test the app:

1. Use `get_flutter_app_dtd` (`serverpod` MCP) to get the Flutter app's DTD
2. Pass the DTD to `connect_dart_tooling_daemon` (`dart` MCP) to connect to the app
3. Use `flutter_driver` (`dart` MCP) to navigate through the app

The app is launched from `string_theory_flutter/lib/driver.dart`, which starts the Flutter driver extension with text entry emulation turned off so the app stays usable by hand. To let the driver type, set `enableTextEntryEmulation: true` there and `hot_restart` the app.
