enum WaypointType {
  departure,
  enroute,
  destination,
  userDefined,
}

class Waypoint {
  const Waypoint({
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
  final WaypointType type;

  Waypoint copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    WaypointType? type,
  }) {
    return Waypoint(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
    );
  }
}

