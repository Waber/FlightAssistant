import 'package:flight_assistant/features/flight_planning/domain/entities/leg.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';

class RoutePlan {
  const RoutePlan({
    required this.id,
    required this.name,
    required this.waypoints,
    required this.legs,
    required this.totalDistanceNm,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final List<Waypoint> waypoints;
  final List<Leg> legs;
  final double totalDistanceNm;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RoutePlan.empty({
    required String id,
    required String name,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return RoutePlan(
      id: id,
      name: name,
      waypoints: const [],
      legs: const [],
      totalDistanceNm: 0,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  RoutePlan copyWith({
    String? id,
    String? name,
    List<Waypoint>? waypoints,
    List<Leg>? legs,
    double? totalDistanceNm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoutePlan(
      id: id ?? this.id,
      name: name ?? this.name,
      waypoints: waypoints ?? this.waypoints,
      legs: legs ?? this.legs,
      totalDistanceNm: totalDistanceNm ?? this.totalDistanceNm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

