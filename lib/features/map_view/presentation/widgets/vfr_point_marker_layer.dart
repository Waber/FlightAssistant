import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class VfrPointMarkerLayer extends StatelessWidget {
  const VfrPointMarkerLayer({super.key, required this.vfrPoints});

  final List<VfrPoint> vfrPoints;

  @override
  Widget build(BuildContext context) {
    if (vfrPoints.isEmpty) return const SizedBox.shrink();

    return WidgetLayer(
      markers: [
        for (final point in vfrPoints)
          Marker(
            point: Geographic(lon: point.longitude, lat: point.latitude),
            size: const Size(36, 36),
            child: Tooltip(
              message: point.name,
              child: _VfrPointMarker(code: point.code),
            ),
          ),
      ],
    );
  }
}

class _VfrPointMarker extends StatelessWidget {
  const _VfrPointMarker({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE67E22),
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white, width: 1.5),
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
          code,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 8,
          ),
        ),
      ),
    );
  }
}
