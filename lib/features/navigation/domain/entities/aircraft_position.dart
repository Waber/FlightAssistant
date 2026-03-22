class AircraftPosition {
  const AircraftPosition({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitudeFt,
    this.groundSpeedKt,
    this.trackDeg,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? altitudeFt;
  final double? groundSpeedKt;
  final double? trackDeg;
}

