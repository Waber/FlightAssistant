import 'dart:math' as math;

import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flutter/material.dart';

class FlightMapWidget extends StatelessWidget {
  const FlightMapWidget({
    required this.waypoints,
    super.key,
  });

  final List<Waypoint> waypoints;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: waypoints.isEmpty
              ? const Center(
                  child: Text('Map placeholder: route will be visible after adding waypoints.'),
                )
              : CustomPaint(
                  painter: _RoutePreviewPainter(waypoints),
                ),
        ),
      ),
    );
  }
}

class _RoutePreviewPainter extends CustomPainter {
  _RoutePreviewPainter(this.waypoints);

  final List<Waypoint> waypoints;

  @override
  void paint(Canvas canvas, Size size) {
    final points = _normalize(waypoints, size);
    if (points.isEmpty) {
      return;
    }

    final routePaint = Paint()
      ..color = const Color(0xFF0B5A8F)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, routePaint);
    }

    final markerFill = Paint()
      ..color = const Color(0xFF54A2D8)
      ..style = PaintingStyle.fill;
    final markerStroke = Paint()
      ..color = const Color(0xFF05375A)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      canvas.drawCircle(point, 5, markerFill);
      canvas.drawCircle(point, 5, markerStroke);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Color(0xFF05375A),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(point.dx + 6, point.dy - 6));
    }
  }

  List<Offset> _normalize(List<Waypoint> waypoints, Size size) {
    if (waypoints.isEmpty) {
      return const [];
    }

    final latitudes = waypoints.map((waypoint) => waypoint.latitude).toList();
    final longitudes = waypoints.map((waypoint) => waypoint.longitude).toList();

    final minLat = latitudes.reduce(math.min);
    final maxLat = latitudes.reduce(math.max);
    final minLon = longitudes.reduce(math.min);
    final maxLon = longitudes.reduce(math.max);

    final latRange = (maxLat - minLat).abs() < 0.00001 ? 1.0 : (maxLat - minLat);
    final lonRange = (maxLon - minLon).abs() < 0.00001 ? 1.0 : (maxLon - minLon);
    const margin = 8.0;
    final drawableWidth = size.width - (margin * 2);
    final drawableHeight = size.height - (margin * 2);

    return waypoints.map((waypoint) {
      final x = margin + ((waypoint.longitude - minLon) / lonRange) * drawableWidth;
      final y = margin + ((maxLat - waypoint.latitude) / latRange) * drawableHeight;
      return Offset(x, y);
    }).toList();
  }

  @override
  bool shouldRepaint(covariant _RoutePreviewPainter oldDelegate) {
    return oldDelegate.waypoints != waypoints;
  }
}

