# Enrich & correct aviation data categories — design

**Date:** 2026-06-14
**Status:** Approved (implementation deferred)
**Branch:** `feature/real-pl-aviation-data` (continues Iteration 10 / Phase 1)

## Problem

When the first real Polish OpenAIP dataset was fetched (Task 10), the numeric
`type` → category lookup tables in `tool/aviation_data/mapping.py` proved wrong.
They had been guessed against the tiny placeholder dataset, not the live OpenAIP
type enum, so live data was badly miscategorised:

- **70% of airspaces (700/1005)** fell through to `other`.
- **40% of airports (173/431)** fell through to `other`.

Diagnosis (re-fetching the raw type histogram and correlating codes → the Polish
names, which embed the ICAO designator) confirmed the tables are shifted/wrong:

| raw code | count | mapped (buggy) | actual (from names + OpenAIP enum) |
|----------|-------|----------------|------------------------------------|
| airspace 6 | 69 | other | RMZ (`RMZ EPBC`) |
| airspace 13 | 52 | tmz | ATZ (`ATZ EPBA`) |
| airspace 8 | 284 | other | TRA (`EPTR…` = Temp. Reserved) |
| airspace 9 | 44 | other | TSA (`EPTS…` = Temp. Segregated) |
| airspace 10 | 1 | tsa | FIR (`FIR EPWW`) |
| airport 3 | 5 | heliport | International Airport (`KRAKÓW/BALICE`) |
| airport 7 | 8 | other | Heliport Civil (`… BAZA LPR`) |

The OpenAIP airport enum was confirmed authoritatively (OpenAIP Google Group:
0=Airport, 1=Glider Site, 2=Airfield Civil, 3=International Airport,
4=Heliport Military, 5=Military Aerodrome, 6=Ultra Light, 7=Heliport Civil,
8=Aerodrome Closed, 9=Airfield IFR, 10=Airfield Water, 11=Landing Strip,
12=Agricultural Landing Strip, 13=Altiport). The airspace enum was confirmed by
matching the standard OpenAIP airspace enum against the Polish names — every
identifiable code matched (4=CTR, 6=RMZ, 7=TMA, 8=TRA, 9=TSA, 10=FIR, 13=ATZ,
18=Warning/BVLOS, 21=Gliding Sector, 28=Aerial Sporting, 30=Military Route,
33=FIS Sector).

Separately, the map does **not** currently differentiate by type at all: every
airport is one blue circle, every airspace one amber outline.

## Goal

1. **Correct** the `mapping.py` lookup tables against the authoritative enums.
2. **Enrich** the app's category model: add first-class types that matter to a
   VFR pilot but are currently lost in `other`.
3. **Style** the map by category so the new categories are actually
   distinguishable.

## Scope

### 1. Data correctness — `tool/aviation_data/mapping.py`

Replace `_AIRSPACE_TYPE`:

```python
_AIRSPACE_TYPE = {
    1: "restricted",
    2: "danger",
    3: "prohibited",
    4: "ctr",
    5: "tmz",
    6: "rmz",
    7: "tma",
    8: "tra",
    9: "tsa",
    13: "atz",
    18: "drone_zone",       # Warning Area / BVLOS drone ops
    21: "gliding_sector",
    28: "sporting",         # aerial sporting / recreational activity
    30: "military_route",
}
```

Everything else (10=FIR, 33=FIS, 11=UIR, …) → `other`.

Replace `_AIRPORT_TYPE`:

```python
_AIRPORT_TYPE = {
    0: "licensed",          # Airport (civil/military)
    1: "grass",             # Glider Site
    2: "licensed",          # Airfield Civil
    3: "licensed",          # International Airport
    4: "heliport",          # Heliport Military
    5: "military",          # Military Aerodrome
    6: "ultralight",        # Ultra Light Flying Site
    7: "heliport",          # Heliport Civil
    9: "licensed",          # Airfield IFR
    11: "landing_strip",    # Landing Strip
    12: "landing_strip",    # Agricultural Landing Strip
}
```

Everything else (8=Closed, 10=Water, 13=Altiport) → `other`.

The misleading `# Exact codes confirmed against live data` comment is removed;
the codes now match the cited OpenAIP enum.

### 2. New categories — Dart entities + parser

`lib/features/aviation_data/domain/entities/airspace.dart` — extend
`AirspaceType` with: `militaryRoute, glidingSector, droneZone, sporting`.

`lib/features/aviation_data/domain/entities/airport.dart` — extend
`AirportType` with: `military, ultralight, landingStrip`.

`lib/features/aviation_data/data/datasources/aviation_data_loader.dart` — add
the matching cases in `_parseAirspaceType` / `_parseAirportType`. GeoJSON string
keys are snake_case, Dart enum values camelCase:

| GeoJSON key | Dart `AirspaceType` |
|-------------|---------------------|
| `military_route` | `militaryRoute` |
| `gliding_sector` | `glidingSector` |
| `drone_zone` | `droneZone` |
| `sporting` | `sporting` |

| GeoJSON key | Dart `AirportType` |
|-------------|--------------------|
| `military` | `military` |
| `ultralight` | `ultralight` |
| `landing_strip` | `landingStrip` |

Cross-language schema (Python output ↔ Dart parser keys) must stay matching —
verify as part of the final review, as in Phase 1.

### 3. Map styling

**Airspaces** — `AirspacePolygonLayer.fromAirspaces` currently returns a single
`PolylineLayer` (one colour). MapLibre's `PolylineLayer` is single-colour, so
change the return type to `List<PolylineLayer>` — one layer per colour group —
and update `flight_map_widget._buildLayers()` to `addAll(...)`. Colour by
aviation convention:

| colour | hex (approx) | airspace types |
|--------|--------------|----------------|
| red | `0xFFD32F2F` | prohibited, restricted, danger |
| blue | `0xFF1565C0` | ctr, tma, atz, mctr |
| purple | `0xFF7B1FA2` | rmz, tmz |
| orange | `0xFFEF6C00` | tsa, tra |
| brown | `0xFF5D4037` | militaryRoute |
| green | `0xFF388E3C` | glidingSector, sporting |
| magenta | `0xFFC2185B` | droneZone |
| amber | `0xFFDBA800` (current) | other |

**Airports** — `_AirportMarker` selects icon + colour by `airport.type`:

| type | colour | icon |
|------|--------|------|
| licensed | blue `0xFF0B5A8F` (current) | `Icons.flight` |
| grass | green | `Icons.flight` |
| ultralight | green | `Icons.paragliding` |
| landingStrip | brown | `Icons.flight_land` |
| heliport | blue | "H" badge (Material has no helicopter icon) |
| military | olive/dark | `Icons.shield` |
| other | grey | `Icons.flight` |

### 4. Testing

- **Python** (`tool/aviation_data/tests/test_mapping.py`): add a case per new
  code → type for both airspaces and airports; keep the existing
  unknown-code → `other` test.
- **Dart**: parser tests for each new enum case; a small test asserting
  `fromAirspaces` groups into the expected number of `PolylineLayer`s by colour.
- Gates: `flutter analyze` clean, `flutter test` green, `pytest` green.

### 5. Re-fetch & verify

After the code changes: re-run `python -m tool.aviation_data.fetch` (or
`.venv/bin/python -m tool.aviation_data.fetch`) to regenerate the assets with
correct categories, then verify on the iOS Simulator, then commit the
regenerated assets.

## Out of scope / caveats

- **FIR & FIS stay `other`.** `FIR EPWW` is one polygon covering all of Poland;
  rendered amber it blankets the map. If that is visually noisy, filtering FIR
  (and possibly FIS sectors) out of the airspace layer is a quick follow-up —
  not part of this change.
- **Layer toggles unchanged** — airspaces remain a single on/off group, not
  per-colour toggles.
- No change to the repository seam / providers introduced in Phase 1.

## Files touched

- `tool/aviation_data/mapping.py` (+ `tests/test_mapping.py`)
- `lib/features/aviation_data/domain/entities/airspace.dart`
- `lib/features/aviation_data/domain/entities/airport.dart`
- `lib/features/aviation_data/data/datasources/aviation_data_loader.dart`
- `lib/features/map_view/presentation/widgets/airspace_polygon_layer.dart`
- `lib/features/map_view/presentation/widgets/airport_marker_layer.dart`
- `lib/features/map_view/presentation/widgets/flight_map_widget.dart`
- Dart tests under `test/`
- Regenerated `assets/aviation_data/*.geojson` + `aviation_data_meta.json`
