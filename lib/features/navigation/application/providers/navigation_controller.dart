import 'dart:async';

import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/navigation/data/datasources/gps_datasource.dart';
import 'package:flight_assistant/features/navigation/domain/entities/active_navigation_state.dart';
import 'package:flight_assistant/features/navigation/domain/entities/aircraft_position.dart';
import 'package:flight_assistant/features/navigation/domain/services/navigation_service.dart';
import 'package:flight_assistant/features/navigation/domain/services/waypoint_sequencing_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationRuntimeState {
  const NavigationRuntimeState({
    this.isActive = false,
    this.activeNavigation,
    this.aircraftPosition,
    this.message,
  });

  final bool isActive;
  final ActiveNavigationState? activeNavigation;
  final AircraftPosition? aircraftPosition;
  final String? message;

  NavigationRuntimeState copyWith({
    bool? isActive,
    ActiveNavigationState? activeNavigation,
    bool clearActiveNavigation = false,
    AircraftPosition? aircraftPosition,
    bool clearAircraftPosition = false,
    String? message,
    bool clearMessage = false,
  }) {
    return NavigationRuntimeState(
      isActive: isActive ?? this.isActive,
      activeNavigation:
          clearActiveNavigation ? null : (activeNavigation ?? this.activeNavigation),
      aircraftPosition:
          clearAircraftPosition ? null : (aircraftPosition ?? this.aircraftPosition),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class NavigationController extends StateNotifier<NavigationRuntimeState> {
  NavigationController({
    required GpsDataSource gpsDataSource,
    required NavigationService navigationService,
    required WaypointSequencingService waypointSequencingService,
  })  : _gpsDataSource = gpsDataSource,
        _navigationService = navigationService,
        _waypointSequencingService = waypointSequencingService,
        super(const NavigationRuntimeState());

  final GpsDataSource _gpsDataSource;
  final NavigationService _navigationService;
  final WaypointSequencingService _waypointSequencingService;
  StreamSubscription<AircraftPosition>? _positionSubscription;

  void startNavigation(RoutePlan routePlan) {
    if (routePlan.legs.isEmpty) {
      state = state.copyWith(
        message: 'Cannot start navigation. Route has no legs.',
        clearMessage: false,
      );
      return;
    }

    _positionSubscription?.cancel();
    final firstLeg = routePlan.legs.first;

    state = state.copyWith(
      isActive: true,
      activeNavigation: ActiveNavigationState(
        activeRouteId: routePlan.id,
        activeLegIndex: 0,
        nextWaypoint: firstLeg.toWaypoint,
        distanceToNextNm: null,
        desiredTrackDeg: firstLeg.trueCourseDeg,
        bearingToWaypointDeg: null,
      ),
      clearMessage: true,
    );

    _positionSubscription = _gpsDataSource.watchPosition().listen(
      (position) => _updateState(routePlan, position),
      onError: (_) {
        state = state.copyWith(
          isActive: false,
          message: 'GPS stream failed.',
        );
      },
    );
  }

  void stopNavigation() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    state = state.copyWith(
      isActive: false,
      clearActiveNavigation: true,
      clearAircraftPosition: true,
      clearMessage: true,
    );
  }

  void _updateState(RoutePlan routePlan, AircraftPosition position) {
    final active = state.activeNavigation;
    if (active == null || routePlan.legs.isEmpty) {
      return;
    }

    final clampedLegIndex = active.activeLegIndex.clamp(0, routePlan.legs.length - 1);
    final currentLeg = routePlan.legs[clampedLegIndex];
    final distance = _navigationService.calculateDistanceToWaypointNm(
      aircraftPosition: position,
      nextWaypoint: currentLeg.toWaypoint,
    );
    final bearing = _navigationService.calculateBearingToWaypointDeg(
      aircraftPosition: position,
      nextWaypoint: currentLeg.toWaypoint,
    );

    final resolvedLegIndex = _waypointSequencingService.resolveNextLegIndex(
      currentLegIndex: clampedLegIndex,
      legsCount: routePlan.legs.length,
      distanceToNextNm: distance,
    );
    final resolvedLeg = routePlan.legs[resolvedLegIndex];

    state = state.copyWith(
      aircraftPosition: position,
      activeNavigation: active.copyWith(
        activeLegIndex: resolvedLegIndex,
        nextWaypoint: resolvedLeg.toWaypoint,
        desiredTrackDeg: resolvedLeg.trueCourseDeg,
        distanceToNextNm: distance,
        bearingToWaypointDeg: bearing,
      ),
      clearMessage: true,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
