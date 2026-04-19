# Development Journal

## 2026-03-21 - Iteration 1 (MVP foundation)

### Scope delivered
- Created Flutter project skeleton files: `pubspec.yaml`, `analysis_options.yaml`, `lib/main.dart`.
- Added app bootstrap: theme + router + shared scaffold/navigation.
- Implemented `flight_planning` module with layered structure:
  - `domain`: `Waypoint`, `Leg`, `RoutePlan`, `RouteCalculationService`
  - `application`: use cases + Riverpod controller/providers
  - `data`: local datasource (in-memory), models, repository implementation
  - `presentation`: route planning screen, waypoint form/list, summary card
- Added `map_view` placeholders with route preview painter.
- Added `route_storage` screen and providers for listing/deleting saved routes.
- Added `navigation` skeleton (entities/services/controller + fake GPS datasource).
- Added `settings` screen placeholder.
- Added first unit tests for geo utils and route calculation service.

### Decisions
- Local persistence is implemented as in-memory store for now.
- SQLite/Drift files were prepared as placeholders to avoid over-engineering early.
- Map rendering is a temporary preview (custom painter), not MapLibre/Mapbox yet.

### Constraints
- Flutter/Dart SDK was not available in local PATH during this iteration.
- Because of that, tests and formatting could not be executed yet.

### Next step recommendation
- Install Flutter SDK and run:
  - `flutter pub get`
  - `flutter test`
  - `flutter run`
- Replace in-memory datasource with Drift/SQLite integration.

## 2026-03-22 - Iteration 2 (verification + analyzer cleanup)

### Scope delivered
- Verified local toolchain: `Flutter 3.41.5` / `Dart 3.11.3`.
- Executed test suite with `flutter test` (all tests passing).
- Executed static analysis with `flutter analyze`.
- Fixed analyzer issues:
  - removed unused import in `flight_planning_screen.dart`,
  - replaced deprecated `DropdownButtonFormField.value` with `initialValue`,
  - removed unnecessary cast in `navigation_controller.dart`.

### Current status
- Project is in green baseline for existing unit tests.
- Static analyzer reports no warnings/errors after cleanup.

### Next step recommendation
- Implement real local persistence with Drift/SQLite (replace in-memory datasource).

## 2026-03-22 - Iteration 3 (SQLite persistence)

### Scope delivered
- Replaced in-memory route datasource with SQLite-backed implementation.
- Implemented `AppDatabase` lifecycle and schema bootstrapping (`routes`, `waypoints`, `legs`).
- Added table SQL definitions and indexes for route-linked records.
- Wired database into Riverpod providers (`appDatabaseProvider` + datasource injection).
- Added dedicated datasource tests for:
  - save + read route with legs/waypoints,
  - ordering by `updatedAt` descending,
  - delete route.
- Added dependencies:
  - runtime: `sqflite`, `path`,
  - tests: `sqflite_common_ffi`.

### Verification
- `flutter test` -> all tests passed (including new datasource tests).
- `flutter analyze` -> no issues found.

### Next step recommendation
- Replace current custom SQLite mapping with Drift layer (optional), keeping test coverage as migration safety net.

## 2026-03-31 - Iteration 4 (iOS platform setup + first launch)

### Scope delivered
- Generated iOS platform directory via `flutter create --platforms=ios .`.
- Removed auto-generated boilerplate `test/widget_test.dart` (referenced non-existent `MyApp`).
- Verified analyzer (0 issues) and test suite (8/8 passing) after platform generation.
- Installed Flutter SDK, Xcode, and CocoaPods on local machine.
- Successfully launched app on iOS Simulator for the first time.

### Decisions
- iOS-first approach — Android platform deferred until needed.
- No Xcode project edits needed; Flutter CLI handles the build.

### Current status
- App runs on iOS Simulator with all three tabs (Planner, Saved Routes, Settings).
- Green baseline maintained (analyzer clean, all tests pass).

### Bugs fixed during first manual testing
- **Overflow on flight planning screen**: wrapped body in `SingleChildScrollView`, added `shrinkWrap` + `NeverScrollableScrollPhysics` to `WaypointList` to avoid nested scroll conflict.
- **Route name not saved**: Save button now applies the current text field value before persisting.
- **Saved Routes tab not refreshing**: invalidate `savedRoutesProvider` after successful save.
- **Controller instability**: inlined `initialRouteProvider` into controller provider to prevent UUID regeneration on re-reads.
- Removed auto-generated `initialRouteProvider` (unused after refactor).
- Changed `saveCurrentRoute` return type to `Future<bool>` to allow UI feedback on success/failure.

### Next step recommendation
- Pick next development task: real map integration (MapLibre), Drift migration, or UI improvements.

## 2026-04-19 - Iteration 5 (3-agent planning sync + QA baseline hardening)

### Scope delivered
- Spawned a 3-agent team and synchronized responsibilities:
  - analyst/planner: implementation plans for MapLibre, Drift migration, UI improvements,
  - developer: readiness audit + concrete file-level backlog,
  - tester: QA review + automated test baseline expansion.
- Added dependencies required to unblock planned work:
  - runtime: `maplibre`, `drift`, `drift_flutter`, `path_provider`, `sqlite3_flutter_libs`,
  - dev: `drift_dev`, `build_runner`, `integration_test`.
- Expanded automated test coverage with new harness and scenarios:
  - controller tests for `FlightPlanningController`,
  - widget tests for `FlightPlanningScreen`, `WaypointList`, `RouteSummaryCard`,
  - app smoke test across main tabs,
  - additional route calculation multi-leg test.
- Added test support utilities in `test/support/` and integration test scaffold docs in `integration_test/`.

### Decisions
- QA-first sequencing for the current phase:
  1. keep baseline green with broader unit/widget coverage,
  2. execute MapLibre integration with smoke checks,
  3. keep Drift migration as optional hardening step after product-facing work.
- `integration_test` package is configured, but device-level execution still depends on local simulator/device setup.

### Verification
- `flutter pub get` -> dependencies resolved successfully.
- `flutter analyze` -> no issues found.
- `flutter test` -> all tests passed (20/20).

### Next step recommendation
- Start implementation spike for real map integration (MapLibre) on top of the new test baseline:
  - replace map placeholder widget with MapLibre rendering,
  - keep route overlay data contract stable,
  - validate with smoke tests and iOS simulator run.

## 2026-04-19 - Iteration 6 (MapLibre integration with 3-agent execution)

### Scope delivered
- Replaced map placeholder rendering with real `MapLibreMap` in `FlightMapWidget`.
- Implemented map states:
  - empty state when route has no waypoints,
  - waypoint markers for `>=1` waypoint,
  - route polyline for `>=2` waypoints.
- Added camera behavior:
  - center + zoom for single waypoint,
  - `fitBounds` for multi-point route,
  - camera refresh on map/style ready and waypoint updates.
- Reused the same map widget implementation in:
  - planner screen (`FlightPlanningScreen`),
  - dedicated map screen (`MapScreen`),
  to avoid duplicated map logic.
- Added/updated automated tests for map-related behavior and stabilized widget/smoke tests with test MapLibre platform mocks.

### Verification
- `flutter analyze` -> no issues found.
- `flutter test` -> all tests passed (28/28).

### Time tracking
- Task window (wall-clock): **17:43-17:54 CEST** (~**00:11**).
- Team elapsed time (parallel work): **~00:11**.
- Team effort sum (roles combined): **~00:34**.
- Per role (approx, session-tracked):
  - Planner agent: **~00:04**
  - Developer agent: **~00:10**
  - Tester agent: **~00:10**
  - Main coordinator: **~00:10**

### Notes
- Time values are approximate and based on session timestamps from the current run.
- Full native renderer validation on real device/simulator remains recommended after this iteration, even though CI/widget coverage is green.

## 2026-04-19 - Iteration 7 (simulator validation + map backlog reprioritization)

### Scope delivered
- Confirmed app launch on iOS Simulator (`iPhone 17`) after environment/bootstrap fixes.
- Reviewed current map implementation against requested next-stage scope.
- Reprioritized roadmap for next iteration with map-first requirements.

### Status split (requested map scope)
- Already implemented:
  - dedicated `MapScreen` widget exists (`lib/features/map_view/presentation/screens/map_screen.dart`),
  - map widget supports empty state (can render without waypoints),
  - MapLibre base integration (camera fit, route polyline, waypoint markers).
- Not implemented yet (next-stage backlog):
  - user-facing navigation path to standalone map screen without adding waypoint first,
  - built-in Polish aviation data pack (VFR points, airports, airspaces/strefy from AUP/AIP sources),
  - runtime layer toggles (airports / VFR points / airspaces),
  - map UI controls for resizing/scaling controls/buttons.

### Next step recommendation
- Execute map-priority backlog in this order:
  1. expose standalone map route/tab from app navigation,
  2. define ingest format and local storage for Polish AUP/AIP datasets,
  3. add map layer controller (toggle visibility by category),
  4. add UI size controls and test coverage for map interactions.

### Time tracking
- Task window (wall-clock): **18:46-19:10 CEST** (~**00:24**).
- Team/subagents used: **no** (main coordinator only).
- Coordinator effort: **~00:24**.
