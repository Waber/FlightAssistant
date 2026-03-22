import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flutter/material.dart';

class WaypointMarkerLayer extends StatelessWidget {
  const WaypointMarkerLayer({
    required this.waypoints,
    super.key,
  });

  final List<Waypoint> waypoints;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: waypoints
          .map(
            (waypoint) => Chip(
              label: Text(waypoint.name),
              avatar: const Icon(Icons.location_on_outlined, size: 16),
            ),
          )
          .toList(),
    );
  }
}

