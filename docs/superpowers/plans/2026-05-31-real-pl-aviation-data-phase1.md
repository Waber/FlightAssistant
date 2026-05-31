# Real PL Aviation Data (Phase 1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Iteration 8 sample aviation data with real Polish VFR data from OpenAIP, bundled offline, behind a repository seam, with a Python conversion pipeline and a hardened loader.

**Architecture:** A dev-side Python script fetches OpenAIP PL data and writes committed `assets/*.geojson` + a metadata file. The Flutter app reads those assets through a hardened `AviationDataLoader`, wrapped by a `BundledAviationDataSource` implementing a new `AviationDataRepository`. Riverpod providers read the repository; `MapScreen` shows loading/error states and a "data as of" label. Phase 2 (runtime refresh + cache + user API key) plugs new sources behind the same repository.

**Tech Stack:** Flutter/Dart, Riverpod, MapLibre; Python 3 + `requests` for the pipeline; `pytest` for pipeline tests; `flutter_test` for Dart tests.

**Reference spec:** `docs/superpowers/specs/2026-05-31-real-pl-aviation-data-design.md`

---

## File Structure

**Dart (app):**
- Modify `lib/features/aviation_data/domain/entities/airspace.dart` — extend `AirspaceType`.
- Create `lib/features/aviation_data/domain/entities/aviation_data_meta.dart` — provenance entity.
- Modify `lib/features/aviation_data/data/datasources/aviation_data_loader.dart` — per-feature isolation, MultiPolygon, extended mapping, meta parsing.
- Create `lib/features/aviation_data/domain/repositories/aviation_data_repository.dart` — abstract repository.
- Create `lib/features/aviation_data/data/repositories/bundled_aviation_data_source.dart` — Phase 1 impl.
- Modify `lib/features/aviation_data/application/providers/aviation_data_providers.dart` — repository provider + meta provider.
- Modify `lib/features/map_view/presentation/screens/map_screen.dart` — `.when()` UX + data-as-of label.
- Create `assets/aviation_data/aviation_data_meta.json` — provenance asset.
- Modify `pubspec.yaml` — register the meta asset.

**Python (dev-side, not shipped):**
- Create `tool/aviation_data/mapping.py` — pure OpenAIP→app-GeoJSON mapping.
- Create `tool/aviation_data/fetch.py` — network fetch + orchestration + file writing.
- Create `tool/aviation_data/requirements.txt`.
- Create `tool/aviation_data/README.md`.
- Create `tool/aviation_data/tests/test_mapping.py` + `tool/aviation_data/tests/fixtures/openaip_sample.json`.

**Tests (Dart):**
- Modify `test/features/aviation_data/data/airspace_parser_test.dart`.
- Create `test/features/aviation_data/data/parser_error_isolation_test.dart`.
- Create `test/features/aviation_data/data/aviation_data_meta_test.dart`.
- Create `test/features/aviation_data/data/bundled_aviation_data_source_test.dart`.
- Create `test/features/map_view/presentation/screens/map_screen_states_test.dart`.

---

## Task 1: Extend `AirspaceType` and map new types in the loader

**Files:**
- Modify: `lib/features/aviation_data/domain/entities/airspace.dart`
- Modify: `lib/features/aviation_data/data/datasources/aviation_data_loader.dart`
- Test: `test/features/aviation_data/data/airspace_parser_test.dart`

- [ ] **Step 1: Add failing tests for new airspace types**

Append inside the existing `group('AviationDataLoader.parseAirspaces', ...)` in `airspace_parser_test.dart`:

```dart
    test('maps extended airspace types', () {
      const json = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"D1","name":"Danger 1","type":"danger","class":"G","ceiling":"FL095","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"A1","name":"ATZ 1","type":"atz","class":"G","ceiling":"2000ft","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"X1","name":"Unknown","type":"weird","class":"G","ceiling":"FL095","floor":"GND"}}
]}''';
      final result = AviationDataLoader.parseAirspaces(json);
      expect(result.map((a) => a.type), [
        AirspaceType.danger,
        AirspaceType.atz,
        AirspaceType.other, // unknown maps to other, record kept
      ]);
    });
```

- [ ] **Step 2: Run the test, verify it fails**

Run: `flutter test test/features/aviation_data/data/airspace_parser_test.dart`
Expected: FAIL — `danger`/`atz` are not members of `AirspaceType`.

- [ ] **Step 3: Extend the enum**

In `lib/features/aviation_data/domain/entities/airspace.dart`, replace the enum line:

```dart
enum AirspaceType {
  ctr,
  tma,
  mctr,
  atz,
  danger,
  restricted,
  prohibited,
  tsa,
  tra,
  rmz,
  tmz,
  other,
}
```

- [ ] **Step 4: Extend the mapping**

In `aviation_data_loader.dart`, replace `_parseAirspaceType` with:

```dart
  static AirspaceType _parseAirspaceType(String value) => switch (value) {
        'ctr' => AirspaceType.ctr,
        'tma' => AirspaceType.tma,
        'mctr' => AirspaceType.mctr,
        'atz' => AirspaceType.atz,
        'danger' => AirspaceType.danger,
        'restricted' => AirspaceType.restricted,
        'prohibited' => AirspaceType.prohibited,
        'tsa' => AirspaceType.tsa,
        'tra' => AirspaceType.tra,
        'rmz' => AirspaceType.rmz,
        'tmz' => AirspaceType.tmz,
        _ => AirspaceType.other,
      };
```

- [ ] **Step 5: Run tests, verify pass**

Run: `flutter test test/features/aviation_data/data/airspace_parser_test.dart`
Expected: PASS (all tests, including the existing ones).

- [ ] **Step 6: Commit**

```bash
git add lib/features/aviation_data/domain/entities/airspace.dart \
        lib/features/aviation_data/data/datasources/aviation_data_loader.dart \
        test/features/aviation_data/data/airspace_parser_test.dart
git commit -m "feat(aviation): extend AirspaceType with VFR-relevant types"
```

---

## Task 2: Per-feature error isolation in all three parsers

**Why:** Today each `parse*` does one `try/catch` around the whole `.map(...)`, so a single malformed feature drops the entire layer. Switch to per-feature isolation: skip + log the bad one, keep the rest. Malformed top-level JSON still returns `[]`.

**Files:**
- Modify: `lib/features/aviation_data/data/datasources/aviation_data_loader.dart`
- Test: `test/features/aviation_data/data/parser_error_isolation_test.dart` (create)

- [ ] **Step 1: Write failing tests**

Create `test/features/aviation_data/data/parser_error_isolation_test.dart`:

```dart
import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('per-feature error isolation', () {
    test('parseAirports keeps good features, skips a malformed one', () {
      const json = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"Point","coordinates":[20.0,52.0]},
  "properties":{"id":"EPWA","name":"Warszawa","icao":"EPWA","type":"licensed"}},
 {"type":"Feature","geometry":{"type":"Point","coordinates":[19.0,51.0]},
  "properties":{"id":"BAD","name":"No ICAO key here","type":"grass"}},
 {"type":"Feature","geometry":{"type":"Point","coordinates":[18.0,54.0]},
  "properties":{"id":"EPGD","name":"Gdansk","icao":"EPGD","type":"licensed"}}
]}''';
      final result = AviationDataLoader.parseAirports(json);
      expect(result.map((a) => a.id), ['EPWA', 'EPGD']);
    });

    test('parseVfrPoints keeps good features, skips a malformed one', () {
      const json = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"Point","coordinates":[20.0,52.0]},
  "properties":{"id":"L","name":"Lima","code":"LIMA"}},
 {"type":"Feature","geometry":{"type":"Point","coordinates":[19.0,51.0]},
  "properties":{"id":"BAD","name":"missing code"}}
]}''';
      final result = AviationDataLoader.parseVfrPoints(json);
      expect(result.map((v) => v.id), ['L']);
    });

    test('parseAirspaces keeps good features, skips a malformed one', () {
      const json = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"OK","name":"Ok","type":"ctr","class":"D","ceiling":"FL095","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0]]]},
  "properties":{"id":"BAD","name":"missing class","type":"ctr","ceiling":"FL095","floor":"GND"}}
]}''';
      final result = AviationDataLoader.parseAirspaces(json);
      expect(result.map((a) => a.id), ['OK']);
    });

    test('malformed top-level JSON still returns empty', () {
      expect(AviationDataLoader.parseAirports('not json'), isEmpty);
      expect(AviationDataLoader.parseVfrPoints('not json'), isEmpty);
      expect(AviationDataLoader.parseAirspaces('not json'), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run, verify it fails**

Run: `flutter test test/features/aviation_data/data/parser_error_isolation_test.dart`
Expected: FAIL — current code throws inside `.map`, the whole list becomes `[]`, so `['EPWA','EPGD']` is not returned.

- [ ] **Step 3: Refactor the three parsers to isolate per feature**

In `aviation_data_loader.dart`, replace the three `parse*` methods with the versions below. Keep the existing imports. (Note: `parseAirspaces` here still handles only `Polygon`; MultiPolygon is added in Task 3.)

```dart
  static List<Airport> parseAirports(String jsonString) {
    return _parseFeatures(jsonString, 'parseAirports', (f) {
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
    });
  }

  static List<VfrPoint> parseVfrPoints(String jsonString) {
    return _parseFeatures(jsonString, 'parseVfrPoints', (f) {
      final props = f['properties'] as Map<String, dynamic>;
      final coords = f['geometry']['coordinates'] as List<dynamic>;
      return VfrPoint(
        id: props['id'] as String,
        name: props['name'] as String,
        code: props['code'] as String,
        latitude: (coords[1] as num).toDouble(),
        longitude: (coords[0] as num).toDouble(),
      );
    });
  }

  static List<Airspace> parseAirspaces(String jsonString) {
    return _parseFeatures(jsonString, 'parseAirspaces', (f) {
      final props = f['properties'] as Map<String, dynamic>;
      final rawRing =
          (f['geometry']['coordinates'] as List<dynamic>)[0] as List<dynamic>;
      return Airspace(
        id: props['id'] as String,
        name: props['name'] as String,
        type: _parseAirspaceType(props['type'] as String),
        airspaceClass: props['class'] as String,
        ceiling: props['ceiling'] as String,
        floor: props['floor'] as String,
        polygon: _ring(rawRing),
      );
    });
  }

  /// Decodes a FeatureCollection and maps each feature with [build], isolating
  /// per-feature failures: a bad feature is skipped + logged, the rest are kept.
  /// Malformed top-level JSON returns an empty list.
  static List<T> _parseFeatures<T>(
    String jsonString,
    String op,
    T Function(Map<String, dynamic> feature) build,
  ) {
    final List<dynamic> features;
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      features = map['features'] as List<dynamic>;
    } catch (e, st) {
      developer.log('$op failed (top-level)',
          name: 'AviationDataLoader', error: e, stackTrace: st);
      return [];
    }
    final result = <T>[];
    for (final f in features) {
      try {
        result.add(build(f as Map<String, dynamic>));
      } catch (e, st) {
        developer.log('$op skipped a feature',
            name: 'AviationDataLoader', error: e, stackTrace: st);
      }
    }
    return result;
  }

  static List<(double, double)> _ring(List<dynamic> rawRing) {
    return rawRing.map((c) {
      final coord = c as List<dynamic>;
      // GeoJSON uses [lon, lat]; convert to (lat, lon) record.
      return ((coord[1] as num).toDouble(), (coord[0] as num).toDouble());
    }).toList();
  }
```

- [ ] **Step 4: Run, verify pass**

Run: `flutter test test/features/aviation_data/data/`
Expected: PASS (new isolation tests + all existing parser tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/aviation_data/data/datasources/aviation_data_loader.dart \
        test/features/aviation_data/data/parser_error_isolation_test.dart
git commit -m "feat(aviation): per-feature error isolation in parsers"
```

---

## Task 3: MultiPolygon support in `parseAirspaces`

**Why:** Real OpenAIP airspaces use `Polygon` and `MultiPolygon`. Today MultiPolygon is silently dropped. Expand a MultiPolygon into N `Airspace` records (one per polygon's outer ring), each sharing the feature's properties. Keeps `Airspace.polygon` unchanged.

**Files:**
- Modify: `lib/features/aviation_data/data/datasources/aviation_data_loader.dart`
- Test: `test/features/aviation_data/data/airspace_parser_test.dart`

- [ ] **Step 1: Add failing tests**

Append inside the `group('AviationDataLoader.parseAirspaces', ...)`:

```dart
    test('explodes MultiPolygon into one Airspace per polygon', () {
      const json = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"MultiPolygon","coordinates":[
   [[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]],
   [[[22.0,53.0],[22.1,53.0],[22.1,53.1],[22.0,53.0]]]
 ]},
  "properties":{"id":"R1","name":"Restricted 1","type":"restricted","class":"G","ceiling":"FL095","floor":"GND"}}
]}''';
      final result = AviationDataLoader.parseAirspaces(json);
      expect(result.length, 2);
      expect(result.every((a) => a.id == 'R1'), isTrue);
      expect(result.every((a) => a.type == AirspaceType.restricted), isTrue);
      expect(result[0].polygon.first.$1, closeTo(51.0, 0.0001));
      expect(result[1].polygon.first.$1, closeTo(53.0, 0.0001));
    });
```

- [ ] **Step 2: Run, verify it fails**

Run: `flutter test test/features/aviation_data/data/airspace_parser_test.dart`
Expected: FAIL — current code reads `coordinates[0]` as a ring, mis-parsing MultiPolygon (wrong count / throws → skipped → length 0).

- [ ] **Step 3: Implement MultiPolygon handling**

In `aviation_data_loader.dart`, the per-feature `build` for airspaces must be able to yield multiple records. Replace `parseAirspaces` with a version that flat-maps, and add a `_buildAirspaces` helper:

```dart
  static List<Airspace> parseAirspaces(String jsonString) {
    final groups = _parseFeatures(jsonString, 'parseAirspaces', _buildAirspaces);
    return groups.expand((g) => g).toList();
  }

  /// Builds one Airspace per polygon. `Polygon` -> 1 record; `MultiPolygon` -> N.
  static List<Airspace> _buildAirspaces(Map<String, dynamic> f) {
    final props = f['properties'] as Map<String, dynamic>;
    final geometry = f['geometry'] as Map<String, dynamic>;
    final geomType = geometry['type'] as String;
    final coords = geometry['coordinates'] as List<dynamic>;

    final List<List<dynamic>> rings; // each = outer ring of one polygon
    if (geomType == 'MultiPolygon') {
      rings = coords
          .map((polygon) => (polygon as List<dynamic>)[0] as List<dynamic>)
          .toList();
    } else {
      // Polygon: coordinates[0] is the outer ring.
      rings = [coords[0] as List<dynamic>];
    }

    final type = _parseAirspaceType(props['type'] as String);
    final id = props['id'] as String;
    final name = props['name'] as String;
    final airspaceClass = props['class'] as String;
    final ceiling = props['ceiling'] as String;
    final floor = props['floor'] as String;

    return rings
        .map((ring) => Airspace(
              id: id,
              name: name,
              type: type,
              airspaceClass: airspaceClass,
              ceiling: ceiling,
              floor: floor,
              polygon: _ring(ring),
            ))
        .toList();
  }
```

Note: `_parseFeatures` now returns `List<List<Airspace>>` for this call; `parseAirspaces` flattens with `.expand`. The previous single-record airspace branch from Task 2 is replaced by `_buildAirspaces`.

- [ ] **Step 4: Run, verify pass**

Run: `flutter test test/features/aviation_data/data/`
Expected: PASS (MultiPolygon explode + Polygon still 1 record + error isolation + extended types).

- [ ] **Step 5: Commit**

```bash
git add lib/features/aviation_data/data/datasources/aviation_data_loader.dart \
        test/features/aviation_data/data/airspace_parser_test.dart
git commit -m "feat(aviation): expand MultiPolygon airspaces into per-polygon records"
```

---

## Task 4: `AviationDataMeta` entity + parser + asset

**Files:**
- Create: `lib/features/aviation_data/domain/entities/aviation_data_meta.dart`
- Modify: `lib/features/aviation_data/data/datasources/aviation_data_loader.dart`
- Create: `assets/aviation_data/aviation_data_meta.json`
- Modify: `pubspec.yaml`
- Test: `test/features/aviation_data/data/aviation_data_meta_test.dart` (create)

- [ ] **Step 1: Create the entity**

Create `lib/features/aviation_data/domain/entities/aviation_data_meta.dart`:

```dart
class AviationDataMeta {
  const AviationDataMeta({
    required this.source,
    required this.license,
    required this.generatedAt,
    required this.dataAsOf,
    required this.airportCount,
    required this.vfrPointCount,
    required this.airspaceCount,
  });

  final String source;
  final String license;
  final String generatedAt; // ISO date, e.g. "2026-05-31"
  final String dataAsOf; // ISO date the source data is current as of
  final int airportCount;
  final int vfrPointCount;
  final int airspaceCount;
}
```

- [ ] **Step 2: Write failing test**

Create `test/features/aviation_data/data/aviation_data_meta_test.dart`:

```dart
import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AviationDataLoader.parseMeta', () {
    test('parses metadata fields', () {
      const json = '''
{"source":"OpenAIP","license":"CC BY-NC-SA 4.0","generatedAt":"2026-05-31",
 "dataAsOf":"2026-05-29","counts":{"airports":123,"vfrPoints":200,"airspaces":80}}''';
      final meta = AviationDataLoader.parseMeta(json);
      expect(meta, isNotNull);
      expect(meta!.source, 'OpenAIP');
      expect(meta.dataAsOf, '2026-05-29');
      expect(meta.airportCount, 123);
      expect(meta.airspaceCount, 80);
    });

    test('returns null for malformed JSON', () {
      expect(AviationDataLoader.parseMeta('not json'), isNull);
    });
  });
}
```

- [ ] **Step 3: Run, verify fails**

Run: `flutter test test/features/aviation_data/data/aviation_data_meta_test.dart`
Expected: FAIL — `parseMeta` not defined.

- [ ] **Step 4: Add `parseMeta` + `loadMeta` to the loader**

Add the import at the top of `aviation_data_loader.dart`:

```dart
import 'package:flight_assistant/features/aviation_data/domain/entities/aviation_data_meta.dart';
```

Add these methods to the `AviationDataLoader` class:

```dart
  static Future<AviationDataMeta?> loadMeta() async {
    final raw = await rootBundle.loadString(
      'assets/aviation_data/aviation_data_meta.json',
    );
    return parseMeta(raw);
  }

  static AviationDataMeta? parseMeta(String jsonString) {
    try {
      final map = json.decode(jsonString) as Map<String, dynamic>;
      final counts = map['counts'] as Map<String, dynamic>;
      return AviationDataMeta(
        source: map['source'] as String,
        license: map['license'] as String,
        generatedAt: map['generatedAt'] as String,
        dataAsOf: map['dataAsOf'] as String,
        airportCount: (counts['airports'] as num).toInt(),
        vfrPointCount: (counts['vfrPoints'] as num).toInt(),
        airspaceCount: (counts['airspaces'] as num).toInt(),
      );
    } catch (e, st) {
      developer.log('parseMeta failed',
          name: 'AviationDataLoader', error: e, stackTrace: st);
      return null;
    }
  }
```

- [ ] **Step 5: Create the asset**

Create `assets/aviation_data/aviation_data_meta.json` (placeholder values; the Python pipeline regenerates this in Task 10 with real counts/dates):

```json
{
  "source": "OpenAIP",
  "license": "CC BY-NC-SA 4.0",
  "generatedAt": "2026-05-31",
  "dataAsOf": "2026-05-31",
  "counts": { "airports": 5, "vfrPoints": 5, "airspaces": 3 }
}
```

- [ ] **Step 6: Register the asset in `pubspec.yaml`**

Under `flutter: assets:`, add the line (keep the existing three):

```yaml
    - assets/aviation_data/aviation_data_meta.json
```

- [ ] **Step 7: Run, verify pass**

Run: `flutter test test/features/aviation_data/data/aviation_data_meta_test.dart`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/aviation_data/domain/entities/aviation_data_meta.dart \
        lib/features/aviation_data/data/datasources/aviation_data_loader.dart \
        assets/aviation_data/aviation_data_meta.json pubspec.yaml \
        test/features/aviation_data/data/aviation_data_meta_test.dart
git commit -m "feat(aviation): add AviationDataMeta entity, parser, and asset"
```

---

## Task 5: Repository seam — `AviationDataRepository` + `BundledAviationDataSource`

**Note:** Tests use a **fake `AssetBundle`** (the idiomatic Flutter seam) rather than a fake loader — `BundledAviationDataSource` takes an optional `AssetBundle` that defaults to `rootBundle`, and reads the four assets through it.

**Files:**
- Create: `lib/features/aviation_data/domain/repositories/aviation_data_repository.dart`
- Create: `lib/features/aviation_data/data/repositories/bundled_aviation_data_source.dart`
- Test: `test/features/aviation_data/data/bundled_aviation_data_source_test.dart` (create)

- [ ] **Step 1: Create the abstract repository**

Create `lib/features/aviation_data/domain/repositories/aviation_data_repository.dart`:

```dart
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/aviation_data_meta.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';

abstract class AviationDataRepository {
  Future<List<Airport>> getAirports();
  Future<List<VfrPoint>> getVfrPoints();
  Future<List<Airspace>> getAirspaces();
  Future<AviationDataMeta?> getMeta();
}
```

- [ ] **Step 2: Write failing test (with a fake AssetBundle)**

Create `test/features/aviation_data/data/bundled_aviation_data_source_test.dart`:

```dart
import 'dart:typed_data';

import 'package:flight_assistant/features/aviation_data/data/repositories/bundled_aviation_data_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._files);
  final Map<String, String> _files;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _files[key];
    if (value == null) throw FlutterError('asset not found: $key');
    return value;
  }

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(_files[key]!.codeUnits);
    return ByteData.view(bytes.buffer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BundledAviationDataSource reads + parses bundled assets', () async {
    final bundle = _FakeAssetBundle({
      'assets/aviation_data/airports_pl.geojson':
          '{"type":"FeatureCollection","features":[{"type":"Feature",'
          '"geometry":{"type":"Point","coordinates":[20.0,52.0]},'
          '"properties":{"id":"EPWA","name":"Warszawa","icao":"EPWA","type":"licensed"}}]}',
      'assets/aviation_data/vfr_points_pl.geojson':
          '{"type":"FeatureCollection","features":[]}',
      'assets/aviation_data/airspaces_pl.geojson':
          '{"type":"FeatureCollection","features":[]}',
      'assets/aviation_data/aviation_data_meta.json':
          '{"source":"OpenAIP","license":"CC BY-NC-SA 4.0","generatedAt":"2026-05-31",'
          '"dataAsOf":"2026-05-29","counts":{"airports":1,"vfrPoints":0,"airspaces":0}}',
    });
    final source = BundledAviationDataSource(bundle: bundle);

    expect((await source.getAirports()).single.icaoCode, 'EPWA');
    expect(await source.getVfrPoints(), isEmpty);
    expect(await source.getAirspaces(), isEmpty);
    expect((await source.getMeta())!.source, 'OpenAIP');
  });
}
```

- [ ] **Step 3: Run, verify fails**

Run: `flutter test test/features/aviation_data/data/bundled_aviation_data_source_test.dart`
Expected: FAIL — `BundledAviationDataSource` does not exist.

- [ ] **Step 4: Implement `BundledAviationDataSource`**

This requires the loader's `parse*`/`parseMeta` (already static, pure on strings). Create `lib/features/aviation_data/data/repositories/bundled_aviation_data_source.dart`:

```dart
import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/aviation_data_meta.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';
import 'package:flight_assistant/features/aviation_data/domain/repositories/aviation_data_repository.dart';
import 'package:flutter/services.dart';

/// Phase 1 repository: reads bundled GeoJSON assets (fully offline).
class BundledAviationDataSource implements AviationDataRepository {
  BundledAviationDataSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const _airports = 'assets/aviation_data/airports_pl.geojson';
  static const _vfrPoints = 'assets/aviation_data/vfr_points_pl.geojson';
  static const _airspaces = 'assets/aviation_data/airspaces_pl.geojson';
  static const _meta = 'assets/aviation_data/aviation_data_meta.json';

  @override
  Future<List<Airport>> getAirports() async =>
      AviationDataLoader.parseAirports(await _bundle.loadString(_airports));

  @override
  Future<List<VfrPoint>> getVfrPoints() async =>
      AviationDataLoader.parseVfrPoints(await _bundle.loadString(_vfrPoints));

  @override
  Future<List<Airspace>> getAirspaces() async =>
      AviationDataLoader.parseAirspaces(await _bundle.loadString(_airspaces));

  @override
  Future<AviationDataMeta?> getMeta() async =>
      AviationDataLoader.parseMeta(await _bundle.loadString(_meta));
}
```

- [ ] **Step 5: Run, verify pass**

Run: `flutter test test/features/aviation_data/data/bundled_aviation_data_source_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/aviation_data/domain/repositories/aviation_data_repository.dart \
        lib/features/aviation_data/data/repositories/bundled_aviation_data_source.dart \
        test/features/aviation_data/data/bundled_aviation_data_source_test.dart
git commit -m "feat(aviation): add AviationDataRepository + BundledAviationDataSource"
```

---

## Task 6: Wire providers to the repository + add meta provider

**Files:**
- Modify: `lib/features/aviation_data/application/providers/aviation_data_providers.dart`
- Test: existing provider/screen tests (must stay green; they override the FutureProviders directly).

- [ ] **Step 1: Replace the providers file**

Replace the entire contents of `aviation_data_providers.dart` with:

```dart
import 'package:flight_assistant/features/aviation_data/data/repositories/bundled_aviation_data_source.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/aviation_data_meta.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';
import 'package:flight_assistant/features/aviation_data/domain/repositories/aviation_data_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single seam for aviation data. Phase 2 overrides this with a repository
/// that prefers freshest-of {remote, cached, bundled} — providers/UI unchanged.
final aviationDataRepositoryProvider = Provider<AviationDataRepository>(
  (ref) => BundledAviationDataSource(),
);

final airportsProvider = FutureProvider<List<Airport>>(
  (ref) => ref.watch(aviationDataRepositoryProvider).getAirports(),
);

final vfrPointsProvider = FutureProvider<List<VfrPoint>>(
  (ref) => ref.watch(aviationDataRepositoryProvider).getVfrPoints(),
);

final airspacesProvider = FutureProvider<List<Airspace>>(
  (ref) => ref.watch(aviationDataRepositoryProvider).getAirspaces(),
);

final aviationDataMetaProvider = FutureProvider<AviationDataMeta?>(
  (ref) => ref.watch(aviationDataRepositoryProvider).getMeta(),
);
```

- [ ] **Step 2: Run the full aviation + map test suites**

Run: `flutter test test/features/aviation_data/ test/features/map_view/`
Expected: PASS — existing screen tests override `airportsProvider`/`vfrPointsProvider`/`airspacesProvider` directly, so they bypass the repository and stay green.

- [ ] **Step 3: Commit**

```bash
git add lib/features/aviation_data/application/providers/aviation_data_providers.dart
git commit -m "refactor(aviation): read providers through AviationDataRepository seam"
```

---

## Task 7: `MapScreen` loading/error UX + "data as of" label

**Why:** Replace `valueOrNull ?? []` with explicit `.when(...)` handling — base map renders immediately, a small spinner shows while layers load, a SnackBar shows on error, and a discreet "Data: OpenAIP, as of <date>" label provides required attribution.

**Files:**
- Modify: `lib/features/map_view/presentation/screens/map_screen.dart`
- Test: `test/features/map_view/presentation/screens/map_screen_states_test.dart` (create)

- [ ] **Step 1: Write failing tests for loading + error states**

Create `test/features/map_view/presentation/screens/map_screen_states_test.dart`:

```dart
import 'dart:async';

import 'package:flight_assistant/features/aviation_data/application/providers/aviation_data_providers.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
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

  final base = [
    routeRepositoryProvider.overrideWithValue(TestRouteRepository()),
    loggerServiceProvider.overrideWithValue(CapturingLoggerService()),
  ];

  testWidgets('shows a loading indicator while aviation data loads',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...base,
          // Never-completing future -> provider stays in loading state.
          airportsProvider
              .overrideWith((ref) => Completer<List<Airport>>().future),
          vfrPointsProvider.overrideWith((ref) async => []),
          airspacesProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pump(); // do not settle (future never completes)
    expect(find.byKey(const Key('aviation-loading')), findsOneWidget);
  });

  testWidgets('shows a SnackBar when aviation data fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...base,
          airportsProvider.overrideWith((ref) async => throw Exception('boom')),
          vfrPointsProvider.overrideWith((ref) async => []),
          airspacesProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pump(); // let the error microtask run
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('aviation data'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run, verify fails**

Run: `flutter test test/features/map_view/presentation/screens/map_screen_states_test.dart`
Expected: FAIL — no `aviation-loading` key, no SnackBar.

- [ ] **Step 3: Rewrite `MapScreen.build` to handle states**

In `map_screen.dart`, replace the body of `build` (the lines computing `airports`/`vfrPoints`/`airspaces` and the `return AppScaffold(...)`) with the version below. Keep the rest of the file (`_showLayersSheet`, `_LayersBottomSheet`) unchanged.

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waypoints =
        ref.watch(flightPlanningControllerProvider).routePlan.waypoints;
    final layerVisibility = ref.watch(layerVisibilityProvider);

    final airportsAsync = ref.watch(airportsProvider);
    final vfrPointsAsync = ref.watch(vfrPointsProvider);
    final airspacesAsync = ref.watch(airspacesProvider);
    final meta = ref.watch(aviationDataMetaProvider).valueOrNull;

    final isLoading = airportsAsync.isLoading ||
        vfrPointsAsync.isLoading ||
        airspacesAsync.isLoading;
    final hasError = airportsAsync.hasError ||
        vfrPointsAsync.hasError ||
        airspacesAsync.hasError;

    // Surface a one-off error without blocking the map.
    if (hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load aviation data')),
        );
      });
    }

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
        builder: (context, constraints) => Stack(
          children: [
            FlightMapWidget(
              waypoints: waypoints,
              airports: airportsAsync.valueOrNull ?? const [],
              vfrPoints: vfrPointsAsync.valueOrNull ?? const [],
              airspaces: airspacesAsync.valueOrNull ?? const [],
              layerVisibility: layerVisibility,
              showControls: true,
              height: constraints.maxHeight,
            ),
            if (isLoading)
              const Positioned(
                top: 12,
                left: 12,
                child: SizedBox(
                  key: Key('aviation-loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (meta != null)
              Positioned(
                bottom: 8,
                left: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Data: ${meta.source}, as of ${meta.dataAsOf}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 4: Run the map test suite**

Run: `flutter test test/features/map_view/`
Expected: PASS — new state tests + existing smoke/screen tests (which override providers with immediate `[]`, so no spinner/SnackBar appears in those).

- [ ] **Step 5: Commit**

```bash
git add lib/features/map_view/presentation/screens/map_screen.dart \
        test/features/map_view/presentation/screens/map_screen_states_test.dart
git commit -m "feat(map): loading/error states + data provenance label"
```

---

## Task 8: Python pipeline — pure mapping module + tests

**Files:**
- Create: `tool/aviation_data/mapping.py`
- Create: `tool/aviation_data/requirements.txt`
- Create: `tool/aviation_data/tests/__init__.py` (empty)
- Create: `tool/aviation_data/tests/test_mapping.py`
- Create: `tool/aviation_data/tests/fixtures/openaip_sample.json`

**Mapping contract:** the OpenAIP API returns items with (documented) fields — for an airspace: `_id`/`name`/`type`/`icaoClass`/`upperLimit`/`lowerLimit`/`geometry`; for an airport: `icaoCode`/`name`/`type`/`geometry`; for a reporting point: `name`/`geometry` (+ a short code). The functions below map those to **our** GeoJSON `properties`. Exact field names are re-confirmed against one live record in Task 9, Step 1; adjust this module + fixture together if they differ.

- [ ] **Step 1: Create `requirements.txt`**

```
requests==2.32.3
pytest==8.3.3
```

- [ ] **Step 2: Write the fixture**

Create `tool/aviation_data/tests/fixtures/openaip_sample.json`:

```json
{
  "airports": [
    {"icaoCode": "EPWA", "name": "Warszawa Chopin", "type": 9,
     "geometry": {"type": "Point", "coordinates": [20.9679, 52.1657]}},
    {"icaoCode": "", "name": "Grass Strip", "type": 1,
     "geometry": {"type": "Point", "coordinates": [19.0, 51.0]}}
  ],
  "reporting_points": [
    {"name": "LIMA", "geometry": {"type": "Point", "coordinates": [21.0, 52.3]}}
  ],
  "airspaces": [
    {"_id": "a1", "name": "Warszawa CTR", "type": 4, "icaoClass": 3,
     "upperLimit": {"value": 9500, "unit": 1, "referenceDatum": 1},
     "lowerLimit": {"value": 0, "unit": 1, "referenceDatum": 0},
     "geometry": {"type": "Polygon",
       "coordinates": [[[20.6,51.9],[21.3,51.9],[21.3,52.4],[20.6,51.9]]]}},
    {"_id": "m1", "name": "Multi Restricted", "type": 1, "icaoClass": 8,
     "upperLimit": {"value": 9500, "unit": 1, "referenceDatum": 1},
     "lowerLimit": {"value": 0, "unit": 1, "referenceDatum": 0},
     "geometry": {"type": "MultiPolygon",
       "coordinates": [[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]],
                       [[[22.0,53.0],[22.1,53.0],[22.1,53.1],[22.0,53.0]]]]}}
  ]
}
```

- [ ] **Step 3: Write failing tests**

Create `tool/aviation_data/tests/test_mapping.py`:

```python
import json
import os

from tool.aviation_data.mapping import (
    map_airport,
    map_reporting_point,
    map_airspace_feature,
)

FIX = os.path.join(os.path.dirname(__file__), "fixtures", "openaip_sample.json")
with open(FIX) as fh:
    SAMPLE = json.load(fh)


def test_map_airport_with_icao():
    f = map_airport(SAMPLE["airports"][0])
    assert f["properties"]["icao"] == "EPWA"
    assert f["properties"]["type"] == "licensed"
    assert f["geometry"]["type"] == "Point"


def test_map_airport_without_icao_falls_back_to_id_and_other_type():
    f = map_airport(SAMPLE["airports"][1])
    assert f["properties"]["icao"] == ""
    assert f["properties"]["id"]  # non-empty id even without ICAO
    assert f["properties"]["type"] in {"grass", "other"}


def test_map_reporting_point():
    f = map_reporting_point(SAMPLE["reporting_points"][0])
    assert f["properties"]["code"] == "LIMA"
    assert f["properties"]["name"] == "LIMA"


def test_map_airspace_polygon_is_one_feature():
    feats = map_airspace_feature(SAMPLE["airspaces"][0])
    assert len(feats) == 1
    assert feats[0]["properties"]["type"] == "ctr"
    assert feats[0]["geometry"]["type"] == "Polygon"


def test_map_airspace_multipolygon_kept_as_multipolygon():
    feats = map_airspace_feature(SAMPLE["airspaces"][1])
    # The Dart loader explodes MultiPolygon; the pipeline may emit it as-is.
    assert len(feats) == 1
    assert feats[0]["geometry"]["type"] == "MultiPolygon"
    assert feats[0]["properties"]["type"] == "restricted"


def test_unknown_airspace_type_maps_to_other():
    item = dict(SAMPLE["airspaces"][0])
    item["type"] = 999
    feats = map_airspace_feature(item)
    assert feats[0]["properties"]["type"] == "other"
```

- [ ] **Step 4: Run, verify fails**

Run (from repo root): `python -m pytest tool/aviation_data/tests/ -v`
Expected: FAIL — `tool.aviation_data.mapping` does not exist.

- [ ] **Step 5: Implement `mapping.py`**

Create `tool/aviation_data/mapping.py`:

```python
"""Pure OpenAIP -> app-GeoJSON mapping. No network here (easy to unit-test)."""

# OpenAIP numeric airport "type" -> our AirportType strings.
# Unmapped -> "other". (Exact codes confirmed against live data in fetch.py.)
_AIRPORT_TYPE = {
    0: "other",        # heliport civil/other -> handled below
    9: "licensed",     # international/regional civil
    10: "licensed",
    2: "licensed",     # civil
    1: "grass",        # airfield/glider grass strip
    3: "heliport",
}

# OpenAIP numeric airspace "type" -> our AirspaceType strings. Unmapped -> "other".
_AIRSPACE_TYPE = {
    4: "ctr",
    7: "tma",
    1: "restricted",
    2: "danger",
    3: "prohibited",
    21: "atz",
    10: "tsa",
    11: "tra",
    12: "rmz",
    13: "tmz",
}


def map_airport(item: dict) -> dict:
    icao = (item.get("icaoCode") or "").strip()
    name = item.get("name", "")
    return {
        "type": "Feature",
        "geometry": item["geometry"],
        "properties": {
            "id": icao or f"AP_{name}".strip().replace(" ", "_"),
            "name": name,
            "icao": icao,
            "type": _AIRPORT_TYPE.get(item.get("type"), "other"),
        },
    }


def map_reporting_point(item: dict) -> dict:
    name = item.get("name", "")
    return {
        "type": "Feature",
        "geometry": item["geometry"],
        "properties": {
            "id": f"VP_{name}".replace(" ", "_"),
            "name": name,
            "code": name,
        },
    }


def _limit_to_str(limit: dict) -> str:
    """Format an OpenAIP altitude limit into our ceiling/floor string."""
    value = limit.get("value", 0)
    datum = limit.get("referenceDatum")  # 0=GND, 1=MSL/AMSL, 2=STD/FL
    if datum == 0 and value == 0:
        return "GND"
    if datum == 2:
        return f"FL{int(value) // 100:03d}"
    suffix = "AMSL" if datum == 1 else "AGL"
    return f"{int(value)}ft {suffix}"


def map_airspace_feature(item: dict) -> list:
    """Return a list (always length 1) so callers can flat-map uniformly."""
    props = {
        "id": str(item.get("_id") or item.get("name")),
        "name": item.get("name", ""),
        "type": _AIRSPACE_TYPE.get(item.get("type"), "other"),
        "class": _icao_class(item.get("icaoClass")),
        "ceiling": _limit_to_str(item.get("upperLimit", {})),
        "floor": _limit_to_str(item.get("lowerLimit", {})),
    }
    return [{"type": "Feature", "geometry": item["geometry"], "properties": props}]


def _icao_class(code) -> str:
    # OpenAIP icaoClass: 0=A ... 6=G, 8=unclassified/SUA.
    return {0: "A", 1: "B", 2: "C", 3: "D", 4: "E", 5: "F", 6: "G"}.get(code, "G")
```

- [ ] **Step 6: Run, verify pass**

Run: `python -m pytest tool/aviation_data/tests/ -v`
Expected: PASS (6 tests).

- [ ] **Step 7: Commit**

```bash
git add tool/aviation_data/mapping.py tool/aviation_data/requirements.txt \
        tool/aviation_data/tests/
git commit -m "feat(tool): OpenAIP->app GeoJSON mapping module with tests"
```

---

## Task 9: Python pipeline — `fetch.py` (network + orchestration)

**Files:**
- Create: `tool/aviation_data/fetch.py`
- Create: `tool/aviation_data/README.md`

- [ ] **Step 1: Confirm OpenAIP field names against one live record**

With a free OpenAIP API key exported as `OPENAIP_API_KEY`, run:

```bash
curl -s -H "x-openaip-api-key: $OPENAIP_API_KEY" \
  "https://api.core.openaip.net/api/airspaces?country=PL&limit=1" | head -c 2000
```

Confirm the field names used in `mapping.py` (`_id`, `name`, `type`, `icaoClass`, `upperLimit`/`lowerLimit` `{value,unit,referenceDatum}`, `geometry`). If any differ, update `mapping.py` + the fixture in Task 8 together, re-run `pytest`, and amend the Task 8 commit.

- [ ] **Step 2: Implement `fetch.py`**

Create `tool/aviation_data/fetch.py`:

```python
"""Fetch OpenAIP data for Poland and write the app's bundled GeoJSON assets.

Usage:
    OPENAIP_API_KEY=xxxx python tool/aviation_data/fetch.py

Writes (relative to repo root):
    assets/aviation_data/airports_pl.geojson
    assets/aviation_data/vfr_points_pl.geojson
    assets/aviation_data/airspaces_pl.geojson
    assets/aviation_data/aviation_data_meta.json
"""
import datetime as dt
import json
import os
import sys

import requests

from tool.aviation_data.mapping import (
    map_airport,
    map_reporting_point,
    map_airspace_feature,
)

API = "https://api.core.openaip.net/api"
COUNTRY = "PL"
REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_DIR = os.path.join(REPO_ROOT, "assets", "aviation_data")


def _key() -> str:
    key = os.environ.get("OPENAIP_API_KEY")
    if not key:
        sys.exit("ERROR: set OPENAIP_API_KEY (free account at openaip.net).")
    return key


def _fetch_all(resource: str, key: str) -> list:
    """Page through an OpenAIP collection for Poland."""
    items, page, limit = [], 1, 1000
    headers = {"x-openaip-api-key": key}
    while True:
        resp = requests.get(
            f"{API}/{resource}",
            headers=headers,
            params={"country": COUNTRY, "limit": limit, "page": page},
            timeout=60,
        )
        resp.raise_for_status()
        body = resp.json()
        batch = body.get("items", body if isinstance(body, list) else [])
        items.extend(batch)
        total_pages = body.get("totalPages", 1) if isinstance(body, dict) else 1
        if page >= total_pages or not batch:
            break
        page += 1
    return items


def _write(name: str, features: list) -> int:
    features.sort(key=lambda f: f["properties"]["id"])  # deterministic diffs
    fc = {"type": "FeatureCollection", "features": features}
    path = os.path.join(OUT_DIR, name)
    with open(path, "w") as fh:
        json.dump(fc, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    return len(features)


def main() -> None:
    key = _key()
    os.makedirs(OUT_DIR, exist_ok=True)

    airports = [map_airport(a) for a in _fetch_all("airports", key)]
    vfr = [map_reporting_point(p) for p in _fetch_all("reporting-points", key)]
    raw_airspaces = _fetch_all("airspaces", key)
    airspaces = []
    for a in raw_airspaces:
        airspaces.extend(map_airspace_feature(a))

    n_ap = _write("airports_pl.geojson", airports)
    n_vp = _write("vfr_points_pl.geojson", vfr)
    n_as = _write("airspaces_pl.geojson", airspaces)

    today = dt.date.today().isoformat()
    meta = {
        "source": "OpenAIP",
        "license": "CC BY-NC-SA 4.0",
        "generatedAt": today,
        "dataAsOf": today,
        "counts": {"airports": n_ap, "vfrPoints": n_vp, "airspaces": n_as},
    }
    with open(os.path.join(OUT_DIR, "aviation_data_meta.json"), "w") as fh:
        json.dump(meta, fh, indent=2)
        fh.write("\n")

    print(f"Wrote {n_ap} airports, {n_vp} VFR points, {n_as} airspaces.")


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Write `README.md`**

Create `tool/aviation_data/README.md`:

```markdown
# Aviation data pipeline (dev-side)

Fetches Polish VFR aviation data from OpenAIP and writes the app's bundled
GeoJSON assets. Run manually when you want to refresh the data. The app itself
never calls OpenAIP in Phase 1 — it only reads the committed assets.

## Prerequisites
- Python 3.10+
- A free OpenAIP API key: create an account at https://www.openaip.net, then
  generate an API key in your account settings.

## Run
```bash
python -m pip install -r tool/aviation_data/requirements.txt
export OPENAIP_API_KEY=your_key_here       # never commit this
python tool/aviation_data/fetch.py
```

This overwrites:
- `assets/aviation_data/airports_pl.geojson`
- `assets/aviation_data/vfr_points_pl.geojson`
- `assets/aviation_data/airspaces_pl.geojson`
- `assets/aviation_data/aviation_data_meta.json`

Review the diff, run the app, then commit the regenerated assets.

## Tests
```bash
python -m pytest tool/aviation_data/tests/ -v
```

## Data attribution
Data © OpenAIP contributors, licensed CC BY-NC-SA 4.0. The app shows
"Data: OpenAIP, as of <date>" on the map.
```

- [ ] **Step 4: Commit**

```bash
git add tool/aviation_data/fetch.py tool/aviation_data/README.md
git commit -m "feat(tool): OpenAIP fetch pipeline + README"
```

---

## Task 10 (manual, requires user's OpenAIP key): generate + commit real PL data

> This task needs a real `OPENAIP_API_KEY` and network. It is performed by the user
> (or by the agent if the user supplies a key). The app code and all tests above are
> independent of the real dataset, so the build stays green without it.

- [ ] **Step 1: Generate the data**

```bash
python -m pip install -r tool/aviation_data/requirements.txt
export OPENAIP_API_KEY=your_key_here
python tool/aviation_data/fetch.py
```
Expected: prints non-zero counts; overwrites the four asset files.

- [ ] **Step 2: Verify in the app**

Run: `flutter run -d iphone` (or the simulator). On the Map tab, confirm Polish airports / VFR points / airspaces render, layer toggles work, and the "Data: OpenAIP, as of <date>" label shows.

- [ ] **Step 3: Run the full test suite**

Run: `flutter analyze && flutter test`
Expected: analyzer clean; all tests pass (synthetic-fixture tests are unaffected by the real data).

- [ ] **Step 4: Commit the real data**

```bash
git add assets/aviation_data/*.geojson assets/aviation_data/aviation_data_meta.json
git commit -m "data(aviation): real Polish VFR dataset from OpenAIP"
```

---

## Final verification (Phase 1 done)

- [ ] `python -m pytest tool/aviation_data/tests/ -v` → all pass.
- [ ] `flutter analyze` → no issues.
- [ ] `flutter test` → all pass (57 baseline + new tests).
- [ ] App on iOS Simulator: Map tab shows real PL data, toggles work, loading/error states behave, "data as of" label visible.
- [ ] Update `docs/development-journal.md` with an Iteration 10 entry (date, AI model, time tracking per AGENTS.md; if a 3-agent team is used, per-member durations).

---

## Self-review notes (author)

- **Spec coverage:** pipeline (T8–T10), bundled real data (T10), hardened parser — per-feature isolation (T2), MultiPolygon (T3), extended `AirspaceType` (T1), `AirportType` unchanged/unknown→other (T1 + mapping), repository seam Bundled-only (T5–T6), provenance metadata (T4 + label T7), loading/error UX (T7). All covered.
- **Phase 2 boundary:** remote source, Drift cache, user API key in Settings — intentionally absent.
- **Type consistency:** `AviationDataRepository` methods `getAirports/getVfrPoints/getAirspaces/getMeta` used identically in T5/T6; `parseMeta`/`loadMeta` names consistent T4→T5; `AviationDataMeta` field names consistent T4→T7.
