enum AirportType { licensed, grass, heliport, military, ultralight, landingStrip, other }

class Airport {
  const Airport({
    required this.id,
    required this.name,
    required this.icaoCode,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  final String id;
  final String name;
  final String icaoCode;
  final double latitude;
  final double longitude;
  final AirportType type;
}
