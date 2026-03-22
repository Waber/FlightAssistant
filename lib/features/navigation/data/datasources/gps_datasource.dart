import 'dart:async';
import 'dart:math' as math;

import 'package:flight_assistant/features/navigation/domain/entities/aircraft_position.dart';

class GpsDataSource {
  Stream<AircraftPosition> watchPosition() {
    return Stream<AircraftPosition>.periodic(
      const Duration(seconds: 1),
      (tick) {
        final angle = tick / 8;
        return AircraftPosition(
          latitude: 52.2297 + (0.02 * math.sin(angle)),
          longitude: 21.0122 + (0.02 * math.cos(angle)),
          groundSpeedKt: 96,
          trackDeg: 120,
          timestamp: DateTime.now(),
        );
      },
    );
  }
}

