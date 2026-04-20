import 'package:flight_assistant/features/aviation_data/application/providers/aviation_data_providers.dart';
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

  final baseOverrides = [
    routeRepositoryProvider.overrideWithValue(TestRouteRepository()),
    loggerServiceProvider.overrideWithValue(CapturingLoggerService()),
    airportsProvider.overrideWith((ref) async => []),
    vfrPointsProvider.overrideWith((ref) async => []),
    airspacesProvider.overrideWith((ref) async => []),
  ];

  testWidgets('renders Map View title', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Map View'), findsOneWidget);
  });

  testWidgets('navigation bar has 4 destinations', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    // Plan, Map, Saved, Settings
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('renders layers icon button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
  });

  testWidgets('renders with waypoint data', (tester) async {
    final container = ProviderContainer(overrides: baseOverrides);
    addTearDown(container.dispose);
    container.read(flightPlanningControllerProvider.notifier).addWaypoint(
      name: 'EPWA',
      latitude: 52.1657,
      longitude: 20.9671,
      type: WaypointType.departure,
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Map View'), findsOneWidget);
  });
}
