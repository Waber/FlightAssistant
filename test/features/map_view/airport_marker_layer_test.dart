import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/airport_marker_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AirportMarkerLayer.colorFor', () {
    test('licensed is the established blue', () {
      expect(AirportMarkerLayer.colorFor(AirportType.licensed),
          const Color(0xFF0B5A8F));
    });

    test('grass and ultralight share green', () {
      const green = Color(0xFF2E7D32);
      expect(AirportMarkerLayer.colorFor(AirportType.grass), green);
      expect(AirportMarkerLayer.colorFor(AirportType.ultralight), green);
    });

    test('landingStrip is brown, military is olive, other is grey', () {
      expect(AirportMarkerLayer.colorFor(AirportType.landingStrip),
          const Color(0xFF6D4C41));
      expect(AirportMarkerLayer.colorFor(AirportType.military),
          const Color(0xFF556B2F));
      expect(AirportMarkerLayer.colorFor(AirportType.other),
          const Color(0xFF757575));
    });
  });

  group('AirportMarkerLayer.iconFor', () {
    test('returns null for heliport (rendered as an "H" badge)', () {
      expect(AirportMarkerLayer.iconFor(AirportType.heliport), isNull);
    });

    test('uses distinct icons for the other types', () {
      expect(AirportMarkerLayer.iconFor(AirportType.ultralight),
          Icons.paragliding);
      expect(AirportMarkerLayer.iconFor(AirportType.landingStrip),
          Icons.flight_land);
      expect(AirportMarkerLayer.iconFor(AirportType.military), Icons.shield);
      expect(AirportMarkerLayer.iconFor(AirportType.licensed), Icons.flight);
    });
  });
}
