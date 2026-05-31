"""Fetch OpenAIP data for Poland and write the app's bundled GeoJSON assets.

Usage:
    OPENAIP_API_KEY=xxxx python -m tool.aviation_data.fetch

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
        batch = body.get("items", []) if isinstance(body, dict) else (body if isinstance(body, list) else [])
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
