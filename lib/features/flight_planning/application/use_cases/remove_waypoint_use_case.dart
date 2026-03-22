import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/flight_planning/domain/services/route_calculation_service.dart';

class RemoveWaypointUseCase {
  RemoveWaypointUseCase(this._routeCalculationService);

  final RouteCalculationService _routeCalculationService;

  RoutePlan call({
    required RoutePlan routePlan,
    required String waypointId,
  }) {
    final updatedWaypoints = routePlan.waypoints
        .where((waypoint) => waypoint.id != waypointId)
        .toList();
    return _routeCalculationService.calculate(
      routePlan.copyWith(waypoints: updatedWaypoints),
    );
  }
}

