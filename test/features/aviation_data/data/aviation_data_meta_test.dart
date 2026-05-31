import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AviationDataLoader.parseMeta', () {
    test('parses metadata fields', () {
      const json = '''
{"source":"OpenAIP","license":"CC BY-NC-SA 4.0","generatedAt":"2026-05-31",
 "dataAsOf":"2026-05-29","counts":{"airports":123,"vfrPoints":200,"airspaces":80}}''';
      final meta = AviationDataLoader.parseMeta(json);
      expect(meta, isNotNull);
      expect(meta!.source, 'OpenAIP');
      expect(meta.dataAsOf, '2026-05-29');
      expect(meta.airportCount, 123);
      expect(meta.vfrPointCount, 200);
      expect(meta.airspaceCount, 80);
    });

    test('returns null for malformed JSON', () {
      expect(AviationDataLoader.parseMeta('not json'), isNull);
    });

    test('returns null for structurally valid but incomplete JSON', () {
      expect(AviationDataLoader.parseMeta('{"source":"X"}'), isNull);
    });
  });
}
