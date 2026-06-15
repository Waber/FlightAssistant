import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class AirspacePolygonLayer {
  const AirspacePolygonLayer._();

  /// Colour for an airspace type, by aviation convention.
  static Color colorFor(AirspaceType type) => switch (type) {
        AirspaceType.prohibited ||
        AirspaceType.restricted ||
        AirspaceType.danger =>
          const Color(0xFFD32F2F), // red — hazard
        AirspaceType.ctr ||
        AirspaceType.tma ||
        AirspaceType.atz ||
        AirspaceType.mctr =>
          const Color(0xFF1565C0), // blue — controlled
        AirspaceType.rmz || AirspaceType.tmz =>
          const Color(0xFF7B1FA2), // purple — radio/transponder
        AirspaceType.tsa || AirspaceType.tra =>
          const Color(0xFFEF6C00), // orange — temporary
        AirspaceType.militaryRoute => const Color(0xFF5D4037), // brown
        AirspaceType.glidingSector ||
        AirspaceType.sporting =>
          const Color(0xFF388E3C), // green
        AirspaceType.droneZone => const Color(0xFFC2185B), // magenta
        AirspaceType.other => const Color(0xFFDBA800), // amber
      };

  /// Returns one [PolylineLayer] per distinct colour group tracing the airspace
  /// boundaries. Empty list when there is nothing to draw. Add the result to
  /// [MapLibreMap.layers] with `addAll`.
  static List<PolylineLayer> fromAirspaces(List<Airspace> airspaces) {
    final byColor = <int, List<Feature<LineString>>>{};
    for (final airspace in airspaces) {
      if (airspace.polygon.length < 2) continue;
      final coords = airspace.polygon
          .map((p) => Geographic(lon: p.$2, lat: p.$1))
          .toList(growable: false);
      final color = colorFor(airspace.type);
      byColor
          .putIfAbsent(color.toARGB32(), () => [])
          .add(Feature<LineString>(geometry: LineString.from(coords)));
    }

    return [
      for (final entry in byColor.entries)
        PolylineLayer(
          polylines: entry.value,
          color: Color(entry.key),
          width: 2,
        ),
    ];
  }
}
