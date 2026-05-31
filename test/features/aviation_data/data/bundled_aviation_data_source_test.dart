import 'dart:typed_data';

import 'package:flight_assistant/features/aviation_data/data/repositories/bundled_aviation_data_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._files);
  final Map<String, String> _files;

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _files[key];
    if (value == null) throw FlutterError('asset not found: $key');
    return value;
  }

  @override
  Future<ByteData> load(String key) async {
    final bytes = Uint8List.fromList(_files[key]!.codeUnits);
    return ByteData.view(bytes.buffer);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('BundledAviationDataSource reads + parses bundled assets', () async {
    final bundle = _FakeAssetBundle({
      'assets/aviation_data/airports_pl.geojson':
          '{"type":"FeatureCollection","features":[{"type":"Feature",'
          '"geometry":{"type":"Point","coordinates":[20.0,52.0]},'
          '"properties":{"id":"EPWA","name":"Warszawa","icao":"EPWA","type":"licensed"}}]}',
      'assets/aviation_data/vfr_points_pl.geojson':
          '{"type":"FeatureCollection","features":[]}',
      'assets/aviation_data/airspaces_pl.geojson':
          '{"type":"FeatureCollection","features":[]}',
      'assets/aviation_data/aviation_data_meta.json':
          '{"source":"OpenAIP","license":"CC BY-NC-SA 4.0","generatedAt":"2026-05-31",'
          '"dataAsOf":"2026-05-29","counts":{"airports":1,"vfrPoints":0,"airspaces":0}}',
    });
    final source = BundledAviationDataSource(bundle: bundle);

    expect((await source.getAirports()).single.icaoCode, 'EPWA');
    expect(await source.getVfrPoints(), isEmpty);
    expect(await source.getAirspaces(), isEmpty);
    expect((await source.getMeta())!.source, 'OpenAIP');
  });
}
