import 'package:flight_assistant/core/utils/distance_utils.dart';
import 'package:flight_assistant/core/utils/geo_utils.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/navigation/domain/entities/aircraft_position.dart';

class NavigationService {
  double calculateDistanceToWaypointNm({
    required AircraftPosition aircraftPosition,
    required Waypoint nextWaypoint,
  }) {
    return DistanceUtils.calculateDistanceNm(
      fromLatitude: aircraftPosition.latitude,
      fromLongitude: aircraftPosition.longitude,
      toLatitude: nextWaypoint.latitude,
      toLongitude: nextWaypoint.longitude,
    );
  }

  double calculateBearingToWaypointDeg({
    required AircraftPosition aircraftPosition,
    required Waypoint nextWaypoint,
  }) {
    return GeoUtils.calculateInitialBearing(
      fromLatitude: aircraftPosition.latitude,
      fromLongitude: aircraftPosition.longitude,
      toLatitude: nextWaypoint.latitude,
      toLongitude: nextWaypoint.longitude,
    );
  }
}

