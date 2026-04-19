import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/map_view/presentation/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fakes.dart';
import '../../../../support/map_platform_mocks.dart';

void main() {
  setUpAll(installMapPlatformMocks);
  tearDownAll(removeMapPlatformMocks);

  testWidgets('renders map screen shell with empty route state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routeRepositoryProvider.overrideWithValue(TestRouteRepository()),
          loggerServiceProvider.overrideWithValue(CapturingLoggerService()),
        ],
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Map View'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('renders map screen shell with waypoint data', (tester) async {
    final container = ProviderContainer(
      overrides: [
        routeRepositoryProvider.overrideWithValue(TestRouteRepository()),
        loggerServiceProvider.overrideWithValue(CapturingLoggerService()),
      ],
    );
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

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Map View'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
