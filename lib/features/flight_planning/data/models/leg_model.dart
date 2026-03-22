import 'package:flight_assistant/features/flight_planning/domain/entities/leg.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';

class LegModel {
  const LegModel({
    required this.fromWaypointId,
    required this.toWaypointId,
    required this.distanceNm,
    required this.trueCourseDeg,
  });

  final String fromWaypointId;
  final String toWaypointId;
  final double distanceNm;
  final double trueCourseDeg;

  factory LegModel.fromDomain(Leg leg) {
    return LegModel(
      fromWaypointId: leg.fromWaypoint.id,
      toWaypointId: leg.toWaypoint.id,
      distanceNm: leg.distanceNm,
      trueCourseDeg: leg.trueCourseDeg,
    );
  }

  Leg toDomain(Map<String, Waypoint> waypointMap) {
    final from = waypointMap[fromWaypointId];
    final to = waypointMap[toWaypointId];
    if (from == null || to == null) {
      throw StateError('Cannot build leg because waypoint references are missing.');
    }
    return Leg(
      fromWaypoint: from,
      toWaypoint: to,
      distanceNm: distanceNm,
      trueCourseDeg: trueCourseDeg,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'fromWaypointId': fromWaypointId,
      'toWaypointId': toWaypointId,
      'distanceNm': distanceNm,
      'trueCourseDeg': trueCourseDeg,
    };
  }

  factory LegModel.fromMap(Map<String, dynamic> map) {
    return LegModel(
      fromWaypointId: map['fromWaypointId'] as String,
      toWaypointId: map['toWaypointId'] as String,
      distanceNm: (map['distanceNm'] as num).toDouble(),
      trueCourseDeg: (map['trueCourseDeg'] as num).toDouble(),
    );
  }
}

