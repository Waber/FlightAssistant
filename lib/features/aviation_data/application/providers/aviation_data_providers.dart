import 'package:flight_assistant/features/aviation_data/data/datasources/aviation_data_loader.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final airportsProvider = FutureProvider<List<Airport>>(
  (ref) => AviationDataLoader.loadAirports(),
);

final vfrPointsProvider = FutureProvider<List<VfrPoint>>(
  (ref) => AviationDataLoader.loadVfrPoints(),
);

final airspacesProvider = FutureProvider<List<Airspace>>(
  (ref) => AviationDataLoader.loadAirspaces(),
);
