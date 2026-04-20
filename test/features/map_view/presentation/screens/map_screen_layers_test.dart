import 'package:flight_assistant/features/aviation_data/application/providers/aviation_data_providers.dart';
import 'package:flight_assistant/features/aviation_data/application/providers/layer_visibility_provider.dart';
import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
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

  testWidgets('tapping layers button opens bottom sheet', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Map Layers'), findsOneWidget);
    expect(find.text('Airports'), findsOneWidget);
    expect(find.text('VFR Reporting Points'), findsOneWidget);
    expect(find.text('Airspaces'), findsOneWidget);
  });

  testWidgets('toggling Airports switch updates layerVisibilityProvider',
      (tester) async {
    final container = ProviderContainer(overrides: baseOverrides);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();

    expect(container.read(layerVisibilityProvider).showAirports, isTrue);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(container.read(layerVisibilityProvider).showAirports, isFalse);
  });

  testWidgets('toggling Airspaces switch updates layerVisibilityProvider',
      (tester) async {
    final container = ProviderContainer(overrides: baseOverrides);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.layers_outlined));
    await tester.pumpAndSettle();

    expect(container.read(layerVisibilityProvider).showAirspaces, isTrue);

    await tester.tap(find.byType(Switch).at(2));
    await tester.pumpAndSettle();

    expect(container.read(layerVisibilityProvider).showAirspaces, isFalse);
  });
}
