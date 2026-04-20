import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [20.9679, 52.1657] },
      "properties": { "id": "EPWA", "name": "Warszawa Chopin", "icao": "EPWA", "type": "licensed" }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [23.0103, 52.0853] },
      "properties": { "id": "EPBL", "name": "Biała Podlaska", "icao": "EPBL", "type": "grass" }
    }
  ]
}
''';

  group('AviationDataLoader.parseAirports', () {
    test('returns correct count', () {
      final result = AviationDataLoader.parseAirports(sampleJson);
      expect(result.length, 2);
    });

    test('parses first airport fields correctly', () {
      final result = AviationDataLoader.parseAirports(sampleJson);
      final epwa = result.first;
      expect(epwa.id, 'EPWA');
      expect(epwa.name, 'Warszawa Chopin');
      expect(epwa.icaoCode, 'EPWA');
      expect(epwa.latitude, closeTo(52.1657, 0.0001));
      expect(epwa.longitude, closeTo(20.9679, 0.0001));
      expect(epwa.type, AirportType.licensed);
    });

    test('maps grass type correctly', () {
      final result = AviationDataLoader.parseAirports(sampleJson);
      expect(result[1].type, AirportType.grass);
    });

    test('returns empty list for empty FeatureCollection', () {
      const empty = '{"type":"FeatureCollection","features":[]}';
      expect(AviationDataLoader.parseAirports(empty), isEmpty);
    });

    test('returns empty list for malformed JSON', () {
      expect(AviationDataLoader.parseAirports('not json'), isEmpty);
    });
  });
}
