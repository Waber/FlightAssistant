import 'package:flight_assistant/features/flight_planning/data/models/leg_model.dart';
import 'package:flight_assistant/features/flight_planning/data/models/waypoint_model.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';

class RoutePlanModel {
  const RoutePlanModel({
    required this.id,
    required this.name,
    required this.waypoints,
    required this.legs,
    required this.totalDistanceNm,
    required this.createdAtIso,
    required this.updatedAtIso,
  });

  final String id;
  final String name;
  final List<WaypointModel> waypoints;
  final List<LegModel> legs;
  final double totalDistanceNm;
  final String createdAtIso;
  final String updatedAtIso;

  factory RoutePlanModel.fromDomain(RoutePlan routePlan) {
    return RoutePlanModel(
      id: routePlan.id,
      name: routePlan.name,
      waypoints: routePlan.waypoints.map(WaypointModel.fromDomain).toList(),
      legs: routePlan.legs.map(LegModel.fromDomain).toList(),
      totalDistanceNm: routePlan.totalDistanceNm,
      createdAtIso: routePlan.createdAt.toIso8601String(),
      updatedAtIso: routePlan.updatedAt.toIso8601String(),
    );
  }

  RoutePlan toDomain() {
    final domainWaypoints = waypoints.map((model) => model.toDomain()).toList();
    final waypointMap = <String, Waypoint>{
      for (final waypoint in domainWaypoints) waypoint.id: waypoint,
    };
    return RoutePlan(
      id: id,
      name: name,
      waypoints: domainWaypoints,
      legs: legs.map((model) => model.toDomain(waypointMap)).toList(),
      totalDistanceNm: totalDistanceNm,
      createdAt: DateTime.parse(createdAtIso),
      updatedAt: DateTime.parse(updatedAtIso),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'waypoints': waypoints.map((model) => model.toMap()).toList(),
      'legs': legs.map((model) => model.toMap()).toList(),
      'totalDistanceNm': totalDistanceNm,
      'createdAtIso': createdAtIso,
      'updatedAtIso': updatedAtIso,
    };
  }

  factory RoutePlanModel.fromMap(Map<String, dynamic> map) {
    return RoutePlanModel(
      id: map['id'] as String,
      name: map['name'] as String,
      waypoints: (map['waypoints'] as List<dynamic>)
          .map((entry) => WaypointModel.fromMap(Map<String, dynamic>.from(entry as Map)))
          .toList(),
      legs: (map['legs'] as List<dynamic>)
          .map((entry) => LegModel.fromMap(Map<String, dynamic>.from(entry as Map)))
          .toList(),
      totalDistanceNm: (map['totalDistanceNm'] as num).toDouble(),
      createdAtIso: map['createdAtIso'] as String,
      updatedAtIso: map['updatedAtIso'] as String,
    );
  }
}
