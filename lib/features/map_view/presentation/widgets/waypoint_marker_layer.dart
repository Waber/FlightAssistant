import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class WaypointMarkerLayer extends StatelessWidget {
  const WaypointMarkerLayer({
    required this.waypoints,
    super.key,
  });

  final List<Waypoint> waypoints;

  @override
  Widget build(BuildContext context) {
    if (waypoints.isEmpty) {
      return const SizedBox.shrink();
    }

    return WidgetLayer(
      markers: [
        for (final (index, waypoint) in waypoints.indexed)
          Marker(
            point: Geographic(
              lon: waypoint.longitude,
              lat: waypoint.latitude,
            ),
            size: const Size(32, 32),
            child: Tooltip(
              message: waypoint.name,
              child: _WaypointMarker(index: index),
            ),
          ),
      ],
    );
  }
}

class _WaypointMarker extends StatelessWidget {
  const _WaypointMarker({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0B5A8F),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
