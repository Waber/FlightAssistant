import 'package:flight_assistant/core/utils/distance_utils.dart';
import 'package:flight_assistant/core/utils/geo_utils.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/leg.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';

class RouteCalculationService {
  List<Leg> buildLegs(List<Waypoint> waypoints) {
    if (waypoints.length < 2) {
      return const [];
    }

    final legs = <Leg>[];
    for (int i = 0; i < waypoints.length - 1; i++) {
      final from = waypoints[i];
      final to = waypoints[i + 1];

      final distanceNm = DistanceUtils.calculateDistanceNm(
        fromLatitude: from.latitude,
        fromLongitude: from.longitude,
        toLatitude: to.latitude,
        toLongitude: to.longitude,
      );
      final trueCourseDeg = GeoUtils.calculateInitialBearing(
        fromLatitude: from.latitude,
        fromLongitude: from.longitude,
        toLatitude: to.latitude,
        toLongitude: to.longitude,
      );

      legs.add(
        Leg(
          fromWaypoint: from,
          toWaypoint: to,
          distanceNm: distanceNm,
          trueCourseDeg: trueCourseDeg,
        ),
      );
    }
    return legs;
  }

  RoutePlan calculate(RoutePlan routePlan) {
    final legs = buildLegs(routePlan.waypoints);
    final totalDistanceNm = legs.fold<double>(
      0,
      (total, leg) => total + leg.distanceNm,
    );
    return routePlan.copyWith(
      legs: legs,
      totalDistanceNm: totalDistanceNm,
      updatedAt: DateTime.now(),
    );
  }
}

