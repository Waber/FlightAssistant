import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';

class Leg {
  const Leg({
    required this.fromWaypoint,
    required this.toWaypoint,
    required this.distanceNm,
    required this.trueCourseDeg,
  });

  final Waypoint fromWaypoint;
  final Waypoint toWaypoint;
  final double distanceNm;
  final double trueCourseDeg;
}

