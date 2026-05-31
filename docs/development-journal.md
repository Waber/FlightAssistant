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

## 2026-04-20 - Iteration 8 (map enhancements: 4th tab, aviation layers, controls)

### Scope delivered
All four items from Iteration 7's next-step recommendation are now implemented:

1. **Standalone Map tab** — added as 2nd item in the NavigationBar (order: Plan / Map / Saved / Settings). Plan tab icon switched to `flight` so the `map` icon could move to the new Map tab.
2. **Polish aviation data module** (`lib/features/aviation_data/`) with clean-architecture layering:
   - Domain entities: `Airport`, `VfrPoint`, `Airspace` + `AirportType`/`AirspaceType` enums.
   - Data source: `AviationDataLoader` — static GeoJSON parsers (airports/VFR points use `Point` geometry; airspaces use `Polygon`). Returns empty list on malformed JSON, logs errors via `dart:developer`.
   - Bundled sample GeoJSON assets in `assets/aviation_data/`: 5 airports, 5 VFR points, 3 airspaces (2 CTR + 1 TMA).
   - Riverpod providers: `airportsProvider`, `vfrPointsProvider`, `airspacesProvider` (FutureProviders), `layerVisibilityProvider` (StateProvider<LayerVisibility>).
3. **Layer toggles** — "Layers" IconButton in MapScreen AppBar opens a modal bottom sheet with 3 `SwitchListTile` toggles (Airports / VFR Reporting Points / Airspaces). Bottom sheet is a standalone `ConsumerWidget` (does NOT capture parent `WidgetRef`).
4. **Map UI controls** — floating overlay on the Map tab with 4 buttons: zoom in/out, fit route, my location. Compass button plumbing in place but `_showCompass` always false (documented limitation: maplibre ^0.3.5 lacks `onCameraMove` callback). Added `geolocator: ^13.0.0` dependency + `NSLocationWhenInUseUsageDescription` in `ios/Runner/Info.plist`.

### Visual components added
- `AirportMarkerLayer` — blue circles with flight icon, follows `WaypointMarkerLayer` pattern.
- `VfrPointMarkerLayer` — orange rounded rectangles with NATO phonetic code labels.
- `AirspacePolygonLayer` — amber dashed outlines (`PolylineLayer` with closed `LineString` rings).
- `MapControlsOverlay` — vertical stack of semi-transparent black buttons bottom-right, conditional compass top-left.

### Decisions
- **Approach 1 (in-memory)** chosen over SQLite for aviation data — bundled GeoJSON → Dart objects via Riverpod, no new DB tables. Matches the current scale (~13 sample features; real Polish dataset would be ~1000) and keeps the `AppDatabase` focused on user routes.
- **`_LayersBottomSheet` is its own `ConsumerWidget`** — never pass `WidgetRef` into a bottom sheet builder. The `ref` captured in parent `build` becomes invalid after that build completes; the modal lives past that point.
- **`FlightMapWidget` receives aviation data + `LayerVisibility` via constructor** (not via provider `watch` inside the widget) — `MapScreen` is the single point that reads providers and passes values down, keeping `FlightMapWidget` testable in isolation.
- **Added `bodyPadding` and `actions` params to `AppScaffold`** — backward compatible (both optional with sensible defaults). Map tab uses `EdgeInsets.zero` for full-bleed rendering + injects the Layers action.

### Verification
- `flutter test` → **57/57 passed** (previously 28 baseline + 29 new tests across parser, provider, widget, and screen tests).
- `flutter analyze` → **No issues found!**
- `flutter build ios --simulator --no-codesign` → **blocked by environment** (not a code issue): `flutter clean` during troubleshooting wiped the SwiftPM cache (`~/Library/Caches/org.swift.swiftpm/artifacts/`). MapLibre's xcframework ZIP needs to be re-downloaded via Xcode resolution before the next simulator run. `pod install` was re-run successfully (with `LANG=en_US.UTF-8` workaround for CocoaPods 1.16.2 encoding bug). User should open `ios/Runner.xcworkspace` in Xcode and let SPM re-resolve the MapLibre package.

### Review findings addressed inline
- **AviationDataLoader**: reviewer flagged missing error logging (spec said "Log error, return empty list"). Added `dart:developer` log calls in all 3 catch blocks.
- **FlightMapWidget**: reviewer flagged `_showCompass` never set to true (dead branch until maplibre version upgrade) and missing handling for `LocationPermission.unableToDetermine`. Added TODO comment explaining the limitation and extended the permission denial branch.
- **map_screen_smoke_test.dart**: unused `layer_visibility_provider` import from plan was removed.

### Deferred follow-ups (flagged during reviews, not blocking this iteration)
- `AviationDataLoader` drops the entire list when one feature is malformed. Consider per-feature error isolation so one bad record doesn't nuke the whole layer (important when real Polish AIS data lands).
- `AviationDataLoader.parseAirspaces` only handles `Polygon` geometry. Real AIS data often uses `MultiPolygon` — will silently drop those features today.
- `MapScreen` uses `valueOrNull ?? []` on aviation FutureProviders — loading and error states are invisible to the user. No SnackBar / spinner / skeleton. Consider `.when(...)` pattern with a lightweight progress indicator in a follow-up.
- `_currentZoom` in `FlightMapWidget` is best-effort (last-commanded) — pinch-zoom desyncs it until the next +/- tap. Worth consuming live camera state via `MapCamera.maybeOf` once the camera-change callback is available.
- `AirportType` enum doesn't include `atz`, `danger`, `tsa/tra`, `rmz/tmz` — may need extending once real OpenAIP / OpenFlightMaps GeoJSON replaces the sample data.
- Real production Polish aviation data (OpenAIP / OpenFlightMaps) needs to be downloaded and converted to the app's GeoJSON schema — sample data is for dev/test only.

### Next step recommendation
- Open `ios/Runner.xcworkspace` in Xcode, let SwiftPM resolve MapLibre, then run the app on iOS Simulator to manually verify:
  - Map tab reachable in one tap from any other tab
  - Airport/VFR/airspace markers appear on the map (5/5/3 from sample data)
  - Layer toggles actually hide/show markers without reload
  - Zoom, fit-route, my-location, compass controls all work
- After manual verification, consider which deferred follow-up to tackle next (Drift migration, real production data ingest pipeline, or `.when(...)` loading/error UX) as Iteration 9.

### Time tracking
- Task window (wall-clock): **18:42-20:01 CEST** (~**01:19**).
- Team/subagents used: **yes** — subagent-driven development with implementer + two-stage review (spec compliance + code quality) per task.
- Execution model: **sequential** (not parallel) — each task dispatched one implementer, then one spec reviewer, then one code-quality reviewer before moving on.
- Per-role effort (approximate, summed across all tasks):
  - Planner / PM (design + plan written earlier this session, then informed each implementer brief): **~00:15**
  - Developer (13 implementer subagents): **~00:55**
  - Tester / QA (spec + code-quality reviewer subagents, some combined for trivial tasks): **~00:45**
  - Main coordinator (me, orchestration + follow-up fixes): **~01:19** (wall-clock)
- Team effort sum (roles combined, sequential): **~03:14**.
- Follow-up time spent on iOS build cache troubleshooting after main implementation complete: **~00:07** (19:54-20:01).

## 2026-05-31 - Iteration 9 (fix: iOS build "Use of undeclared identifier 'MapLibrePlugin'")

### Symptom
- `flutter build ios --simulator` failed with:
  `Semantic Issue (Xcode): Use of undeclared identifier 'MapLibrePlugin'` at
  `ios/Runner/GeneratedPluginRegistrant.m:50`.

### Root cause (systematic debugging, no subagents)
The `maplibre` package **requires Swift Package Manager (SwiftPM) on iOS**, but the
project had SwiftPM disabled, so the plugin was forced through CocoaPods. Evidence gathered:
- The `maplibre_ios` pod compiled fine — `maplibre_ios.framework` was produced and its
  generated `maplibre_ios-Swift.h` **did** declare `@interface MapLibrePlugin : NSObject <FlutterPlugin>`.
- The only build error was the `undeclared identifier` at the registration call — no
  "module not found" / "could not build module" preceding it.
- `maplibre_ios` is the **only** plugin whose registrant entry needs an extra
  `#import <maplibre_ios/maplibre_ios-Swift.h>` (its Swift class lives in a separate `.Swift`
  submodule that `@import maplibre_ios;` alone does not pull into the Objective-C registrant).
- `flutter config` showed `enable-swift-package-manager: (Not set)` and `project.pbxproj`
  had **0** SwiftPM references — i.e. the Swift-only plugin class was invisible to the ObjC
  `GeneratedPluginRegistrant.m`.
- Confirmed against the package docs: *"The package requires Swift Package Manager to be enabled."*
  This also matches the Iteration 8 notes that referenced a "SwiftPM cache" / MapLibre
  xcframework resolution — SwiftPM was the intended setup; the flag had been lost.

### Fix
- Enabled SwiftPM **in `pubspec.yaml`** (repo-committed, not a machine-global flag) so the
  setting travels with the project:
  ```yaml
  flutter:
    config:
      enable-swift-package-manager: true
  ```
- Ran `flutter pub get` + `flutter build ios --simulator --no-codesign`. Flutter migrated the
  Xcode project to SwiftPM (added the generated Swift package, 16 SwiftPM refs in
  `project.pbxproj`, new `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/`).

### Verification
- `flutter build ios --simulator --no-codesign` → **✓ Built build/ios/iphonesimulator/Runner.app** (exit 0).
- Change is iOS-build-config only; Dart unit/widget tests (57/57) are unaffected.

### Files changed
- `pubspec.yaml` (SwiftPM config)
- `ios/Runner.xcodeproj/project.pbxproj`, `Runner.xcscheme` (SwiftPM migration, Flutter-generated)
- `ios/Podfile.lock` (maplibre_ios moved off CocoaPods)
- new: `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

### Time tracking
- Task window (wall-clock): ~**00:25** (investigation + first failing build + clean pod/xcodebuild
  evidence run + SwiftPM rebuild incl. MapLibre xcframework download).
- Team/subagents used: **no** (main coordinator only).
- Coordinator effort (total): ~**00:25**.

### AI model
- Claude Code (Claude Opus 4.8, 1M context).

### Next step recommendation
- Manually run the app on iOS Simulator and verify the Iteration 8 map features (Map tab,
  airport/VFR/airspace markers, layer toggles, map controls), now that the build is unblocked.

## Backlog / future steps (captured, not yet scheduled)

- **User-provided OpenAIP API key (data refresh from the app).** Let the user paste their own
  free OpenAIP API key into the app (Settings), so they can refresh the aviation dataset on demand
  when online. Belongs to **Phase 2** of the aviation-data work (runtime refresh + cache): the
  user's key is what `RemoteAviationDataSource` authenticates with — the key comes from the user,
  not bundled in the app. Phase 1 ships read-only bundled OpenAIP data (offline); this is the
  follow-up that makes the data updatable per-user. Requested by the user on 2026-05-31.
