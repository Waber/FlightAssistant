import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "Polygon",
        "coordinates": [[[20.6667, 51.9167], [21.3333, 51.9167], [21.3333, 52.4167], [20.6667, 52.4167], [20.6667, 51.9167]]]
      },
      "properties": { "id": "EPWA_CTR", "name": "Warszawa CTR", "type": "ctr", "class": "D", "ceiling": "FL095", "floor": "GND" }
    }
  ]
}
''';

  group('AviationDataLoader.parseAirspaces', () {
    test('returns correct count', () {
      expect(AviationDataLoader.parseAirspaces(sampleJson).length, 1);
    });

    test('parses fields correctly', () {
      final result = AviationDataLoader.parseAirspaces(sampleJson);
      final ctr = result.first;
      expect(ctr.id, 'EPWA_CTR');
      expect(ctr.name, 'Warszawa CTR');
      expect(ctr.type, AirspaceType.ctr);
      expect(ctr.airspaceClass, 'D');
      expect(ctr.ceiling, 'FL095');
      expect(ctr.floor, 'GND');
    });

    test('parses polygon coordinates in lat/lon order', () {
      final result = AviationDataLoader.parseAirspaces(sampleJson);
      final polygon = result.first.polygon;
      expect(polygon.length, 5); // 4 corners + closing point
      // GeoJSON is [lon, lat] — parser must flip to (lat, lon)
      expect(polygon.first.$1, closeTo(51.9167, 0.0001)); // lat
      expect(polygon.first.$2, closeTo(20.6667, 0.0001)); // lon
    });

    test('returns empty list for empty FeatureCollection', () {
      const empty = '{"type":"FeatureCollection","features":[]}';
      expect(AviationDataLoader.parseAirspaces(empty), isEmpty);
    });

    test('returns empty list for malformed JSON', () {
      expect(AviationDataLoader.parseAirspaces('not json'), isEmpty);
    });
  });
}
