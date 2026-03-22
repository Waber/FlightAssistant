import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/flight_planning/domain/services/route_calculation_service.dart';

class AddWaypointUseCase {
  AddWaypointUseCase(this._routeCalculationService);

  final RouteCalculationService _routeCalculationService;

  RoutePlan call({
    required RoutePlan routePlan,
    required Waypoint waypoint,
  }) {
    final updatedRoute = routePlan.copyWith(
      waypoints: [...routePlan.waypoints, waypoint],
    );
    return _routeCalculationService.calculate(updatedRoute);
  }
}

