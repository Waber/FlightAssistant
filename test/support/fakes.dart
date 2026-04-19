import 'package:flight_assistant/core/services/logger_service.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/flight_planning/domain/repositories/route_repository.dart';

class TestRouteRepository implements RouteRepository {
  TestRouteRepository({
    List<RoutePlan>? routes,
    this.failOnSave = false,
  }) : _routes = List<RoutePlan>.from(routes ?? const <RoutePlan>[]);

  final List<RoutePlan> _routes;
  final bool failOnSave;

  RoutePlan? lastSavedRoute;
  String? deletedRouteId;

  @override
  Future<void> saveRoute(RoutePlan routePlan) async {
    if (failOnSave) {
      throw Exception('save failed');
    }

    lastSavedRoute = routePlan;
    _routes.removeWhere((route) => route.id == routePlan.id);
    _routes.add(routePlan);
  }

  @override
  Future<List<RoutePlan>> getRoutes() async {
    return List<RoutePlan>.unmodifiable(_routes);
  }

  @override
  Future<void> deleteRoute(String routeId) async {
    deletedRouteId = routeId;
    _routes.removeWhere((route) => route.id == routeId);
  }
}

class CapturingLoggerService extends LoggerService {
  final List<String> messages = <String>[];

  @override
  void log(String message) {
    messages.add(message);
  }
}
