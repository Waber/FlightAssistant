# Real Polish aviation data from OpenAIP — Design (Phase 1)

- **Date:** 2026-05-31
- **Author:** Przemek + Claude Code (Claude Opus 4.8, 1M context)
- **Status:** Approved design, pending implementation plan
- **Supersedes sample data:** the hand-written sample GeoJSON from Iteration 8
  (`assets/aviation_data/*.geojson`, 5 airports / 5 VFR points / 3 airspaces).

## 1. Goal & context

Replace the Iteration 8 *sample* aviation data with **real Polish VFR data sourced from
OpenAIP**, bundled for fully offline use. The end-state is a **hybrid** data layer (offline
baseline + optional online refresh), delivered in two phases. **This spec covers Phase 1**
and designs the seams that make Phase 2 a drop-in addition.

### Decisions locked during brainstorming (2026-05-31)
- **Source:** OpenAIP (`openaip.net`) — single source covering all three modelled categories
  (airports, reporting points → VFR points, airspaces). License: CC BY-NC-SA 4.0 (non-commercial),
  acceptable for this learning project (`publish_to: none`).
- **Architecture target:** hybrid. **Phase 1 = offline bundled data.** Phase 2 = runtime refresh + cache.
- **Conversion tool:** **Python** dev-side script (run manually). Produces committed
  `assets/*.geojson`. The Flutter app stays pure Dart/Flutter and only reads bundled assets in Phase 1.
- **Data scope:** VFR-relevant subset — all airports/airfields with positions, VFR reporting points,
  and airspaces relevant to VFR (CTR, TMA, ATZ, danger/restricted/prohibited, TSA/TRA, RMZ/TMZ).
  Excludes IFR-only/upper airspace, navaids, obstacles, hotspots.
- **Data access seam:** introduce a thin `AviationDataRepository` now (Option A) so Phase 2 adds
  sources without touching providers or UI.

## 2. Architecture

Two halves.

### Dev-side (Python, run manually)
```
OpenAIP REST API (country=PL)
   → tool/aviation_data/fetch.py   (fetch + map + sort, deterministic)
   → assets/aviation_data/{airports,vfr_points,airspaces}_pl.geojson   (committed)
   + assets/aviation_data/aviation_data_meta.json                       (committed)
```

### App-side (Dart, Phase 1 runtime — fully offline)
```
assets/*.geojson
   → AviationDataLoader (parser, hardened for real data)
   → BundledAviationDataSource
   → AviationDataRepository (interface)
   → Riverpod providers (airportsProvider / vfrPointsProvider / airspacesProvider / aviationDataMetaProvider)
   → MapScreen → FlightMapWidget (AirportMarkerLayer / VfrPointMarkerLayer / AirspacePolygonLayer)
```
Phase 2 adds `CachedAviationDataSource` (Drift) + `RemoteAviationDataSource` (API) behind the same
repository; providers and UI are unchanged.

## 3. Components

### 3.1 Python conversion pipeline — `tool/aviation_data/`
- Files: `fetch.py`, `requirements.txt`, `README.md` (human-readable run instructions per AGENTS.md),
  and `tests/` with a mapping unit test.
- **Auth:** OpenAIP API key from a free account via env var `OPENAIP_API_KEY`. **Never committed,
  never shipped in the app.** Script fails fast with a clear message if the key is missing.
- **Fetch:** for `country=PL`, the three resources `airports`, `reporting-points`, `airspaces`
  (paginated JSON, header `x-openaip-api-key`).
- **Map** OpenAIP fields → the app's existing GeoJSON shape (same `properties` keys the
  `AviationDataLoader` already reads), so loader changes stay minimal:
  - **Airport** → `{ id, name, icao, type }` + Point geometry. Map OpenAIP airport type codes to our
    `AirportType`; unmapped → `other`.
  - **VFR point** (reporting point) → `{ id, name, code }` + Point geometry.
  - **Airspace** → `{ id, name, type, class, ceiling, floor }` + Polygon/MultiPolygon geometry.
    Map OpenAIP airspace type/class; upper limit → `ceiling`, lower limit → `floor`.
- **Determinism:** sort features by `id`, stable JSON formatting → clean diffs across refreshes.
- **Filtering:** drop out-of-scope categories/types (IFR-only/upper, navaids, obstacles, hotspots).
- **Output:** the three GeoJSON files + `aviation_data_meta.json` (see §3.4).
- **Test:** `pytest` on the pure mapping function with a local fixture JSON (Point + Polygon +
  MultiPolygon + an unknown type) → expected app GeoJSON. No network.

### 3.2 Entities / enums (Dart)
- `AirspaceType` — extend with `atz`, `danger`, `tsa`, `tra`, `rmz`, `tmz`
  (keep existing `ctr`, `tma`, `mctr`, `restricted`, `prohibited`, `other`).
- `AirportType` — **unchanged** for Phase 1 (`licensed`, `grass`, `heliport`, `other`). Map OpenAIP
  airport types onto these existing values; anything not matching maps to `other`. (No new airport
  categories at this stage — decided 2026-05-31.)
- `Airspace.polygon` — **unchanged** (`List<(double lat, double lon)>`). MultiPolygon is handled by
  *exploding* into multiple `Airspace` records in the loader (see §3.3), so `AirspacePolygonLayer`
  needs no change.

### 3.3 `AviationDataLoader` — hardening (3 changes)
1. **Per-feature error isolation:** wrap each feature parse in `try/catch`; a malformed feature is
   skipped + logged (`dart:developer`), the rest of the layer is kept. (Closes Iteration 8 deferred
   follow-up: today one bad feature nukes the whole list.)
2. **MultiPolygon support:** a `MultiPolygon` airspace feature is expanded into **N `Airspace`
   records**, one per polygon ring, all sharing the same properties. (Closes Iteration 8 follow-up:
   today only `Polygon` is handled; MultiPolygon is silently dropped.)
3. **Extended enum mapping:** map the new enum values; any unknown type maps to `other` (record is
   kept, not dropped).

### 3.4 Data provenance — `aviation_data_meta.json`
- Generated by the pipeline. Shape:
  ```json
  { "source": "OpenAIP", "license": "CC BY-NC-SA 4.0",
    "generatedAt": "2026-05-31", "dataAsOf": "2026-05-29",
    "counts": { "airports": 123, "vfrPoints": 200, "airspaces": 80 } }
  ```
- Read via a new `aviationDataMetaProvider` (FutureProvider).
- Purpose: (1) display a discreet "Data: OpenAIP, as of <date>" (required attribution + tells the
  pilot how fresh the data is); (2) Phase 2 compares `dataAsOf` against the API to decide whether to refresh.

### 3.5 Data-access seam
- `AviationDataRepository` (abstract): `Future<List<Airport>> getAirports()`,
  `Future<List<VfrPoint>> getVfrPoints()`, `Future<List<Airspace>> getAirspaces()`.
- `BundledAviationDataSource` — Phase 1 implementation, delegates to `AviationDataLoader` (assets).
- Providers (`airportsProvider`, `vfrPointsProvider`, `airspacesProvider`) read from the repository.
- Phase 2: `CachedAviationDataSource` + `RemoteAviationDataSource` added behind the same repository,
  which picks the freshest available source — no provider/UI changes.

## 4. Data flow (Phase 1)
OpenAIP API → (Python) transform → committed `assets/*.geojson` → `AviationDataLoader` (parse,
hardened) → `BundledAviationDataSource` → `AviationDataRepository` → Riverpod providers →
`MapScreen` / `FlightMapWidget` layers.

## 5. Error handling
- **Pipeline:** missing API key → fail fast with guidance; HTTP/transport errors → non-zero exit,
  no partial overwrite of committed assets.
- **Loader:** per-feature isolation (one bad record never drops a whole layer); malformed file →
  empty list + logged error (existing behaviour, retained).
- **UI (`MapScreen`):** replace `valueOrNull ?? []` with `.when(...)`:
  - *loading:* lightweight indicator (small spinner on the map/layers bar); base map renders immediately.
  - *error:* `SnackBar` ("Failed to load aviation data") and the map keeps working without the layers.
  - Closes Iteration 8 deferred follow-up (invisible loading/error states). Kept minimal — no heavy skeletons.

## 6. Testing strategy
- **Python (`pytest`):** pure mapping function over a local fixture (Point + Polygon + MultiPolygon +
  unknown type) → expected GeoJSON. No network.
- **Dart (extends the current 57-test baseline):**
  - `AviationDataLoader`: MultiPolygon explosion into N airspaces; per-feature error isolation;
    extended enum mapping incl. unknown→`other`.
  - `BundledAviationDataSource` + `AviationDataRepository` (with a fake loader).
  - Provider tests updated to read through the repository.
  - `aviation_data_meta` parser/provider.
  - Existing map widget/screen tests stay green (now exercise `.when` states).
- Tests use **small synthetic fixtures**, not the full PL dataset. Real fetched PL data is committed
  as assets but is not a test dependency.

## 7. Scope / boundaries (YAGNI)
- **In Phase 1:** Python pipeline, bundled real PL data, hardened parser, repository seam
  (`Bundled` only), provenance metadata, loading/error UX.
- **NOT in Phase 1 → Phase 2:**
  - `RemoteAviationDataSource` + Drift cache + freshness logic.
  - **User-provided OpenAIP API key in Settings** (user pastes their own free key to refresh data on
    demand when online; the key authenticates `RemoteAviationDataSource` and comes from the user, not
    bundled). Requested by the user on 2026-05-31; recorded in the development journal backlog.
  - Android support.

## 8. Verification (definition of done for Phase 1)
- `python tool/aviation_data/fetch.py` produces the three GeoJSON files + meta, committed.
- `flutter analyze` clean; `flutter test` green (baseline + new tests).
- App on iOS Simulator shows real PL airports / VFR points / airspaces; layer toggles work;
  loading/error states behave; "data as of <date>" is visible.
