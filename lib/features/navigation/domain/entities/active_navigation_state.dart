import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';

class ActiveNavigationState {
  const ActiveNavigationState({
    required this.activeRouteId,
    required this.activeLegIndex,
    required this.nextWaypoint,
    required this.distanceToNextNm,
    required this.desiredTrackDeg,
    required this.bearingToWaypointDeg,
  });

  final String activeRouteId;
  final int activeLegIndex;
  final Waypoint? nextWaypoint;
  final double? distanceToNextNm;
  final double? desiredTrackDeg;
  final double? bearingToWaypointDeg;

  ActiveNavigationState copyWith({
    String? activeRouteId,
    int? activeLegIndex,
    Waypoint? nextWaypoint,
    double? distanceToNextNm,
    double? desiredTrackDeg,
    double? bearingToWaypointDeg,
  }) {
    return ActiveNavigationState(
      activeRouteId: activeRouteId ?? this.activeRouteId,
      activeLegIndex: activeLegIndex ?? this.activeLegIndex,
      nextWaypoint: nextWaypoint ?? this.nextWaypoint,
      distanceToNextNm: distanceToNextNm ?? this.distanceToNextNm,
      desiredTrackDeg: desiredTrackDeg ?? this.desiredTrackDeg,
      bearingToWaypointDeg: bearingToWaypointDeg ?? this.bearingToWaypointDeg,
    );
  }
}

