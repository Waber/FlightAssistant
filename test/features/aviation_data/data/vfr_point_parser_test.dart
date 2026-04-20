import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sampleJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [20.9122, 52.3050] },
      "properties": { "id": "LIMA", "name": "Lima", "code": "LIMA" }
    },
    {
      "type": "Feature",
      "geometry": { "type": "Point", "coordinates": [21.1833, 52.1667] },
      "properties": { "id": "PAPA", "name": "Papa", "code": "PAPA" }
    }
  ]
}
''';

  group('AviationDataLoader.parseVfrPoints', () {
    test('returns correct count', () {
      expect(AviationDataLoader.parseVfrPoints(sampleJson).length, 2);
    });

    test('parses fields correctly', () {
      final result = AviationDataLoader.parseVfrPoints(sampleJson);
      final lima = result.first;
      expect(lima.id, 'LIMA');
      expect(lima.name, 'Lima');
      expect(lima.code, 'LIMA');
      expect(lima.latitude, closeTo(52.3050, 0.0001));
      expect(lima.longitude, closeTo(20.9122, 0.0001));
    });

    test('returns empty list for empty FeatureCollection', () {
      const empty = '{"type":"FeatureCollection","features":[]}';
      expect(AviationDataLoader.parseVfrPoints(empty), isEmpty);
    });

    test('returns empty list for malformed JSON', () {
      expect(AviationDataLoader.parseVfrPoints('not json'), isEmpty);
    });
  });
}
