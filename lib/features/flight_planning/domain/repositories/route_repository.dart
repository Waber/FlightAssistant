import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';

abstract class RouteRepository {
  Future<void> saveRoute(RoutePlan routePlan);
  Future<List<RoutePlan>> getRoutes();
  Future<void> deleteRoute(String routeId);
}

