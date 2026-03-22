import 'dart:math' as math;

import 'package:flight_assistant/core/constants/app_constants.dart';

class DistanceUtils {
  static double calculateDistanceNm({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
  }) {
    final fromLatRad = _degToRad(fromLatitude);
    final toLatRad = _degToRad(toLatitude);
    final deltaLatRad = _degToRad(toLatitude - fromLatitude);
    final deltaLonRad = _degToRad(toLongitude - fromLongitude);

    final haversine = math.pow(math.sin(deltaLatRad / 2), 2) +
        math.cos(fromLatRad) *
            math.cos(toLatRad) *
            math.pow(math.sin(deltaLonRad / 2), 2);
    final centralAngle = 2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
    return AppConstants.earthRadiusNm * centralAngle;
  }

  static double _degToRad(double degrees) => degrees * (math.pi / 180);
}

