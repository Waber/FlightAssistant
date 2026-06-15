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

    test('maps extended airspace types', () {
      const json = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"D1","name":"Danger 1","type":"danger","class":"G","ceiling":"FL095","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"A1","name":"ATZ 1","type":"atz","class":"G","ceiling":"2000ft","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"S1","name":"TSA 1","type":"tsa","class":"G","ceiling":"FL095","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"T1","name":"TRA 1","type":"tra","class":"G","ceiling":"FL095","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"R1","name":"RMZ 1","type":"rmz","class":"G","ceiling":"FL095","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"M1","name":"TMZ 1","type":"tmz","class":"G","ceiling":"FL095","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"X1","name":"Unknown","type":"weird","class":"G","ceiling":"FL095","floor":"GND"}}
]}''';
      final result = AviationDataLoader.parseAirspaces(json);
      expect(result.map((a) => a.type), [
        AirspaceType.danger,
        AirspaceType.atz,
        AirspaceType.tsa,
        AirspaceType.tra,
        AirspaceType.rmz,
        AirspaceType.tmz,
        AirspaceType.other, // unknown maps to other, record kept
      ]);
    });

    test('maps new VFR airspace categories', () {
      const json = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"MR1","name":"MRT1","type":"military_route","class":"","ceiling":"FL095","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"GS1","name":"Glider","type":"gliding_sector","class":"","ceiling":"FL095","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"DZ1","name":"BVLOS","type":"drone_zone","class":"","ceiling":"FL095","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"SP1","name":"Area","type":"sporting","class":"","ceiling":"FL095","floor":"GND"}}
]}''';
      final result = AviationDataLoader.parseAirspaces(json);
      expect(result.map((a) => a.type), [
        AirspaceType.militaryRoute,
        AirspaceType.glidingSector,
        AirspaceType.droneZone,
        AirspaceType.sporting,
      ]);
    });

    test('explodes MultiPolygon into one Airspace per polygon', () {
      const json = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"MultiPolygon","coordinates":[
   [[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]],
   [[[22.0,53.0],[22.1,53.0],[22.1,53.1],[22.0,53.0]]]
 ]},
  "properties":{"id":"R1","name":"Restricted 1","type":"restricted","class":"G","ceiling":"FL095","floor":"GND"}}
]}''';
      final result = AviationDataLoader.parseAirspaces(json);
      expect(result.length, 2);
      expect(result.every((a) => a.id == 'R1'), isTrue);
      expect(result.every((a) => a.type == AirspaceType.restricted), isTrue);
      expect(result[0].polygon.first.$1, closeTo(51.0, 0.0001));
      expect(result[1].polygon.first.$1, closeTo(53.0, 0.0001));
    });
  });
}
