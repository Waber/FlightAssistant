import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('per-feature error isolation', () {
    test('parseAirports keeps good features, skips a malformed one', () {
      const json = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"Point","coordinates":[20.0,52.0]},
  "properties":{"id":"EPWA","name":"Warszawa","icao":"EPWA","type":"licensed"}},
 {"type":"Feature","geometry":{"type":"Point","coordinates":[19.0,51.0]},
  "properties":{"id":"BAD","name":"No ICAO key here","type":"grass"}},
 {"type":"Feature","geometry":{"type":"Point","coordinates":[18.0,54.0]},
  "properties":{"id":"EPGD","name":"Gdansk","icao":"EPGD","type":"licensed"}}
]}''';
      final result = AviationDataLoader.parseAirports(json);
      expect(result.map((a) => a.id), ['EPWA', 'EPGD']);
    });

    test('parseVfrPoints keeps good features, skips a malformed one', () {
      const json = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"Point","coordinates":[20.0,52.0]},
  "properties":{"id":"L","name":"Lima","code":"LIMA"}},
 {"type":"Feature","geometry":{"type":"Point","coordinates":[19.0,51.0]},
  "properties":{"id":"BAD","name":"missing code"}}
]}''';
      final result = AviationDataLoader.parseVfrPoints(json);
      expect(result.map((v) => v.id), ['L']);
    });

    test('parseAirspaces keeps good features, skips a malformed one', () {
      const json = '''
{"type":"FeatureCollection","features":[
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0],[20.1,51.0],[20.1,51.1],[20.0,51.0]]]},
  "properties":{"id":"OK","name":"Ok","type":"ctr","class":"D","ceiling":"FL095","floor":"GND"}},
 {"type":"Feature","geometry":{"type":"Polygon","coordinates":[[[20.0,51.0]]]},
  "properties":{"id":"BAD","name":"missing class","type":"ctr","ceiling":"FL095","floor":"GND"}}
]}''';
      final result = AviationDataLoader.parseAirspaces(json);
      expect(result.map((a) => a.id), ['OK']);
    });

    test('malformed top-level JSON still returns empty', () {
      expect(AviationDataLoader.parseAirports('not json'), isEmpty);
      expect(AviationDataLoader.parseVfrPoints('not json'), isEmpty);
      expect(AviationDataLoader.parseAirspaces('not json'), isEmpty);
    });
  });
}
