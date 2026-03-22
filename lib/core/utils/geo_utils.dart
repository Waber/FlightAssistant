import 'dart:math' as math;

import 'package:flight_assistant/core/utils/angle_utils.dart';

class GeoUtils {
  static double calculateInitialBearing({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    final fromLatRad = _degToRad(fromLatitude);
    final toLatRad = _degToRad(toLatitude);
    final deltaLonRad = _degToRad(toLongitude - fromLongitude);

    final y = math.sin(deltaLonRad) * math.cos(toLatRad);
    final x = math.cos(fromLatRad) * math.sin(toLatRad) -
        math.sin(fromLatRad) * math.cos(toLatRad) * math.cos(deltaLonRad);
    final bearingRad = math.atan2(y, x);
    return AngleUtils.normalizeDegrees(_radToDeg(bearingRad));
  }

  static double _degToRad(double degrees) => degrees * (math.pi / 180);
  static double _radToDeg(double radians) => radians * (180 / math.pi);
}

