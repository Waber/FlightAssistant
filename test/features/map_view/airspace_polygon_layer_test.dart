import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/airspace_polygon_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Airspace _a(AirspaceType type) => Airspace(
      id: 'x',
      name: 'x',
      type: type,
      airspaceClass: '',
      ceiling: 'FL095',
      floor: 'GND',
      polygon: const [(51.0, 20.0), (51.0, 20.1), (51.1, 20.1)],
    );

void main() {
  group('AirspacePolygonLayer.colorFor', () {
    test('hazard types are red', () {
      const red = Color(0xFFD32F2F);
      expect(AirspacePolygonLayer.colorFor(AirspaceType.prohibited), red);
      expect(AirspacePolygonLayer.colorFor(AirspaceType.restricted), red);
      expect(AirspacePolygonLayer.colorFor(AirspaceType.danger), red);
    });

    test('controlled types are blue', () {
      const blue = Color(0xFF1565C0);
      expect(AirspacePolygonLayer.colorFor(AirspaceType.ctr), blue);
      expect(AirspacePolygonLayer.colorFor(AirspaceType.tma), blue);
      expect(AirspacePolygonLayer.colorFor(AirspaceType.atz), blue);
    });

    test('new categories have distinct colours', () {
      expect(AirspacePolygonLayer.colorFor(AirspaceType.militaryRoute),
          const Color(0xFF5D4037));
      expect(AirspacePolygonLayer.colorFor(AirspaceType.glidingSector),
          const Color(0xFF388E3C));
      expect(AirspacePolygonLayer.colorFor(AirspaceType.droneZone),
          const Color(0xFFC2185B));
      expect(AirspacePolygonLayer.colorFor(AirspaceType.other),
          const Color(0xFFDBA800));
    });
  });

  group('AirspacePolygonLayer.fromAirspaces', () {
    test('returns empty list when no airspaces', () {
      expect(AirspacePolygonLayer.fromAirspaces(const []), isEmpty);
    });

    test('groups into one layer per distinct colour', () {
      final layers = AirspacePolygonLayer.fromAirspaces([
        _a(AirspaceType.danger), // red
        _a(AirspaceType.restricted), // red (same group)
        _a(AirspaceType.ctr), // blue
        _a(AirspaceType.glidingSector), // green
      ]);
      expect(layers.length, 3);
    });

    test('skips degenerate polygons (<2 points)', () {
      final layers = AirspacePolygonLayer.fromAirspaces([
        Airspace(
          id: 'd',
          name: 'd',
          type: AirspaceType.ctr,
          airspaceClass: '',
          ceiling: 'FL095',
          floor: 'GND',
          polygon: const [(51.0, 20.0)],
        ),
      ]);
      expect(layers, isEmpty);
    });
  });
}
