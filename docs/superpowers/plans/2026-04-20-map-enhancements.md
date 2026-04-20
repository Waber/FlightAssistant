# Map Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a standalone Map tab to navigation, display Polish aviation data (airports, VFR points, airspaces) as toggleable layers, and add map controls (zoom, compass, location, fit route).

**Architecture:** New `aviation_data` feature module holds domain entities, a GeoJSON parser, and Riverpod providers. `FlightMapWidget` is extended with optional aviation layer params and an optional controls overlay. `MapScreen` is updated to wire providers and host a bottom-sheet layer toggle.

**Tech Stack:** Flutter, Riverpod, MapLibre ^0.3.5, geolocator ^13.0.0, go_router ^14.8.1, dart:convert

**Spec:** `docs/superpowers/specs/2026-04-20-map-enhancements-design.md`

---

## File Map

### New files
| File | Responsibility |
|------|---------------|
| `lib/features/aviation_data/domain/entities/airport.dart` | Airport entity + AirportType enum |
| `lib/features/aviation_data/domain/entities/vfr_point.dart` | VfrPoint entity |
| `lib/features/aviation_data/domain/entities/airspace.dart` | Airspace entity + AirspaceType enum |
| `lib/features/aviation_data/data/datasources/aviation_data_loader.dart` | Static GeoJSON parsers + asset loaders |
| `lib/features/aviation_data/application/providers/aviation_data_providers.dart` | FutureProviders for airports/vfrPoints/airspaces |
| `lib/features/aviation_data/application/providers/layer_visibility_provider.dart` | LayerVisibility class + StateProvider |
| `lib/features/map_view/presentation/widgets/airport_marker_layer.dart` | WidgetLayer rendering airport icons |
| `lib/features/map_view/presentation/widgets/vfr_point_marker_layer.dart` | WidgetLayer rendering VFR point markers |
| `lib/features/map_view/presentation/widgets/airspace_polygon_layer.dart` | Static helper returning PolylineLayer for airspace outlines |
| `lib/features/map_view/presentation/widgets/map_controls_overlay.dart` | Floating zoom/compass/location/fit-route buttons |
| `assets/aviation_data/airports_pl.geojson` | Sample Polish airport data |
| `assets/aviation_data/vfr_points_pl.geojson` | Sample Polish VFR reporting points |
| `assets/aviation_data/airspaces_pl.geojson` | Sample Polish airspace data |
| `test/features/aviation_data/data/airport_parser_test.dart` | Unit tests for airport GeoJSON parsing |
| `test/features/aviation_data/data/vfr_point_parser_test.dart` | Unit tests for VFR point GeoJSON parsing |
| `test/features/aviation_data/data/airspace_parser_test.dart` | Unit tests for airspace GeoJSON parsing |
| `test/features/aviation_data/application/layer_visibility_provider_test.dart` | Unit tests for layer toggle state |
| `test/features/map_view/presentation/screens/map_screen_layers_test.dart` | Widget tests for layer bottom sheet |

### Modified files
| File | Change |
|------|--------|
| `pubspec.yaml` | Add geolocator, declare aviation_data assets |
| `ios/Runner/Info.plist` | Add NSLocationWhenInUseUsageDescription |
| `lib/app/router/app_router.dart` | Add `/map` route |
| `lib/shared/widgets/app_scaffold.dart` | Add Map tab at index 1; add optional bodyPadding param |
| `lib/features/map_view/presentation/screens/map_screen.dart` | Add layers button + bottom sheet; wire aviation providers; fix currentIndex to 1 |
| `lib/features/map_view/presentation/widgets/flight_map_widget.dart` | Add aviation layer params, showControls flag, controls overlay |
| `test/features/map_view/presentation/screens/map_screen_smoke_test.dart` | Extend for 4-tab navigation |

---

## Task 1: Dependencies & iOS permission

**Files:**
- Modify: `pubspec.yaml`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 1.1: Add geolocator and declare GeoJSON assets in pubspec.yaml**

Replace the `dependencies:` block and add the `flutter:` section:

```yaml
dependencies:
  drift: ^2.32.1
  drift_flutter: ^0.3.0
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  geolocator: ^13.0.0
  go_router: ^14.8.1
  maplibre: ^0.3.5
  path: ^1.9.1
  path_provider: ^2.1.5
  sqflite: ^2.4.2
  sqlite3_flutter_libs: ^0.6.0+eol
  uuid: ^4.5.1

flutter:
  uses-material-design: true
  assets:
    - assets/aviation_data/airports_pl.geojson
    - assets/aviation_data/vfr_points_pl.geojson
    - assets/aviation_data/airspaces_pl.geojson
```

- [ ] **Step 1.2: Add location permission to Info.plist**

Insert these two lines before the closing `</dict>` tag in `ios/Runner/Info.plist`:

```xml
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>FlightAssistant uses your location to show your position on the map.</string>
</dict>
```

- [ ] **Step 1.3: Run flutter pub get**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter pub get
```

Expected: `Running "flutter pub get" in flight_assistant...` with no errors.

- [ ] **Step 1.4: Commit**

```bash
git add pubspec.yaml pubspec.lock ios/Runner/Info.plist
git commit -m "chore: add geolocator dependency and aviation data asset declarations"
```

---

## Task 2: Sample GeoJSON asset files

**Files:**
- Create: `assets/aviation_data/airports_pl.geojson`
- Create: `assets/aviation_data/vfr_points_pl.geojson`
- Create: `assets/aviation_data/airspaces_pl.geojson`

These are sample files for development and testing. Real data can be downloaded from openflightmaps.org or openaip.net and converted to this schema later.

- [ ] **Step 2.1: Create the assets directory**

```bash
mkdir -p /Users/przemek/LearningProjects/FlightAssistant/assets/aviation_data
```

- [ ] **Step 2.2: Create airports_pl.geojson**

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [20.9679, 52.1657] },
      "properties": { "id": "EPWA", "name": "Warszawa Chopin", "icao": "EPWA", "type": "licensed" }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [18.5910, 54.3777] },
      "properties": { "id": "EPGD", "name": "Gdańsk Lech Wałęsa", "icao": "EPGD", "type": "licensed" }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [16.8858, 51.1008] },
      "properties": { "id": "EPWR", "name": "Wrocław Mikołaj Kopernik", "icao": "EPWR", "type": "licensed" }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [19.7965, 50.0777] },
      "properties": { "id": "EPKK", "name": "Kraków Balice", "icao": "EPKK", "type": "licensed" }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [23.0103, 52.0853] },
      "properties": { "id": "EPBL", "name": "Biała Podlaska", "icao": "EPBL", "type": "grass" }
    }
  ]
}
```

- [ ] **Step 2.3: Create vfr_points_pl.geojson**

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [20.9122, 52.3050] },
      "properties": { "id": "LIMA", "name": "Lima", "code": "LIMA" }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [21.1833, 52.1667] },
      "properties": { "id": "PAPA", "name": "Papa", "code": "PAPA" }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [20.7667, 52.1000] },
      "properties": { "id": "GOLF", "name": "Golf", "code": "GOLF" }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [21.0500, 52.3833] },
      "properties": { "id": "ROMEO", "name": "Romeo", "code": "ROMEO" }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [20.8500, 51.9833] },
      "properties": { "id": "DELTA", "name": "Delta", "code": "DELTA" }
    }
  ]
}
```

- [ ] **Step 2.4: Create airspaces_pl.geojson**

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[20.6667, 51.9167], [21.3333, 51.9167], [21.3333, 52.4167], [20.6667, 52.4167], [20.6667, 51.9167]]]
      },
      "properties": { "id": "EPWA_CTR", "name": "Warszawa CTR", "type": "ctr", "class": "D", "ceiling": "FL095", "floor": "GND" }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[18.3333, 54.1667], [18.8333, 54.1667], [18.8333, 54.5833], [18.3333, 54.5833], [18.3333, 54.1667]]]
      },
      "properties": { "id": "EPGD_CTR", "name": "Gdańsk CTR", "type": "ctr", "class": "D", "ceiling": "FL095", "floor": "GND" }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[19.5000, 49.7500], [20.2500, 49.7500], [20.2500, 50.3500], [19.5000, 50.3500], [19.5000, 49.7500]]]
      },
      "properties": { "id": "EPKK_TMA", "name": "Kraków TMA", "type": "tma", "class": "D", "ceiling": "FL145", "floor": "1500ft AMSL" }
    }
  ]
}
```

- [ ] **Step 2.5: Commit**

```bash
git add assets/
git commit -m "feat: add sample Polish aviation GeoJSON asset files"
```

---

## Task 3: Domain entities

**Files:**
- Create: `lib/features/aviation_data/domain/entities/airport.dart`
- Create: `lib/features/aviation_data/domain/entities/vfr_point.dart`
- Create: `lib/features/aviation_data/domain/entities/airspace.dart`

No tests needed — these are pure immutable data classes with no behaviour.

- [ ] **Step 3.1: Create airport.dart**

```dart
enum AirportType { licensed, grass, heliport, other }

class Airport {
  const Airport({
    required this.id,
    required this.name,
    required this.icaoCode,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  final String id;
  final String name;
  final String icaoCode;
  final double latitude;
  final double longitude;
  final AirportType type;
}
```

- [ ] **Step 3.2: Create vfr_point.dart**

```dart
class VfrPoint {
  const VfrPoint({
    required this.id,
    required this.name,
    required this.code,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String code; // e.g. "LIMA", "PAPA"
  final double latitude;
  final double longitude;
}
```

- [ ] **Step 3.3: Create airspace.dart**

```dart
enum AirspaceType { ctr, tma, mctr, restricted, prohibited, other }

class Airspace {
  const Airspace({
    required this.id,
    required this.name,
    required this.type,
    required this.airspaceClass,
    required this.ceiling,
    required this.floor,
    required this.polygon,
  });

  final String id;
  final String name;
  final AirspaceType type;
  final String airspaceClass; // "C", "D", "G", etc.
  final String ceiling;       // e.g. "FL100", "2500ft AMSL"
  final String floor;         // e.g. "GND", "500ft AGL"
  final List<(double lat, double lon)> polygon;
}
```

- [ ] **Step 3.4: Commit**

```bash
git add lib/features/aviation_data/
git commit -m "feat: add aviation data domain entities (Airport, VfrPoint, Airspace)"
```

---

## Task 4: AviationDataLoader with TDD

**Files:**
- Create: `test/features/aviation_data/data/airport_parser_test.dart`
- Create: `test/features/aviation_data/data/vfr_point_parser_test.dart`
- Create: `test/features/aviation_data/data/airspace_parser_test.dart`
- Create: `lib/features/aviation_data/data/datasources/aviation_data_loader.dart`

- [ ] **Step 4.1: Write failing airport parser tests**

Create `test/features/aviation_data/data/airport_parser_test.dart`:

```dart
import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [20.9679, 52.1657] },
      "properties": { "id": "EPWA", "name": "Warszawa Chopin", "icao": "EPWA", "type": "licensed" }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [23.0103, 52.0853] },
      "properties": { "id": "EPBL", "name": "Biała Podlaska", "icao": "EPBL", "type": "grass" }
    }
  ]
}
''';

  group('AviationDataLoader.parseAirports', () {
    test('returns correct count', () {
      final result = AviationDataLoader.parseAirports(sampleJson);
      expect(result.length, 2);
    });

    test('parses first airport fields correctly', () {
      final result = AviationDataLoader.parseAirports(sampleJson);
      final epwa = result.first;
      expect(epwa.id, 'EPWA');
      expect(epwa.name, 'Warszawa Chopin');
      expect(epwa.icaoCode, 'EPWA');
      expect(epwa.latitude, closeTo(52.1657, 0.0001));
      expect(epwa.longitude, closeTo(20.9679, 0.0001));
      expect(epwa.type, AirportType.licensed);
    });

    test('maps grass type correctly', () {
      final result = AviationDataLoader.parseAirports(sampleJson);
      expect(result[1].type, AirportType.grass);
    });

    test('returns empty list for empty FeatureCollection', () {
      const empty = '{"type":"FeatureCollection","features":[]}';
      expect(AviationDataLoader.parseAirports(empty), isEmpty);
    });

    test('returns empty list for malformed JSON', () {
      expect(AviationDataLoader.parseAirports('not json'), isEmpty);
    });
  });
}
```

- [ ] **Step 4.2: Write failing VFR point parser tests**

Create `test/features/aviation_data/data/vfr_point_parser_test.dart`:

```dart
import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [20.9122, 52.3050] },
      "properties": { "id": "LIMA", "name": "Lima", "code": "LIMA" }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [21.1833, 52.1667] },
      "properties": { "id": "PAPA", "name": "Papa", "code": "PAPA" }
    }
  ]
}
''';

  group('AviationDataLoader.parseVfrPoints', () {
    test('returns correct count', () {
      expect(AviationDataLoader.parseVfrPoints(sampleJson).length, 2);
    });

    test('parses fields correctly', () {
      final result = AviationDataLoader.parseVfrPoints(sampleJson);
      final lima = result.first;
      expect(lima.id, 'LIMA');
      expect(lima.name, 'Lima');
      expect(lima.code, 'LIMA');
      expect(lima.latitude, closeTo(52.3050, 0.0001));
      expect(lima.longitude, closeTo(20.9122, 0.0001));
    });

    test('returns empty list for empty FeatureCollection', () {
      const empty = '{"type":"FeatureCollection","features":[]}';
      expect(AviationDataLoader.parseVfrPoints(empty), isEmpty);
    });

    test('returns empty list for malformed JSON', () {
      expect(AviationDataLoader.parseVfrPoints('not json'), isEmpty);
    });
  });
}
```

- [ ] **Step 4.3: Write failing airspace parser tests**

Create `test/features/aviation_data/data/airspace_parser_test.dart`:

```dart
import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[20.6667, 51.9167], [21.3333, 51.9167], [21.3333, 52.4167], [20.6667, 52.4167], [20.6667, 51.9167]]]
      },
      "properties": { "id": "EPWA_CTR", "name": "Warszawa CTR", "type": "ctr", "class": "D", "ceiling": "FL095", "floor": "GND" }
    }
  ]
}
''';

  group('AviationDataLoader.parseAirspaces', () {
    test('returns correct count', () {
      expect(AviationDataLoader.parseAirspaces(sampleJson).length, 1);
    });

    test('parses fields correctly', () {
      final result = AviationDataLoader.parseAirspaces(sampleJson);
      final ctr = result.first;
      expect(ctr.id, 'EPWA_CTR');
      expect(ctr.name, 'Warszawa CTR');
      expect(ctr.type, AirspaceType.ctr);
      expect(ctr.airspaceClass, 'D');
      expect(ctr.ceiling, 'FL095');
      expect(ctr.floor, 'GND');
    });

    test('parses polygon coordinates in lat/lon order', () {
      final result = AviationDataLoader.parseAirspaces(sampleJson);
      final polygon = result.first.polygon;
      expect(polygon.length, 5); // 4 corners + closing point
      // GeoJSON is [lon, lat] — parser must flip to (lat, lon)
      expect(polygon.first.$1, closeTo(51.9167, 0.0001)); // lat
      expect(polygon.first.$2, closeTo(20.6667, 0.0001)); // lon
    });

    test('returns empty list for empty FeatureCollection', () {
      const empty = '{"type":"FeatureCollection","features":[]}';
      expect(AviationDataLoader.parseAirspaces(empty), isEmpty);
    });

    test('returns empty list for malformed JSON', () {
      expect(AviationDataLoader.parseAirspaces('not json'), isEmpty);
    });
  });
}
```

- [ ] **Step 4.4: Run tests to confirm they fail**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter test test/features/aviation_data/
```

Expected: compilation error — `AviationDataLoader` not found yet.

- [ ] **Step 4.5: Implement AviationDataLoader**

Create `lib/features/aviation_data/data/datasources/aviation_data_loader.dart`:

```dart
import 'dart:convert';

import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';
import 'package:flutter/services.dart';

class AviationDataLoader {
  const AviationDataLoader._();

  static Future<List<Airport>> loadAirports() async {
    final raw = await rootBundle.loadString(
      'assets/aviation_data/airports_pl.geojson',
    );
    return parseAirports(raw);
  }

  static Future<List<VfrPoint>> loadVfrPoints() async {
    final raw = await rootBundle.loadString(
      'assets/aviation_data/vfr_points_pl.geojson',
    );
    return parseVfrPoints(raw);
  }

  static Future<List<Airspace>> loadAirspaces() async {
    final raw = await rootBundle.loadString(
      'assets/aviation_data/airspaces_pl.geojson',
    );
    return parseAirspaces(raw);
  }

  static List<Airport> parseAirports(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      final features = map['features'] as List<dynamic>;
      return features.map((f) {
        final props = f['properties'] as Map<String, dynamic>;
        final coords = f['geometry']['coordinates'] as List<dynamic>;
        return Airport(
          id: props['id'] as String,
          name: props['name'] as String,
          icaoCode: props['icao'] as String,
          latitude: (coords[1] as num).toDouble(),
          longitude: (coords[0] as num).toDouble(),
          type: _parseAirportType(props['type'] as String),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static List<VfrPoint> parseVfrPoints(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      final features = map['features'] as List<dynamic>;
      return features.map((f) {
        final props = f['properties'] as Map<String, dynamic>;
        final coords = f['geometry']['coordinates'] as List<dynamic>;
        return VfrPoint(
          id: props['id'] as String,
          name: props['name'] as String,
          code: props['code'] as String,
          latitude: (coords[1] as num).toDouble(),
          longitude: (coords[0] as num).toDouble(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static List<Airspace> parseAirspaces(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      final features = map['features'] as List<dynamic>;
      return features.map((f) {
        final props = f['properties'] as Map<String, dynamic>;
        final rawRing =
            (f['geometry']['coordinates'] as List<dynamic>)[0] as List<dynamic>;
        final polygon = rawRing.map((c) {
          final coord = c as List<dynamic>;
          // GeoJSON uses [lon, lat]; convert to (lat, lon) record
          return ((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
        }).toList();
        return Airspace(
          id: props['id'] as String,
          name: props['name'] as String,
          type: _parseAirspaceType(props['type'] as String),
          airspaceClass: props['class'] as String,
          ceiling: props['ceiling'] as String,
          floor: props['floor'] as String,
          polygon: polygon,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static AirportType _parseAirportType(String value) => switch (value) {
        'licensed' => AirportType.licensed,
        'grass' => AirportType.grass,
        'heliport' => AirportType.heliport,
        _ => AirportType.other,
      };

  static AirspaceType _parseAirspaceType(String value) => switch (value) {
        'ctr' => AirspaceType.ctr,
        'tma' => AirspaceType.tma,
        'mctr' => AirspaceType.mctr,
        'restricted' => AirspaceType.restricted,
        'prohibited' => AirspaceType.prohibited,
        _ => AirspaceType.other,
      };
}
```

- [ ] **Step 4.6: Run tests to confirm they pass**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter test test/features/aviation_data/
```

Expected: all 13 new tests PASS.

- [ ] **Step 4.7: Commit**

```bash
git add lib/features/aviation_data/data/ test/features/aviation_data/data/
git commit -m "feat: add AviationDataLoader with GeoJSON parsers (TDD)"
```

---

## Task 5: LayerVisibility provider with TDD

**Files:**
- Create: `test/features/aviation_data/application/layer_visibility_provider_test.dart`
- Create: `lib/features/aviation_data/application/providers/layer_visibility_provider.dart`

- [ ] **Step 5.1: Write failing provider tests**

Create `test/features/aviation_data/application/layer_visibility_provider_test.dart`:

```dart
import 'package:flight_assistant/features/aviation_data/application/providers/layer_visibility_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('layerVisibilityProvider', () {
    test('starts with all layers visible', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final vis = container.read(layerVisibilityProvider);
      expect(vis.showAirports, isTrue);
      expect(vis.showVfrPoints, isTrue);
      expect(vis.showAirspaces, isTrue);
    });

    test('copyWith toggles airports independently', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(layerVisibilityProvider.notifier).state =
          container.read(layerVisibilityProvider).copyWith(showAirports: false);
      final vis = container.read(layerVisibilityProvider);
      expect(vis.showAirports, isFalse);
      expect(vis.showVfrPoints, isTrue);
      expect(vis.showAirspaces, isTrue);
    });

    test('copyWith toggles vfrPoints independently', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(layerVisibilityProvider.notifier).state =
          container.read(layerVisibilityProvider).copyWith(showVfrPoints: false);
      expect(container.read(layerVisibilityProvider).showVfrPoints, isFalse);
      expect(container.read(layerVisibilityProvider).showAirports, isTrue);
    });

    test('can turn all layers off', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(layerVisibilityProvider.notifier);
      notifier.state = notifier.state.copyWith(showAirports: false);
      notifier.state = notifier.state.copyWith(showVfrPoints: false);
      notifier.state = notifier.state.copyWith(showAirspaces: false);
      final vis = container.read(layerVisibilityProvider);
      expect(vis.showAirports, isFalse);
      expect(vis.showVfrPoints, isFalse);
      expect(vis.showAirspaces, isFalse);
    });
  });
}
```

- [ ] **Step 5.2: Run test to confirm it fails**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter test test/features/aviation_data/application/
```

Expected: compilation error — `layerVisibilityProvider` not found.

- [ ] **Step 5.3: Implement layer_visibility_provider.dart**

Create `lib/features/aviation_data/application/providers/layer_visibility_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LayerVisibility {
  const LayerVisibility({
    this.showAirports = true,
    this.showVfrPoints = true,
    this.showAirspaces = true,
  });

  final bool showAirports;
  final bool showVfrPoints;
  final bool showAirspaces;

  LayerVisibility copyWith({
    bool? showAirports,
    bool? showVfrPoints,
    bool? showAirspaces,
  }) {
    return LayerVisibility(
      showAirports: showAirports ?? this.showAirports,
      showVfrPoints: showVfrPoints ?? this.showVfrPoints,
      showAirspaces: showAirspaces ?? this.showAirspaces,
    );
  }
}

final layerVisibilityProvider = StateProvider<LayerVisibility>(
  (ref) => const LayerVisibility(),
);
```

- [ ] **Step 5.4: Run tests to confirm they pass**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter test test/features/aviation_data/application/
```

Expected: all 4 tests PASS.

- [ ] **Step 5.5: Commit**

```bash
git add lib/features/aviation_data/application/providers/layer_visibility_provider.dart \
        test/features/aviation_data/application/
git commit -m "feat: add LayerVisibility provider (TDD)"
```

---

## Task 6: Aviation data FutureProviders

**Files:**
- Create: `lib/features/aviation_data/application/providers/aviation_data_providers.dart`

These providers just delegate to `AviationDataLoader`. They're tested indirectly through widget test overrides in later tasks.

- [ ] **Step 6.1: Implement aviation_data_providers.dart**

Create `lib/features/aviation_data/application/providers/aviation_data_providers.dart`:

```dart
import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final airportsProvider = FutureProvider<List<Airport>>(
  (ref) => AviationDataLoader.loadAirports(),
);

final vfrPointsProvider = FutureProvider<List<VfrPoint>>(
  (ref) => AviationDataLoader.loadVfrPoints(),
);

final airspacesProvider = FutureProvider<List<Airspace>>(
  (ref) => AviationDataLoader.loadAirspaces(),
);
```

- [ ] **Step 6.2: Run full test suite to confirm no regressions**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter test
```

Expected: all existing tests PASS (currently 28) plus 17 new tests = 45 total.

- [ ] **Step 6.3: Commit**

```bash
git add lib/features/aviation_data/application/providers/aviation_data_providers.dart
git commit -m "feat: add aviation data FutureProviders"
```

---

## Task 7: Navigation — 4th Map tab

**Files:**
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/shared/widgets/app_scaffold.dart`
- Modify: `lib/features/map_view/presentation/screens/map_screen.dart` (currentIndex fix only)
- Modify: `test/features/map_view/presentation/screens/map_screen_smoke_test.dart`

- [ ] **Step 7.1: Extend smoke test for 4-tab nav (write failing test first)**

Replace the content of `test/features/map_view/presentation/screens/map_screen_smoke_test.dart`:

```dart
import 'package:flight_assistant/features/aviation_data/application/providers/aviation_data_providers.dart';
import 'package:flight_assistant/features/aviation_data/application/providers/layer_visibility_provider.dart';
import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/map_view/presentation/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fakes.dart';
import '../../../../support/map_platform_mocks.dart';

void main() {
  setUpAll(installMapPlatformMocks);
  tearDownAll(removeMapPlatformMocks);

  final baseOverrides = [
    routeRepositoryProvider.overrideWithValue(TestRouteRepository()),
    loggerServiceProvider.overrideWithValue(CapturingLoggerService()),
    airportsProvider.overrideWith((ref) async => []),
    vfrPointsProvider.overrideWith((ref) async => []),
    airspacesProvider.overrideWith((ref) async => []),
  ];

  testWidgets('renders Map View title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Map View'), findsOneWidget);
  });

  testWidgets('navigation bar has 4 destinations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    // Plan, Map, Saved, Settings
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('renders layers icon button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
  });

  testWidgets('renders with waypoint data', (tester) async {
    final container = ProviderContainer(overrides: baseOverrides);
    addTearDown(container.dispose);
    container.read(flightPlanningControllerProvider.notifier).addWaypoint(
      name: 'EPWA',
      latitude: 52.1657,
      longitude: 20.9671,
      type: WaypointType.departure,
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Map View'), findsOneWidget);
  });
}
```

- [ ] **Step 7.2: Run test to confirm it fails**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter test test/features/map_view/presentation/screens/map_screen_smoke_test.dart
```

Expected: compilation error — MapScreen doesn't have the layers button yet. That's fine — we add it in Task 12. For now note the test will remain red until Task 12. Continue to next steps.

- [ ] **Step 7.3: Update app_router.dart — add /map route**

Replace the full content of `lib/app/router/app_router.dart`:

```dart
import 'package:flight_assistant/features/flight_planning/presentation/screens/flight_planning_screen.dart';
import 'package:flight_assistant/features/map_view/presentation/screens/map_screen.dart';
import 'package:flight_assistant/features/route_storage/presentation/screens/saved_routes_screen.dart';
import 'package:flight_assistant/features/settings/presentation/screens/settings_screen.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  static const String flightPlanning = '/planner';
  static const String map = '/map';
  static const String savedRoutes = '/saved-routes';
  static const String settings = '/settings';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.flightPlanning,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.flightPlanning,
      builder: (context, state) => const FlightPlanningScreen(),
    ),
    GoRoute(
      path: AppRoutes.map,
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: AppRoutes.savedRoutes,
      builder: (context, state) => const SavedRoutesScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
```

- [ ] **Step 7.4: Update app_scaffold.dart — add Map tab + bodyPadding param**

Replace the full content of `lib/shared/widgets/app_scaffold.dart`:

```dart
import 'package:flight_assistant/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    required this.currentIndex,
    super.key,
    this.floatingActionButton,
    this.bodyPadding = const EdgeInsets.all(16),
  });

  final String title;
  final Widget body;
  final int currentIndex;
  final Widget? floatingActionButton;
  final EdgeInsets bodyPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        minimum: bodyPadding,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onItemTap(context, index),
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.flight_outlined),
            selectedIcon: Icon(Icons.flight),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.save_outlined),
            selectedIcon: Icon(Icons.save),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _onItemTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.flightPlanning);
      case 1:
        context.go(AppRoutes.map);
      case 2:
        context.go(AppRoutes.savedRoutes);
      case 3:
        context.go(AppRoutes.settings);
    }
  }
}
```

- [ ] **Step 7.5: Fix currentIndex in map_screen.dart (from 0 to 1)**

The current `MapScreen` hardcodes `currentIndex: 0`. Fix this — Map is now at index 1. (Full MapScreen rewrite comes in Task 12; for now just fix the index so the app compiles correctly.)

In `lib/features/map_view/presentation/screens/map_screen.dart`, change `currentIndex: 0` to `currentIndex: 1`:

```dart
import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/flight_map_widget.dart';
import 'package:flight_assistant/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waypoints =
        ref.watch(flightPlanningControllerProvider).routePlan.waypoints;
    return AppScaffold(
      title: 'Map View',
      currentIndex: 1,
      body: FlightMapWidget(
        waypoints: waypoints,
        height: 420,
      ),
    );
  }
}
```

- [ ] **Step 7.6: Run flutter analyze and existing tests**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter analyze && flutter test --exclude-tags=needs_map_screen_update
```

If `--exclude-tags` is not available, just run `flutter test` and note the smoke test will fail (it expects 4 tabs and layers button not yet added). Check that all other tests pass.

Actually run without exclusion:
```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter analyze
```

Expected: no issues.

- [ ] **Step 7.7: Commit**

```bash
git add lib/app/router/app_router.dart \
        lib/shared/widgets/app_scaffold.dart \
        lib/features/map_view/presentation/screens/map_screen.dart \
        test/features/map_view/presentation/screens/map_screen_smoke_test.dart
git commit -m "feat: add Map as 4th navigation tab, add bodyPadding to AppScaffold"
```

---

## Task 8: AirportMarkerLayer and VfrPointMarkerLayer

**Files:**
- Create: `lib/features/map_view/presentation/widgets/airport_marker_layer.dart`
- Create: `lib/features/map_view/presentation/widgets/vfr_point_marker_layer.dart`

These are `Widget` classes (like `WaypointMarkerLayer`) that render markers inside `MapLibreMap.children`. They are display-only; tests that cover them run through `FlightMapWidget` smoke tests.

- [ ] **Step 8.1: Create airport_marker_layer.dart**

```dart
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class AirportMarkerLayer extends StatelessWidget {
  const AirportMarkerLayer({super.key, required this.airports});

  final List<Airport> airports;

  @override
  Widget build(BuildContext context) {
    if (airports.isEmpty) return const SizedBox.shrink();

    return WidgetLayer(
      markers: [
        for (final airport in airports)
          Marker(
            point: Geographic(lon: airport.longitude, lat: airport.latitude),
            size: const Size(28, 28),
            child: Tooltip(
              message: '${airport.name} (${airport.icaoCode})',
              child: const _AirportMarker(),
            ),
          ),
      ],
    );
  }
}

class _AirportMarker extends StatelessWidget {
  const _AirportMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0B5A8F),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.flight, color: Colors.white, size: 14),
      ),
    );
  }
}
```

- [ ] **Step 8.2: Create vfr_point_marker_layer.dart**

```dart
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class VfrPointMarkerLayer extends StatelessWidget {
  const VfrPointMarkerLayer({super.key, required this.vfrPoints});

  final List<VfrPoint> vfrPoints;

  @override
  Widget build(BuildContext context) {
    if (vfrPoints.isEmpty) return const SizedBox.shrink();

    return WidgetLayer(
      markers: [
        for (final point in vfrPoints)
          Marker(
            point: Geographic(lon: point.longitude, lat: point.latitude),
            size: const Size(36, 36),
            child: Tooltip(
              message: point.name,
              child: _VfrPointMarker(code: point.code),
            ),
          ),
      ],
    );
  }
}

class _VfrPointMarker extends StatelessWidget {
  const _VfrPointMarker({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE67E22),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          code,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 8,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 8.3: Run flutter analyze**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter analyze
```

Expected: no issues.

- [ ] **Step 8.4: Commit**

```bash
git add lib/features/map_view/presentation/widgets/airport_marker_layer.dart \
        lib/features/map_view/presentation/widgets/vfr_point_marker_layer.dart
git commit -m "feat: add AirportMarkerLayer and VfrPointMarkerLayer widgets"
```

---

## Task 9: AirspacePolygonLayer

**Files:**
- Create: `lib/features/map_view/presentation/widgets/airspace_polygon_layer.dart`

This follows the same static-factory pattern as `RoutePolylineLayer` — returns a `PolylineLayer` (a `Layer`, not a `Widget`) that goes in `FlightMapWidget._buildLayers()`.

- [ ] **Step 9.1: Create airspace_polygon_layer.dart**

```dart
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class AirspacePolygonLayer {
  const AirspacePolygonLayer._();

  /// Returns a [PolylineLayer] tracing all airspace boundaries, or null when
  /// the list is empty. Add the result to [MapLibreMap.layers].
  static PolylineLayer? fromAirspaces(List<Airspace> airspaces) {
    if (airspaces.isEmpty) return null;

    final polylines = <Feature<LineString>>[];
    for (final airspace in airspaces) {
      if (airspace.polygon.length < 2) continue;
      final coords = airspace.polygon
          .map((p) => Geographic(lon: p.$2, lat: p.$1))
          .toList(growable: false);
      polylines.add(Feature<LineString>(geometry: LineString.from(coords)));
    }

    if (polylines.isEmpty) return null;

    return PolylineLayer(
      polylines: polylines,
      color: const Color(0xFFDBA800), // amber — standard airspace colour
      width: 2,
    );
  }
}
```

- [ ] **Step 9.2: Run flutter analyze**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter analyze
```

Expected: no issues.

- [ ] **Step 9.3: Commit**

```bash
git add lib/features/map_view/presentation/widgets/airspace_polygon_layer.dart
git commit -m "feat: add AirspacePolygonLayer static helper"
```

---

## Task 10: MapControlsOverlay widget with TDD

**Files:**
- Create: `test/features/map_view/presentation/widgets/map_controls_overlay_test.dart`
- Create: `lib/features/map_view/presentation/widgets/map_controls_overlay.dart`

- [ ] **Step 10.1: Write failing widget tests**

Create `test/features/map_view/presentation/widgets/map_controls_overlay_test.dart`:

```dart
import 'package:flight_assistant/features/map_view/presentation/widgets/map_controls_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Stack(children: [child])),
    );

void main() {
  group('MapControlsOverlay', () {
    testWidgets('renders zoom in and zoom out buttons', (tester) async {
      await tester.pumpWidget(_wrap(MapControlsOverlay(
        onZoomIn: () {},
        onZoomOut: () {},
        onFitRoute: () {},
        onMyLocation: () {},
        onResetNorth: () {},
        showCompass: false,
      )));
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('renders fit route and my location buttons', (tester) async {
      await tester.pumpWidget(_wrap(MapControlsOverlay(
        onZoomIn: () {},
        onZoomOut: () {},
        onFitRoute: () {},
        onMyLocation: () {},
        onResetNorth: () {},
        showCompass: false,
      )));
      expect(find.byIcon(Icons.fit_screen), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('compass button shown when showCompass is true', (tester) async {
      await tester.pumpWidget(_wrap(MapControlsOverlay(
        onZoomIn: () {},
        onZoomOut: () {},
        onFitRoute: () {},
        onMyLocation: () {},
        onResetNorth: () {},
        showCompass: true,
      )));
      expect(find.byIcon(Icons.explore), findsOneWidget);
    });

    testWidgets('compass button hidden when showCompass is false',
        (tester) async {
      await tester.pumpWidget(_wrap(MapControlsOverlay(
        onZoomIn: () {},
        onZoomOut: () {},
        onFitRoute: () {},
        onMyLocation: () {},
        onResetNorth: () {},
        showCompass: false,
      )));
      expect(find.byIcon(Icons.explore), findsNothing);
    });

    testWidgets('zoom in callback fires on tap', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(MapControlsOverlay(
        onZoomIn: () => called = true,
        onZoomOut: () {},
        onFitRoute: () {},
        onMyLocation: () {},
        onResetNorth: () {},
        showCompass: false,
      )));
      await tester.tap(find.byIcon(Icons.add));
      expect(called, isTrue);
    });

    testWidgets('zoom out callback fires on tap', (tester) async {
      var called = false;
      await tester.pumpWidget(_wrap(MapControlsOverlay(
        onZoomIn: () {},
        onZoomOut: () => called = true,
        onFitRoute: () {},
        onMyLocation: () {},
        onResetNorth: () {},
        showCompass: false,
      )));
      await tester.tap(find.byIcon(Icons.remove));
      expect(called, isTrue);
    });
  });
}
```

- [ ] **Step 10.2: Run test to confirm it fails**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter test test/features/map_view/presentation/widgets/map_controls_overlay_test.dart
```

Expected: compilation error — `MapControlsOverlay` not found.

- [ ] **Step 10.3: Implement MapControlsOverlay**

Create `lib/features/map_view/presentation/widgets/map_controls_overlay.dart`:

```dart
import 'package:flutter/material.dart';

class MapControlsOverlay extends StatelessWidget {
  const MapControlsOverlay({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitRoute,
    required this.onMyLocation,
    required this.onResetNorth,
    required this.showCompass,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitRoute;
  final VoidCallback onMyLocation;
  final VoidCallback onResetNorth;
  final bool showCompass;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (showCompass)
          Positioned(
            top: 12,
            left: 12,
            child: _MapButton(
              onPressed: onResetNorth,
              child: const Icon(Icons.explore, size: 20),
            ),
          ),
        Positioned(
          bottom: 16,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MapButton(
                onPressed: onFitRoute,
                child: const Icon(Icons.fit_screen, size: 20),
              ),
              const SizedBox(height: 6),
              _MapButton(
                onPressed: onMyLocation,
                child: const Icon(Icons.my_location, size: 20),
              ),
              const SizedBox(height: 6),
              _MapButton(
                onPressed: onZoomIn,
                child: const Icon(Icons.add, size: 20),
              ),
              const SizedBox(height: 2),
              _MapButton(
                onPressed: onZoomOut,
                child: const Icon(Icons.remove, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.55),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: IconTheme(
            data: const IconThemeData(color: Colors.white),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 10.4: Run tests to confirm they pass**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter test test/features/map_view/presentation/widgets/map_controls_overlay_test.dart
```

Expected: all 6 tests PASS.

- [ ] **Step 10.5: Commit**

```bash
git add lib/features/map_view/presentation/widgets/map_controls_overlay.dart \
        test/features/map_view/presentation/widgets/map_controls_overlay_test.dart
git commit -m "feat: add MapControlsOverlay widget (TDD)"
```

---

## Task 11: Extend FlightMapWidget with aviation layers and controls

**Files:**
- Modify: `lib/features/map_view/presentation/widgets/flight_map_widget.dart`

- [ ] **Step 11.1: Replace flight_map_widget.dart**

```dart
import 'package:flight_assistant/features/aviation_data/application/providers/layer_visibility_provider.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/airport_marker_layer.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/airspace_polygon_layer.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/map_controls_overlay.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/route_polyline_layer.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/vfr_point_marker_layer.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/waypoint_marker_layer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre/maplibre.dart';

class FlightMapWidget extends StatefulWidget {
  const FlightMapWidget({
    required this.waypoints,
    super.key,
    this.height = 220,
    this.airports = const [],
    this.vfrPoints = const [],
    this.airspaces = const [],
    this.layerVisibility = const LayerVisibility(),
    this.showControls = false,
  });

  final List<Waypoint> waypoints;
  final double height;
  final List<Airport> airports;
  final List<VfrPoint> vfrPoints;
  final List<Airspace> airspaces;
  final LayerVisibility layerVisibility;
  final bool showControls;

  @override
  State<FlightMapWidget> createState() => _FlightMapWidgetState();
}

class _FlightMapWidgetState extends State<FlightMapWidget> {
  static const Geographic _fallbackCenter = Geographic(lon: 21.0122, lat: 52.2297);
  static const EdgeInsets _cameraPadding = EdgeInsets.all(36);

  MapController? _mapController;
  bool _styleLoaded = false;
  double _currentZoom = 8.0;
  bool _showCompass = false;

  @override
  void didUpdateWidget(covariant FlightMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_didWaypointsChange(oldWidget.waypoints, widget.waypoints)) {
      _fitCameraToRoute(animated: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showMap = widget.showControls || widget.waypoints.isNotEmpty;

    return Card(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: !showMap
              ? _MapEmptyState(height: widget.height)
              : !_isMapLibreSupported
                  ? const _MapUnsupportedFallback()
                  : Stack(
                      children: [
                        MapLibreMap(
                          options: MapOptions(
                            initCenter: _initialCenter(widget.waypoints),
                            initZoom: widget.waypoints.length > 1 ? 5 : 8,
                          ),
                          layers: _buildLayers(),
                          onMapCreated: _onMapCreated,
                          onStyleLoaded: (_) {
                            _styleLoaded = true;
                            _fitCameraToRoute(animated: false);
                          },
                          children: _buildChildren(),
                        ),
                        if (widget.showControls)
                          MapControlsOverlay(
                            onZoomIn: _zoomIn,
                            onZoomOut: _zoomOut,
                            onFitRoute: () => _fitCameraToRoute(animated: true),
                            onMyLocation: _goToMyLocation,
                            onResetNorth: _resetNorth,
                            showCompass: _showCompass,
                          ),
                      ],
                    ),
        ),
      ),
    );
  }

  bool get _isMapLibreSupported {
    return kIsWeb ||
        MapController.userLocationIsSupported ||
        PermissionManager.isSupported ||
        OfflineManager.isSupported;
  }

  Geographic _initialCenter(List<Waypoint> waypoints) {
    if (waypoints.isEmpty) return _fallbackCenter;
    final first = waypoints.first;
    return Geographic(lon: first.longitude, lat: first.latitude);
  }

  List<Layer> _buildLayers() {
    final layers = <Layer>[];
    final routeLayer = RoutePolylineLayer.fromWaypoints(widget.waypoints);
    if (routeLayer != null) layers.add(routeLayer);
    if (widget.layerVisibility.showAirspaces) {
      final airspaceLayer = AirspacePolygonLayer.fromAirspaces(widget.airspaces);
      if (airspaceLayer != null) layers.add(airspaceLayer);
    }
    return layers;
  }

  List<Widget> _buildChildren() {
    return [
      WaypointMarkerLayer(waypoints: widget.waypoints),
      if (widget.layerVisibility.showAirports)
        AirportMarkerLayer(airports: widget.airports),
      if (widget.layerVisibility.showVfrPoints)
        VfrPointMarkerLayer(vfrPoints: widget.vfrPoints),
    ];
  }

  void _onMapCreated(MapController controller) {
    _mapController = controller;
    _fitCameraToRoute(animated: false);
  }

  Future<void> _fitCameraToRoute({required bool animated}) async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded || widget.waypoints.isEmpty) return;

    final points = widget.waypoints
        .map((w) => Geographic(lon: w.longitude, lat: w.latitude))
        .toList(growable: false);

    if (points.length == 1) {
      final point = points.first;
      _currentZoom = 9;
      if (animated) {
        await controller.animateCamera(
          center: point,
          zoom: _currentZoom,
          nativeDuration: const Duration(milliseconds: 600),
          padding: _cameraPadding,
        );
      } else {
        await controller.moveCamera(
          center: point,
          zoom: _currentZoom,
          padding: _cameraPadding,
        );
      }
      return;
    }

    final rawBounds = LngLatBounds.fromPoints(points);
    final bounds = _expandSmallBounds(rawBounds);
    await controller.fitBounds(
      bounds: bounds,
      nativeDuration: animated ? const Duration(milliseconds: 750) : Duration.zero,
      padding: _cameraPadding,
      webMaxZoom: 12,
    );
  }

  Future<void> _zoomIn() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;
    _currentZoom = (_currentZoom + 1.0).clamp(0.0, 22.0);
    await controller.animateCamera(
      zoom: _currentZoom,
      nativeDuration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _zoomOut() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;
    _currentZoom = (_currentZoom - 1.0).clamp(0.0, 22.0);
    await controller.animateCamera(
      zoom: _currentZoom,
      nativeDuration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _resetNorth() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;
    setState(() => _showCompass = false);
    await controller.animateCamera(
      bearing: 0,
      nativeDuration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _goToMyLocation() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied. Enable it in Settings.'),
          ),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      _currentZoom = 12;
      await controller.animateCamera(
        center: Geographic(lon: position.longitude, lat: position.latitude),
        zoom: _currentZoom,
        nativeDuration: const Duration(milliseconds: 600),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get current location.')),
        );
      }
    }
  }

  LngLatBounds _expandSmallBounds(LngLatBounds bounds) {
    const minimumSpan = 0.02;
    final lonSpan = (bounds.longitudeEast - bounds.longitudeWest).abs();
    final latSpan = (bounds.latitudeNorth - bounds.latitudeSouth).abs();
    final lonPadding = lonSpan < minimumSpan ? (minimumSpan - lonSpan) / 2 : 0.0;
    final latPadding = latSpan < minimumSpan ? (minimumSpan - latSpan) / 2 : 0.0;
    return bounds.copyWith(
      longitudeWest: bounds.longitudeWest - lonPadding,
      longitudeEast: bounds.longitudeEast + lonPadding,
      latitudeSouth: bounds.latitudeSouth - latPadding,
      latitudeNorth: bounds.latitudeNorth + latPadding,
    );
  }

  bool _didWaypointsChange(List<Waypoint> oldList, List<Waypoint> newList) {
    if (identical(oldList, newList)) return false;
    if (oldList.length != newList.length) return true;
    for (var i = 0; i < oldList.length; i++) {
      final o = oldList[i];
      final n = newList[i];
      if (o.id != n.id || o.latitude != n.latitude || o.longitude != n.longitude) {
        return true;
      }
    }
    return false;
  }
}

class _MapUnsupportedFallback extends StatelessWidget {
  const _MapUnsupportedFallback();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFDCEAF5),
      child: const Center(
        child: Icon(Icons.map_outlined, size: 40, color: Color(0xFF0B5A8F)),
      ),
    );
  }
}

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: const Color(0xFFE9F1F7),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 34, color: Color(0xFF0B5A8F)),
            const SizedBox(height: 8),
            Text(
              'Add at least one waypoint to display the map.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 11.2: Run flutter analyze**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter analyze
```

Expected: no issues. Note: `bearing` is a named parameter on `MapController.animateCamera` in maplibre ^0.3.5. If the analyzer reports it as unknown, check the maplibre changelog — the parameter may be named `rotation` in that version. Adjust `_resetNorth` accordingly.

- [ ] **Step 11.3: Commit**

```bash
git add lib/features/map_view/presentation/widgets/flight_map_widget.dart
git commit -m "feat: extend FlightMapWidget with aviation layers, controls overlay, and My Location"
```

---

## Task 12: MapScreen — full rewrite with layers bottom sheet

**Files:**
- Modify: `lib/features/map_view/presentation/screens/map_screen.dart`
- Create: `test/features/map_view/presentation/screens/map_screen_layers_test.dart`

- [ ] **Step 12.1: Write failing layers bottom sheet tests**

Create `test/features/map_view/presentation/screens/map_screen_layers_test.dart`:

```dart
import 'package:flight_assistant/features/aviation_data/application/providers/aviation_data_providers.dart';
import 'package:flight_assistant/features/aviation_data/application/providers/layer_visibility_provider.dart';
import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/map_view/presentation/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fakes.dart';
import '../../../../support/map_platform_mocks.dart';

void main() {
  setUpAll(installMapPlatformMocks);
  tearDownAll(removeMapPlatformMocks);

  final baseOverrides = [
    routeRepositoryProvider.overrideWithValue(TestRouteRepository()),
    loggerServiceProvider.overrideWithValue(CapturingLoggerService()),
    airportsProvider.overrideWith((ref) async => []),
    vfrPointsProvider.overrideWith((ref) async => []),
    airspacesProvider.overrideWith((ref) async => []),
  ];

  testWidgets('tapping layers button opens bottom sheet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Map Layers'), findsOneWidget);
    expect(find.text('Airports'), findsOneWidget);
    expect(find.text('VFR Reporting Points'), findsOneWidget);
    expect(find.text('Airspaces'), findsOneWidget);
  });

  testWidgets('toggling Airports switch updates layerVisibilityProvider',
      (tester) async {
    final container = ProviderContainer(overrides: baseOverrides);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Open layers sheet
    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();

    expect(container.read(layerVisibilityProvider).showAirports, isTrue);

    // Tap the first Switch (Airports row)
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(container.read(layerVisibilityProvider).showAirports, isFalse);
  });

  testWidgets('toggling Airspaces switch updates layerVisibilityProvider',
      (tester) async {
    final container = ProviderContainer(overrides: baseOverrides);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();

    expect(container.read(layerVisibilityProvider).showAirspaces, isTrue);

    // Third Switch = Airspaces
    await tester.tap(find.byType(Switch).at(2));
    await tester.pumpAndSettle();

    expect(container.read(layerVisibilityProvider).showAirspaces, isFalse);
  });
}
```

- [ ] **Step 12.2: Run test to confirm it fails**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter test test/features/map_view/presentation/screens/map_screen_layers_test.dart
```

Expected: FAIL — `MapScreen` has no layers button yet.

- [ ] **Step 12.3: Rewrite map_screen.dart**

```dart
import 'package:flight_assistant/features/aviation_data/application/providers/aviation_data_providers.dart';
import 'package:flight_assistant/features/aviation_data/application/providers/layer_visibility_provider.dart';
import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/flight_map_widget.dart';
import 'package:flight_assistant/shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waypoints =
        ref.watch(flightPlanningControllerProvider).routePlan.waypoints;
    final layerVisibility = ref.watch(layerVisibilityProvider);
    final airports = ref.watch(airportsProvider).valueOrNull ?? [];
    final vfrPoints = ref.watch(vfrPointsProvider).valueOrNull ?? [];
    final airspaces = ref.watch(airspacesProvider).valueOrNull ?? [];

    return AppScaffold(
      title: 'Map View',
      currentIndex: 1,
      bodyPadding: EdgeInsets.zero,
      actions: [
        IconButton(
          icon: const Icon(Icons.layers_outlined),
          tooltip: 'Layers',
          onPressed: () => _showLayersSheet(context),
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) => FlightMapWidget(
          waypoints: waypoints,
          airports: airports,
          vfrPoints: vfrPoints,
          airspaces: airspaces,
          layerVisibility: layerVisibility,
          showControls: true,
          height: constraints.maxHeight,
        ),
      ),
    );
  }

  void _showLayersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      // _LayersBottomSheet is a ConsumerWidget so it reads providers itself.
      // Never pass WidgetRef into a bottom sheet builder — ref is only valid
      // during the parent's build call.
      builder: (_) => const _LayersBottomSheet(),
    );
  }
}

class _LayersBottomSheet extends ConsumerWidget {
  const _LayersBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibility = ref.watch(layerVisibilityProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Map Layers',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: const Icon(Icons.flight),
            title: const Text('Airports'),
            subtitle: const Text('Licensed fields, grass strips, heliports'),
            value: visibility.showAirports,
            onChanged: (v) => ref
                .read(layerVisibilityProvider.notifier)
                .state = visibility.copyWith(showAirports: v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.place_outlined),
            title: const Text('VFR Reporting Points'),
            subtitle: const Text('CTR entry/exit points (LIMA, PAPA…)'),
            value: visibility.showVfrPoints,
            onChanged: (v) => ref
                .read(layerVisibilityProvider.notifier)
                .state = visibility.copyWith(showVfrPoints: v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.layers_outlined),
            title: const Text('Airspaces'),
            subtitle: const Text('CTR, TMA, MCTR boundaries'),
            value: visibility.showAirspaces,
            onChanged: (v) => ref
                .read(layerVisibilityProvider.notifier)
                .state = visibility.copyWith(showAirspaces: v),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 12.4: Add `actions` parameter to AppScaffold**

`AppScaffold` needs to forward `actions` to its `AppBar`. Open `lib/shared/widgets/app_scaffold.dart` and add the `actions` param:

```dart
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.title,
    required this.body,
    required this.currentIndex,
    super.key,
    this.floatingActionButton,
    this.bodyPadding = const EdgeInsets.all(16),
    this.actions,                          // <-- ADD
  });

  final String title;
  final Widget body;
  final int currentIndex;
  final Widget? floatingActionButton;
  final EdgeInsets bodyPadding;
  final List<Widget>? actions;             // <-- ADD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,                  // <-- ADD
      ),
      body: SafeArea(
        minimum: bodyPadding,
        child: body,
      ),
      ...
    );
  }
```

- [ ] **Step 12.5: Run flutter analyze**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter analyze
```

Expected: no issues.

- [ ] **Step 12.6: Run layer tests**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter test test/features/map_view/presentation/screens/
```

Expected: all map screen tests PASS (layers test + smoke test).

- [ ] **Step 12.7: Commit**

```bash
git add lib/features/map_view/presentation/screens/map_screen.dart \
        lib/shared/widgets/app_scaffold.dart \
        test/features/map_view/presentation/screens/map_screen_layers_test.dart
git commit -m "feat: add aviation layer toggles bottom sheet and provider wiring to MapScreen"
```

---

## Task 13: Final verification

- [ ] **Step 13.1: Run full test suite**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter test --reporter expanded
```

Expected: all tests PASS. Total should be approximately 51+ (28 existing + ~23 new).

- [ ] **Step 13.2: Run static analyzer**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 13.3: Build iOS to confirm no compile errors**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter build ios --simulator --no-codesign
```

Expected: `Build complete.`

- [ ] **Step 13.4: Manual smoke test on iOS Simulator**

```bash
cd /Users/przemek/LearningProjects/FlightAssistant && flutter run -d "iPhone 17"
```

Verify manually:
- [ ] Bottom nav has 4 tabs: Plan / Map / Saved / Settings
- [ ] Tapping Map tab opens the MapScreen with MapLibre map
- [ ] Tapping the layers button opens the bottom sheet with 3 toggles
- [ ] Toggling a layer switch hides/shows the layer on the map
- [ ] Zoom +/− buttons change the map zoom
- [ ] Fit Route button fits the camera to the current route
- [ ] My Location button requests permission on first tap
- [ ] Plan tab still works as before

- [ ] **Step 13.5: Update development journal**

Add a new entry to `docs/development-journal.md` for Iteration 8 following the existing format: scope delivered, decisions, verification results, time tracking (wall-clock start/end, team effort per role).

- [ ] **Step 13.6: Final commit**

```bash
git add docs/development-journal.md
git commit -m "docs: update development journal for iteration 8 (map enhancements)"
```
