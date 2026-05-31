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
