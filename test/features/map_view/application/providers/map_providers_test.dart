import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/map_view/application/providers/map_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fakes.dart';

void main() {
  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        routeRepositoryProvider.overrideWithValue(TestRouteRepository()),
        loggerServiceProvider.overrideWithValue(CapturingLoggerService()),
      ],
    );
  }

  test('mapRouteOverlayProvider returns empty route for initial state', () {
    final container = buildContainer();
    addTearDown(container.dispose);

    final overlay = container.read(mapRouteOverlayProvider);

    expect(overlay.points, isEmpty);
    expect(overlay.hasRoute, isFalse);
  });

  test('mapRouteOverlayProvider updates after waypoint changes', () {
    final container = buildContainer();
    addTearDown(container.dispose);

    final controller = container.read(flightPlanningControllerProvider.notifier);
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

    final overlay = container.read(mapRouteOverlayProvider);

    expect(overlay.points, hasLength(2));
    expect(overlay.points.first.latitude, closeTo(52.1657, 0.00001));
    expect(overlay.points.first.longitude, closeTo(20.9671, 0.00001));
    expect(overlay.points.last.latitude, closeTo(50.0777, 0.00001));
    expect(overlay.points.last.longitude, closeTo(19.7848, 0.00001));
    expect(overlay.hasRoute, isTrue);
  });
}
