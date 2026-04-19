import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/map_platform_mocks.dart';
import '../support/test_app.dart';

void main() {
  setUpAll(installMapPlatformMocks);
  tearDownAll(removeMapPlatformMocks);

  testWidgets('navigates across the main tabs and renders saved routes',
      (tester) async {
    final savedRoute = RoutePlan.empty(
      id: 'route-99',
      name: 'Stored route',
      now: DateTime(2026, 1, 1),
    ).copyWith(
      waypoints: const [
        Waypoint(
          id: 'wp-1',
          name: 'EPWA',
          latitude: 52.1657,
          longitude: 20.9671,
          type: WaypointType.departure,
        ),
      ],
      totalDistanceNm: 0,
    );

    await tester.pumpWidget(
      buildTestApp(
        routeRepository: TestRouteRepository(routes: [savedRoute]),
        loggerService: CapturingLoggerService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Flight Planning'), findsOneWidget);

    final navigationBar = find.byType(NavigationBar);

    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Saved')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saved Routes'), findsOneWidget);
    expect(find.text('Stored route'), findsOneWidget);
    expect(find.text('1 waypoints  -  0.0 NM'), findsOneWidget);

    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Settings')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Map provider'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);

    await tester.tap(
      find.descendant(of: navigationBar, matching: find.text('Plan')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flight Planning'), findsOneWidget);
  });
}
