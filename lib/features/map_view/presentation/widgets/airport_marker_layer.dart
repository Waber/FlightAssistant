import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class AirportMarkerLayer extends StatelessWidget {
  const AirportMarkerLayer({super.key, required this.airports});

  final List<Airport> airports;

  @override
  Widget build(BuildContext context) {
    if (airports.isEmpty) return const SizedBox.shrink();

    return WidgetLayer(
      markers: [
        for (final airport in airports)
          Marker(
            point: Geographic(lon: airport.longitude, lat: airport.latitude),
            size: const Size(28, 28),
            child: Tooltip(
              message: '${airport.name} (${airport.icaoCode})',
              child: const _AirportMarker(),
            ),
          ),
      ],
    );
  }
}

class _AirportMarker extends StatelessWidget {
  const _AirportMarker();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0B5A8F),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.flight, color: Colors.white, size: 14),
      ),
    );
  }
}
