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
