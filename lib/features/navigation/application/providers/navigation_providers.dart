import 'package:flight_assistant/features/navigation/application/providers/navigation_controller.dart';
import 'package:flight_assistant/features/navigation/data/datasources/gps_datasource.dart';
import 'package:flight_assistant/features/navigation/domain/services/navigation_service.dart';
import 'package:flight_assistant/features/navigation/domain/services/waypoint_sequencing_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final gpsDataSourceProvider = Provider<GpsDataSource>((ref) => GpsDataSource());

final navigationServiceProvider = Provider<NavigationService>((ref) {
  return NavigationService();
});

final waypointSequencingServiceProvider = Provider<WaypointSequencingService>((ref) {
  return WaypointSequencingService();
});

final navigationControllerProvider =
    StateNotifierProvider<NavigationController, NavigationRuntimeState>((ref) {
  return NavigationController(
    gpsDataSource: ref.watch(gpsDataSourceProvider),
    navigationService: ref.watch(navigationServiceProvider),
    waypointSequencingService: ref.watch(waypointSequencingServiceProvider),
  );
});

