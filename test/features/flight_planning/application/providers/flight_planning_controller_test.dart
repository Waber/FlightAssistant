import 'package:flight_assistant/core/services/logger_service.dart';
import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_controller.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/add_waypoint_use_case.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/create_route_use_case.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/remove_waypoint_use_case.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/reorder_waypoints_use_case.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/flight_planning/domain/repositories/route_repository.dart';
import 'package:flight_assistant/features/flight_planning/domain/services/route_calculation_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fakes.dart';

void main() {
  late TestRouteRepository routeRepository;
  late CapturingLoggerService loggerService;
  late FlightPlanningController controller;

  FlightPlanningController buildController({
    required RouteRepository routeRepository,
    required LoggerService loggerService,
    required RoutePlan initialRoute,
  }) {
    final routeCalculationService = RouteCalculationService();
    return FlightPlanningController(
      initialRoute: initialRoute,
      addWaypointUseCase: AddWaypointUseCase(routeCalculationService),
      removeWaypointUseCase: RemoveWaypointUseCase(routeCalculationService),
      reorderWaypointsUseCase: ReorderWaypointsUseCase(routeCalculationService),
      createRouteUseCase: CreateRouteUseCase(),
      routeRepository: routeRepository,
      loggerService: loggerService,
    );
  }

  setUp(() {
    routeRepository = TestRouteRepository();
    loggerService = CapturingLoggerService();
    controller = buildController(
      routeRepository: routeRepository,
      loggerService: loggerService,
      initialRoute: RoutePlan.empty(
        id: 'route-1',
        name: 'New Route',
        now: DateTime(2026, 1, 1),
      ),
    );
  });

  test('addWaypoint recalculates the route and keeps the new waypoint', () {
    controller.addWaypoint(
      name: 'EPWA',
      latitude: 52.1657,
      longitude: 20.9671,
      type: WaypointType.departure,
    );
    controller.addWaypoint(
      name: 'EPKK',
      latitude: 50.0777,
      longitude: 19.7848,
      type: WaypointType.destination,
    );

    expect(controller.state.routePlan.waypoints, hasLength(2));
    expect(controller.state.routePlan.legs, hasLength(1));
    expect(controller.state.routePlan.legs.single.fromWaypoint.name, 'EPWA');
    expect(controller.state.routePlan.legs.single.toWaypoint.name, 'EPKK');
    expect(controller.state.routePlan.totalDistanceNm, greaterThan(100));
    expect(controller.state.errorMessage, isNull);
  });

  test('reorderWaypoint changes waypoint order and keeps route consistent', () {
    controller.addWaypoint(
      name: 'A',
      latitude: 52.0,
      longitude: 20.0,
      type: WaypointType.enroute,
    );
    controller.addWaypoint(
      name: 'B',
      latitude: 51.0,
      longitude: 21.0,
      type: WaypointType.enroute,
    );
    controller.addWaypoint(
      name: 'C',
      latitude: 50.0,
      longitude: 22.0,
      type: WaypointType.destination,
    );

    controller.reorderWaypoint(oldIndex: 2, newIndex: 0);

    expect(
      controller.state.routePlan.waypoints.map((waypoint) => waypoint.name),
      ['C', 'A', 'B'],
    );
    expect(controller.state.routePlan.legs, hasLength(2));
    expect(controller.state.errorMessage, isNull);
  });

  test('updateRouteName trims whitespace and ignores empty input', () {
    controller.updateRouteName('  Training Route  ');

    expect(controller.state.routePlan.name, 'Training Route');
    final updatedAtAfterRename = controller.state.routePlan.updatedAt;

    controller.updateRouteName('   ');

    expect(controller.state.routePlan.name, 'Training Route');
    expect(controller.state.routePlan.updatedAt, updatedAtAfterRename);
  });

  test('saveCurrentRoute persists the route and clears the busy state', () async {
    controller.addWaypoint(
      name: 'EPWA',
      latitude: 52.1657,
      longitude: 20.9671,
      type: WaypointType.departure,
    );

    final saved = await controller.saveCurrentRoute();

    expect(saved, isTrue);
    expect(controller.state.isBusy, isFalse);
    expect(routeRepository.lastSavedRoute, isNotNull);
    expect(routeRepository.lastSavedRoute!.id, controller.state.routePlan.id);
    expect(loggerService.messages, contains('Route saved: ${controller.state.routePlan.id}'));
  });

  test('saveCurrentRoute reports a failure from the repository', () async {
    routeRepository = TestRouteRepository(failOnSave: true);
    controller = buildController(
      routeRepository: routeRepository,
      loggerService: loggerService,
      initialRoute: RoutePlan.empty(
        id: 'route-1',
        name: 'New Route',
        now: DateTime(2026, 1, 1),
      ),
    );

    final saved = await controller.saveCurrentRoute();

    expect(saved, isFalse);
    expect(controller.state.isBusy, isFalse);
    expect(controller.state.errorMessage, 'Unable to save route locally.');
    expect(loggerService.messages.single, startsWith('Unable to save route:'));
  });
}
