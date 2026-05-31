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
