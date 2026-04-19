import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class RoutePolylineLayer {
  const RoutePolylineLayer._();

  static PolylineLayer? fromWaypoints(List<Waypoint> waypoints) {
    if (waypoints.length < 2) {
      return null;
    }

    final coordinates = waypoints
        .map((waypoint) => Geographic(lon: waypoint.longitude, lat: waypoint.latitude))
        .toList(growable: false);

    return PolylineLayer(
      polylines: [
        Feature<LineString>(
          geometry: LineString.from(coordinates),
        ),
      ],
      color: const Color(0xFF0B5A8F),
      width: 4,
    );
  }
}
