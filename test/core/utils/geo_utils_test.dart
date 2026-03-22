import 'package:flight_assistant/core/utils/geo_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeoUtils.calculateInitialBearing', () {
    test('returns north bearing close to 0 degrees', () {
      final result = GeoUtils.calculateInitialBearing(
        fromLatitude: 0,
        fromLongitude: 0,
        toLatitude: 1,
        toLongitude: 0,
      );

      expect(result, closeTo(0, 0.01));
    });

    test('returns east bearing close to 90 degrees', () {
      final result = GeoUtils.calculateInitialBearing(
        fromLatitude: 0,
        fromLongitude: 0,
        toLatitude: 0,
        toLongitude: 1,
      );

      expect(result, closeTo(90, 0.01));
    });
  });
}

