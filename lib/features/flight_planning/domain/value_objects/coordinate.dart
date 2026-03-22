import 'package:flight_assistant/core/errors/app_exception.dart';

class Coordinate {
  Coordinate({
    required this.latitude,
    required this.longitude,
  }) {
    if (latitude < -90 || latitude > 90) {
      throw AppException('Latitude must be within -90..90.');
    }
    if (longitude < -180 || longitude > 180) {
      throw AppException('Longitude must be within -180..180.');
    }
  }

  final double latitude;
  final double longitude;
}

