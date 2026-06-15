import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/aviation_data_meta.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';

abstract class AviationDataRepository {
  Future<List<Airport>> getAirports();
  Future<List<VfrPoint>> getVfrPoints();
  Future<List<Airspace>> getAirspaces();
  Future<AviationDataMeta?> getMeta();
}
