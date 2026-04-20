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
