class AviationDataMeta {
  const AviationDataMeta({
    required this.source,
    required this.license,
    required this.generatedAt,
    required this.dataAsOf,
    required this.airportCount,
    required this.vfrPointCount,
    required this.airspaceCount,
  });

  final String source;
  final String license;
  final String generatedAt; // ISO date, e.g. "2026-05-31"
  final String dataAsOf; // ISO date the source data is current as of
  final int airportCount;
  final int vfrPointCount;
  final int airspaceCount;
}
