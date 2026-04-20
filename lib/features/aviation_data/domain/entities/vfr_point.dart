class VfrPoint {
  const VfrPoint({
    required this.id,
    required this.name,
    required this.code,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String code; // e.g. "LIMA", "PAPA"
  final double latitude;
  final double longitude;
}
