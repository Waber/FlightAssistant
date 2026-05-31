enum AirspaceType {
  ctr,
  tma,
  mctr,
  atz,
  danger,
  restricted,
  prohibited,
  tsa,
  tra,
  rmz,
  tmz,
  other,
}

class Airspace {
  const Airspace({
    required this.id,
    required this.name,
    required this.type,
    required this.airspaceClass,
    required this.ceiling,
    required this.floor,
    required this.polygon,
  });

  final String id;
  final String name;
  final AirspaceType type;
  final String airspaceClass; // "C", "D", "G", etc.
  final String ceiling; // e.g. "FL100", "2500ft AMSL"
  final String floor; // e.g. "GND", "500ft AGL"
  final List<(double lat, double lon)> polygon;
}
