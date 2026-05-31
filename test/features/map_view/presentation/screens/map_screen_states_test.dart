import 'dart:async';

import 'package:flight_assistant/features/aviation_data/application/providers/aviation_data_providers.dart';
import 'package:flight_assistant/features/aviation_data/domain/entities/airport.dart';
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

  final base = [
    routeRepositoryProvider.overrideWithValue(TestRouteRepository()),
    loggerServiceProvider.overrideWithValue(CapturingLoggerService()),
  ];

  testWidgets('shows a loading indicator while aviation data loads',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...base,
          // Never-completing future -> provider stays in loading state.
          airportsProvider
              .overrideWith((ref) => Completer<List<Airport>>().future),
          vfrPointsProvider.overrideWith((ref) async => []),
          airspacesProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pump(); // do not settle (future never completes)
    expect(find.byKey(const Key('aviation-loading')), findsOneWidget);
  });

  testWidgets('shows a SnackBar when aviation data fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...base,
          airportsProvider.overrideWith((ref) async => throw Exception('boom')),
          vfrPointsProvider.overrideWith((ref) async => []),
          airspacesProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(home: MapScreen()),
      ),
    );
    await tester.pump(); // let the error microtask run
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.textContaining('aviation data'), findsOneWidget);
  });
}
