import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';

class WaypointModel {
  const WaypointModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String type;

  factory WaypointModel.fromDomain(Waypoint waypoint) {
    return WaypointModel(
      id: waypoint.id,
      name: waypoint.name,
      latitude: waypoint.latitude,
      longitude: waypoint.longitude,
      type: waypoint.type.name,
    );
  }

  Waypoint toDomain() {
    return Waypoint(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      type: WaypointType.values.firstWhere(
        (value) => value.name == type,
        orElse: () => WaypointType.userDefined,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'type': type,
    };
  }

  factory WaypointModel.fromMap(Map<String, dynamic> map) {
    return WaypointModel(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      type: map['type'] as String,
    );
  }
}

