"""Pure OpenAIP -> app-GeoJSON mapping. No network here (easy to unit-test)."""

# OpenAIP numeric airport "type" -> our AirportType strings. Unmapped -> "other".
# Codes per the OpenAIP airport type enum.
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

# OpenAIP numeric airspace "type" -> our AirspaceType strings. Unmapped -> "other".
# Codes per the OpenAIP airspace type enum, cross-checked against live PL names.
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
    18: "drone_zone",       # Warning Area / BVLOS drone operations
    21: "gliding_sector",
    28: "sporting",         # aerial sporting / recreational activity
    30: "military_route",
}

# OpenAIP icaoClass codes 0..6 -> ICAO airspace class A..G.
# Codes outside this range (e.g. 8 = unclassified/SUA) are intentionally
# absent so they map to "" (unknown) rather than being misreported as "G".
_ICAO_CLASS = {0: "A", 1: "B", 2: "C", 3: "D", 4: "E", 5: "F", 6: "G"}


def map_airport(item: dict) -> dict:
    icao = (item.get("icaoCode") or "").strip()
    name = item.get("name", "")
    return {
        "type": "Feature",
        "geometry": item["geometry"],
        "properties": {
            "id": icao or f"AP_{name.strip()}".replace(" ", "_"),
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
        # Assumes the API value is in feet (confirmed against live data in Task 9).
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
    # Unknown/unclassified (e.g. 8 = SUA) -> "" so it isn't misreported as "G".
    return _ICAO_CLASS.get(code, "")
