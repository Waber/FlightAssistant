import 'package:flight_assistant/core/services/logger_service.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/add_waypoint_use_case.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/create_route_use_case.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/remove_waypoint_use_case.dart';
import 'package:flight_assistant/features/flight_planning/application/use_cases/reorder_waypoints_use_case.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/flight_planning/domain/repositories/route_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class FlightPlanningState {
  const FlightPlanningState({
    required this.routePlan,
    this.isBusy = false,
    this.errorMessage,
  });

  final RoutePlan routePlan;
  final bool isBusy;
  final String? errorMessage;

  FlightPlanningState copyWith({
    RoutePlan? routePlan,
    bool? isBusy,
    String? errorMessage,
  }) {
    return FlightPlanningState(
      routePlan: routePlan ?? this.routePlan,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: errorMessage,
    );
  }
}

class FlightPlanningController extends StateNotifier<FlightPlanningState> {
  FlightPlanningController({
    required RoutePlan initialRoute,
    required AddWaypointUseCase addWaypointUseCase,
    required RemoveWaypointUseCase removeWaypointUseCase,
    required ReorderWaypointsUseCase reorderWaypointsUseCase,
    required CreateRouteUseCase createRouteUseCase,
    required RouteRepository routeRepository,
    required LoggerService loggerService,
  })  : _addWaypointUseCase = addWaypointUseCase,
        _removeWaypointUseCase = removeWaypointUseCase,
        _reorderWaypointsUseCase = reorderWaypointsUseCase,
        _createRouteUseCase = createRouteUseCase,
        _routeRepository = routeRepository,
        _loggerService = loggerService,
        super(FlightPlanningState(routePlan: initialRoute));

  final AddWaypointUseCase _addWaypointUseCase;
  final RemoveWaypointUseCase _removeWaypointUseCase;
  final ReorderWaypointsUseCase _reorderWaypointsUseCase;
  final CreateRouteUseCase _createRouteUseCase;
  final RouteRepository _routeRepository;
  final LoggerService _loggerService;
  final Uuid _uuid = const Uuid();

  void addWaypoint({
    required String name,
    required double latitude,
    required double longitude,
    required WaypointType type,
  }) {
    try {
      final waypoint = Waypoint(
        id: _uuid.v4(),
        name: name,
        latitude: latitude,
        longitude: longitude,
        type: type,
      );
      final updatedRoute = _addWaypointUseCase(
        routePlan: state.routePlan,
        waypoint: waypoint,
      );
      state = state.copyWith(
        routePlan: updatedRoute,
        errorMessage: null,
      );
    } catch (error) {
      _loggerService.log('Unable to add waypoint: $error');
      state = state.copyWith(errorMessage: 'Unable to add waypoint.');
    }
  }

  void removeWaypoint(String waypointId) {
    final updatedRoute = _removeWaypointUseCase(
      routePlan: state.routePlan,
      waypointId: waypointId,
    );
    state = state.copyWith(
      routePlan: updatedRoute,
      errorMessage: null,
    );
  }

  void reorderWaypoint({
    required int oldIndex,
    required int newIndex,
  }) {
    final updatedRoute = _reorderWaypointsUseCase(
      routePlan: state.routePlan,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    state = state.copyWith(
      routePlan: updatedRoute,
      errorMessage: null,
    );
  }

  Future<void> saveCurrentRoute() async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      await _routeRepository.saveRoute(state.routePlan);
      _loggerService.log('Route saved: ${state.routePlan.id}');
      state = state.copyWith(isBusy: false, errorMessage: null);
    } catch (error) {
      _loggerService.log('Unable to save route: $error');
      state = state.copyWith(
        isBusy: false,
        errorMessage: 'Unable to save route locally.',
      );
    }
  }

  void startNewRoute({String name = 'New Route'}) {
    final newRoute = _createRouteUseCase(
      id: _uuid.v4(),
      name: name,
    );
    state = state.copyWith(
      routePlan: newRoute,
      errorMessage: null,
    );
  }

  void updateRouteName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    state = state.copyWith(
      routePlan: state.routePlan.copyWith(
        name: trimmed,
        updatedAt: DateTime.now(),
      ),
      errorMessage: null,
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
