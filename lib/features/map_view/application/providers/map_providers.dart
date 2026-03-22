import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/map_view/domain/entities/map_route_overlay.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final mapRouteOverlayProvider = Provider<MapRouteOverlay>((ref) {
  final routePlan = ref.watch(flightPlanningControllerProvider).routePlan;
  return MapRouteOverlay.fromWaypoints(routePlan.waypoints);
});

