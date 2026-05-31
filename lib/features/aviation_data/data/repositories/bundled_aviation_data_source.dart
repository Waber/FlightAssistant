import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/aviation_data_meta.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';
import 'package:flight_assistant/features/aviation_data/domain/repositories/aviation_data_repository.dart';
import 'package:flutter/services.dart';

/// Phase 1 repository: reads bundled GeoJSON assets (fully offline).
class BundledAviationDataSource implements AviationDataRepository {
  BundledAviationDataSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  static const _airports = 'assets/aviation_data/airports_pl.geojson';
  static const _vfrPoints = 'assets/aviation_data/vfr_points_pl.geojson';
  static const _airspaces = 'assets/aviation_data/airspaces_pl.geojson';
  static const _meta = 'assets/aviation_data/aviation_data_meta.json';

  @override
  Future<List<Airport>> getAirports() async =>
      AviationDataLoader.parseAirports(await _bundle.loadString(_airports));

  @override
  Future<List<VfrPoint>> getVfrPoints() async =>
      AviationDataLoader.parseVfrPoints(await _bundle.loadString(_vfrPoints));

  @override
  Future<List<Airspace>> getAirspaces() async =>
      AviationDataLoader.parseAirspaces(await _bundle.loadString(_airspaces));

  @override
  Future<AviationDataMeta?> getMeta() async =>
      AviationDataLoader.parseMeta(await _bundle.loadString(_meta));
}
