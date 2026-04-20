# Map Enhancements — Design Spec
**Date:** 2026-04-20
**Status:** Approved for implementation

---

## Context

The app currently has a working MapLibre map embedded in the Planner tab. A standalone `MapScreen` exists but is not reachable from navigation. The previous iteration (Iteration 7) identified four next-step priorities:

1. Expose standalone map as a navigation destination
2. Define ingest format and local storage for Polish AUP/AIP aviation datasets
3. Add map layer controller (toggle visibility by category)
4. Add UI controls (zoom, compass, location, fit route)

This spec covers all four items as a single cohesive iteration.

---

## Goals

- Make the map a first-class screen in the app, accessible in one tap from anywhere
- Display real Polish aviation data (airports, VFR points, airspaces) on the map
- Allow the pilot to toggle each data layer on/off without leaving the map
- Provide essential map controls optimised for one-handed cockpit use

---

## Navigation Changes

### 4th Tab: Map

Add a **Map** tab as the second item in the bottom NavigationBar:

```
Plan | Map | Saved Routes | Settings
```

**Files to modify:**
- `lib/app/router/app_router.dart` — add `/map` route pointing to `MapScreen`
- `lib/shared/widgets/app_scaffold.dart` — add Map `NavigationDestination` at index 1; shift Saved Routes to index 2, Settings to index 3

`MapScreen` already exists at `lib/features/map_view/presentation/screens/map_screen.dart` — no new screen file needed, just wire it into navigation.

---

## New Feature Module: `aviation_data`

### Directory structure

```
lib/features/aviation_data/
  domain/
    entities/
      airport.dart
      vfr_point.dart
      airspace.dart
  data/
    datasources/
      aviation_data_loader.dart
  application/
    providers/
      aviation_data_providers.dart
      layer_visibility_provider.dart
```

### Domain entities

**`Airport`**
```dart
enum AirportType { licensed, grass, heliport, other }

class Airport {
  final String id;
  final String name;
  final String icaoCode;
  final double latitude;
  final double longitude;
  final AirportType type;
}
```

**`VfrPoint`**
```dart
class VfrPoint {
  final String id;
  final String name;
  final String code;   // e.g. "LIMA", "PAPA"
  final double latitude;
  final double longitude;
}
```

**`Airspace`**
```dart
enum AirspaceType { ctr, tma, mctr, restricted, prohibited, other }

class Airspace {
  final String id;
  final String name;
  final AirspaceType type;
  final String airspaceClass;   // "C", "D", "G", etc.
  final String ceiling;         // e.g. "FL100", "2500ft AMSL"
  final String floor;           // e.g. "GND", "500ft AGL"
  final List<(double lat, double lon)> polygon;
}
```

### Bundled GeoJSON assets

Three files live under `assets/aviation_data/` and are declared in `pubspec.yaml`:

```
assets/aviation_data/
  airports_pl.geojson
  vfr_points_pl.geojson
  airspaces_pl.geojson
```

**GeoJSON format — airports and VFR points** use `Point` geometry:
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [21.0122, 52.1657] },
      "properties": {
        "id": "EPWA",
        "name": "Warszawa Okęcie",
        "icao": "EPWA",
        "type": "licensed"
      }
    }
  ]
}
```

**GeoJSON format — airspaces** use `Polygon` geometry:
```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[20.9, 52.1], [21.1, 52.1], [21.1, 52.3], [20.9, 52.3], [20.9, 52.1]]]
      },
      "properties": {
        "id": "EPWA_CTR",
        "name": "Warszawa CTR",
        "type": "ctr",
        "class": "D",
        "ceiling": "FL095",
        "floor": "GND"
      }
    }
  ]
}
```

Data sources: **OpenFlightMaps** (openflightmaps.org) and **OpenAIP** (openaip.net) — both free, export GeoJSON, cover Polish airspace.

**Asset file creation:** The Engineer creates minimal sample GeoJSON files (5–10 entries each) for development and testing, formatted to match the schema above. Real production data should be downloaded from OpenFlightMaps or OpenAIP and converted to the above schema before release — this is out of scope for this iteration.

### Data loader

`AviationDataLoader` in `data/datasources/` uses `rootBundle.loadString()` to read each asset file and `dart:convert` to parse JSON. Returns typed lists. No DB, no file I/O — parsed data lives in memory via Riverpod.

### Providers

```dart
// aviation_data_providers.dart
final airportsProvider     = FutureProvider<List<Airport>>(...);
final vfrPointsProvider    = FutureProvider<List<VfrPoint>>(...);
final airspacesProvider    = FutureProvider<List<Airspace>>(...);

// layer_visibility_provider.dart
@immutable
class LayerVisibility {
  final bool showAirports;    // default: true
  final bool showVfrPoints;   // default: true
  final bool showAirspaces;   // default: true
  const LayerVisibility({...});
  LayerVisibility copyWith({...});
}

final layerVisibilityProvider = StateProvider<LayerVisibility>(
  (ref) => const LayerVisibility(showAirports: true, showVfrPoints: true, showAirspaces: true),
);
```

---

## Map Screen Changes

### Layers button + bottom sheet

Add a **Layers** `IconButton` to `MapScreen`'s AppBar (top-right). Tapping it calls `showModalBottomSheet` with three `SwitchListTile` rows:

| Icon | Label | Subtitle |
|------|-------|----------|
| ✈️ | Airports | Licensed fields, grass strips, heliports |
| 🔶 | VFR Reporting Points | CTR entry/exit points (LIMA, PAPA…) |
| 🟡 | Airspaces | CTR, TMA, MCTR boundaries |

Each switch reads from / writes to `layerVisibilityProvider`.

### Aviation data layers in `FlightMapWidget`

`FlightMapWidget` already renders `WaypointMarkerLayer` and `RoutePolylineLayer`. Extend it to conditionally render three new layer widgets, gated by `layerVisibilityProvider`:

- **`AirportMarkerLayer`** — `WidgetLayer` rendering a small plane icon for each airport; follows the same pattern as `WaypointMarkerLayer`
- **`VfrPointMarkerLayer`** — `WidgetLayer` rendering an orange diamond with the point code label
- **`AirspacePolygonLayer`** — dashed `PolylineLayer` tracing each airspace boundary polygon. Outline-only in this iteration (no fill) — keeps it simple and avoids obscuring the map underneath.

`FlightMapWidget` receives **both** aviation data lists and `LayerVisibility` via constructor parameters (injected from providers in `MapScreen`). The widget itself does not watch any Riverpod provider — `MapScreen` is the single point that reads providers and passes values down. This keeps `FlightMapWidget` fully testable in isolation.

### Map controls overlay

Wrap the map in a `Stack`. Add a `Column` of `FloatingActionButton.small` buttons anchored to `Alignment.bottomRight`:

| Button | Action |
|--------|--------|
| ⛶ Fit route | Calls existing `_fitCameraToRoute()` logic |
| 📍 My location | `Geolocator.getCurrentPosition()` → animate camera |
| + Zoom in | `mapController.animateCamera(CameraUpdate.zoomIn())` |
| − Zoom out | `mapController.animateCamera(CameraUpdate.zoomOut())` |

Compass button (`🧭`) appears top-left only when map bearing ≠ 0° (via `MapLibreMap.onCameraIdle` callback checking bearing). Tapping resets bearing to 0.

### New dependency: `geolocator`

- Add `geolocator: ^13.0.0` to `pubspec.yaml`
- Add to `ios/Runner/Info.plist`:
  ```xml
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>FlightAssistant uses your location to show your position on the map.</string>
  ```
- Request permission on first tap of the My Location button using `Geolocator.requestPermission()`

---

## Error Handling

| Scenario | Behaviour |
|----------|-----------|
| GeoJSON asset missing or malformed | Log error, return empty list — map shows without that layer; no crash |
| Location permission denied | Show `SnackBar`: "Location permission denied. Enable it in Settings." |
| Location service disabled | Show `SnackBar`: "Enable location services to use this feature." |
| MapLibre not supported (simulator edge case) | Existing placeholder fallback already handles this |

---

## Testing Plan

| Test file | Type | Checks |
|-----------|------|--------|
| `test/features/aviation_data/data/airport_parser_test.dart` | Unit | GeoJSON string → correct `List<Airport>` incl. type mapping |
| `test/features/aviation_data/data/vfr_point_parser_test.dart` | Unit | GeoJSON string → correct `List<VfrPoint>` |
| `test/features/aviation_data/data/airspace_parser_test.dart` | Unit | GeoJSON string → correct `List<Airspace>` incl. polygon coordinates |
| `test/features/aviation_data/application/layer_visibility_provider_test.dart` | Unit | Toggle state transitions (all combos) |
| `test/features/map_view/presentation/screens/map_screen_layers_test.dart` | Widget | Tapping Layers button opens sheet; toggling switch updates provider |
| `test/features/map_view/presentation/screens/map_screen_smoke_test.dart` | Widget | Extend existing smoke test to cover 4-tab navigation |

GPS / `geolocator` integration not tested at unit level — device-specific, deferred to manual QA on simulator.

---

## Out of Scope (next iterations)

- Live API fetch from OpenAIP / OpenFlightMaps
- AUP delta updates (dynamic airspace activation)
- Drift migration for user route storage
- Navigation mode (active GPS tracking along route)
- Android platform support
