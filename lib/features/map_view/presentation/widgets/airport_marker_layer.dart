import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flutter/material.dart';
import 'package:maplibre/maplibre.dart';

class AirportMarkerLayer extends StatelessWidget {
  const AirportMarkerLayer({super.key, required this.airports});

  final List<Airport> airports;

  /// Marker fill colour per airport type.
  static Color colorFor(AirportType type) => switch (type) {
        AirportType.licensed => const Color(0xFF0B5A8F), // blue (established)
        AirportType.grass || AirportType.ultralight =>
          const Color(0xFF2E7D32), // green
        AirportType.landingStrip => const Color(0xFF6D4C41), // brown
        AirportType.heliport => const Color(0xFF0B5A8F), // blue
        AirportType.military => const Color(0xFF556B2F), // olive
        AirportType.other => const Color(0xFF757575), // grey
      };

  /// Glyph icon per airport type, or null for heliport (which renders an "H").
  static IconData? iconFor(AirportType type) => switch (type) {
        AirportType.heliport => null,
        AirportType.ultralight => Icons.paragliding,
        AirportType.landingStrip => Icons.flight_land,
        AirportType.military => Icons.shield,
        AirportType.licensed ||
        AirportType.grass ||
        AirportType.other =>
          Icons.flight,
      };

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
              child: _AirportMarker(type: airport.type),
            ),
          ),
      ],
    );
  }
}

class _AirportMarker extends StatelessWidget {
  const _AirportMarker({required this.type});

  final AirportType type;

  @override
  Widget build(BuildContext context) {
    final icon = AirportMarkerLayer.iconFor(type);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AirportMarkerLayer.colorFor(type),
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
      child: Center(
        child: icon == null
            ? const Text(
                'H',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              )
            : Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }
}
