import 'package:flight_assistant/core/services/logger_service.dart';
import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_controller.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/add_waypoint_use_case.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/calculate_route_summary_use_case.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/create_route_use_case.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/remove_waypoint_use_case.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/reorder_waypoints_use_case.dart';
import 'package:flight_assistant/features/flight_planning/data/datasources/local_route_datasource.dart';
import 'package:flight_assistant/features/flight_planning/data/repositories/route_repository_impl.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/flight_planning/domain/repositories/route_repository.dart';
import 'package:flight_assistant/features/flight_planning/domain/services/route_calculation_service.dart';
import 'package:flight_assistant/features/route_storage/data/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService();
});

final routeCalculationServiceProvider =
    Provider<RouteCalculationService>((ref) {
  return RouteCalculationService();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final appDatabase = AppDatabase();
  ref.onDispose(() {
    appDatabase.close();
  });
  return appDatabase;
});

final localRouteDataSourceProvider = Provider<LocalRouteDataSource>((ref) {
  return LocalRouteDataSource(ref.watch(appDatabaseProvider));
});

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepositoryImpl(ref.watch(localRouteDataSourceProvider));
});

final createRouteUseCaseProvider = Provider<CreateRouteUseCase>((ref) {
  return CreateRouteUseCase();
});

final addWaypointUseCaseProvider = Provider<AddWaypointUseCase>((ref) {
  return AddWaypointUseCase(ref.watch(routeCalculationServiceProvider));
});

final removeWaypointUseCaseProvider = Provider<RemoveWaypointUseCase>((ref) {
  return RemoveWaypointUseCase(ref.watch(routeCalculationServiceProvider));
});

final reorderWaypointsUseCaseProvider =
    Provider<ReorderWaypointsUseCase>((ref) {
  return ReorderWaypointsUseCase(ref.watch(routeCalculationServiceProvider));
});

final calculateRouteSummaryUseCaseProvider =
    Provider<CalculateRouteSummaryUseCase>((ref) {
  return CalculateRouteSummaryUseCase();
});

final initialRouteProvider = Provider<RoutePlan>((ref) {
  final createRouteUseCase = ref.watch(createRouteUseCaseProvider);
  return createRouteUseCase(
    id: const Uuid().v4(),
    name: 'New Route',
  );
});

final flightPlanningControllerProvider =
    StateNotifierProvider<FlightPlanningController, FlightPlanningState>((ref) {
  return FlightPlanningController(
    initialRoute: ref.watch(initialRouteProvider),
    addWaypointUseCase: ref.watch(addWaypointUseCaseProvider),
    removeWaypointUseCase: ref.watch(removeWaypointUseCaseProvider),
    reorderWaypointsUseCase: ref.watch(reorderWaypointsUseCaseProvider),
    createRouteUseCase: ref.watch(createRouteUseCaseProvider),
    routeRepository: ref.watch(routeRepositoryProvider),
    loggerService: ref.watch(loggerServiceProvider),
  );
});

final currentRouteSummaryProvider = Provider<RouteSummary>((ref) {
  final routePlan = ref.watch(flightPlanningControllerProvider).routePlan;
  final useCase = ref.watch(calculateRouteSummaryUseCaseProvider);
  return useCase(routePlan);
});
