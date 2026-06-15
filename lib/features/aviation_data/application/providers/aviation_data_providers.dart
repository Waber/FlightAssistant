import 'package:flight_assistant/features/aviation_data/data/repositories/bundled_aviation_data_source.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airspace.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/aviation_data_meta.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/vfr_point.dart';
import 'package:flight_assistant/features/aviation_data/domain/repositories/aviation_data_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single seam for aviation data. Phase 2 overrides this with a repository
/// that prefers freshest-of {remote, cached, bundled} — providers/UI unchanged.
final aviationDataRepositoryProvider = Provider<AviationDataRepository>(
  (ref) => BundledAviationDataSource(),
);

final airportsProvider = FutureProvider<List<Airport>>(
  (ref) => ref.watch(aviationDataRepositoryProvider).getAirports(),
);

final vfrPointsProvider = FutureProvider<List<VfrPoint>>(
  (ref) => ref.watch(aviationDataRepositoryProvider).getVfrPoints(),
);

final airspacesProvider = FutureProvider<List<Airspace>>(
  (ref) => ref.watch(aviationDataRepositoryProvider).getAirspaces(),
);

final aviationDataMetaProvider = FutureProvider<AviationDataMeta?>(
  (ref) => ref.watch(aviationDataRepositoryProvider).getMeta(),
);
