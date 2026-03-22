import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';

class RouteSummary {
  const RouteSummary({
    required this.totalDistanceNm,
    required this.legCount,
    required this.waypointCount,
  });

  final double totalDistanceNm;
  final int legCount;
  final int waypointCount;
}

class CalculateRouteSummaryUseCase {
  RouteSummary call(RoutePlan routePlan) {
    return RouteSummary(
      totalDistanceNm: routePlan.totalDistanceNm,
      legCount: routePlan.legs.length,
      waypointCount: routePlan.waypoints.length,
    );
  }
}

