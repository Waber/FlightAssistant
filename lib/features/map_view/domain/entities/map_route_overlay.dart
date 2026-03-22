import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';

class MapPoint {
  const MapPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class MapRouteOverlay {
  const MapRouteOverlay({required this.points});

  final List<MapPoint> points;

  bool get hasRoute => points.length > 1;

  factory MapRouteOverlay.fromWaypoints(List<Waypoint> waypoints) {
    return MapRouteOverlay(
      points: waypoints
          .map((waypoint) => MapPoint(
                latitude: waypoint.latitude,
                longitude: waypoint.longitude,
              ))
          .toList(),
    );
  }
}

