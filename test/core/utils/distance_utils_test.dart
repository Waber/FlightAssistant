import 'package:flight_assistant/core/utils/distance_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DistanceUtils.calculateDistanceNm', () {
    test('returns 0 for identical coordinates', () {
      final result = DistanceUtils.calculateDistanceNm(
        fromLatitude: 52.2297,
        fromLongitude: 21.0122,
        toLatitude: 52.2297,
        toLongitude: 21.0122,
      );

      expect(result, 0);
    });

    test('returns valid distance for Warsaw-Krakow route', () {
      final result = DistanceUtils.calculateDistanceNm(
        fromLatitude: 52.2297,
        fromLongitude: 21.0122,
        toLatitude: 50.0647,
        toLongitude: 19.945,
      );

      expect(result, greaterThan(130));
      expect(result, lessThan(150));
    });
  });
}

