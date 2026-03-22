import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/flight_planning/domain/services/route_calculation_service.dart';

class ReorderWaypointsUseCase {
  ReorderWaypointsUseCase(this._routeCalculationService);

  final RouteCalculationService _routeCalculationService;

  RoutePlan call({
    required RoutePlan routePlan,
    required int oldIndex,
    required int newIndex,
  }) {
    if (oldIndex < 0 || oldIndex >= routePlan.waypoints.length) {
      return routePlan;
    }
    if (newIndex < 0 || newIndex >= routePlan.waypoints.length) {
      return routePlan;
    }

    final updatedWaypoints = [...routePlan.waypoints];
    final moved = updatedWaypoints.removeAt(oldIndex);
    updatedWaypoints.insert(newIndex, moved);

    return _routeCalculationService.calculate(
      routePlan.copyWith(waypoints: updatedWaypoints),
    );
  }
}

