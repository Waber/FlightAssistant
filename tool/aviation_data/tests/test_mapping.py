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
    assert f["properties"]["type"] == "grass"  # fixture type=1 -> "grass"


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
