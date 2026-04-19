import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fakes.dart';
import '../../../../support/map_platform_mocks.dart';
import '../../../../support/test_app.dart';

void main() {
  setUpAll(installMapPlatformMocks);
  tearDownAll(removeMapPlatformMocks);

  testWidgets('adds a waypoint and updates the planning summary',
      (tester) async {
    await tester.pumpWidget(buildFlightPlanningScreen(
      routeRepository: TestRouteRepository(),
      loggerService: CapturingLoggerService(),
    ));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(1), 'EPWA');
    await tester.enterText(textFields.at(2), '52.1657');
    await tester.enterText(textFields.at(3), '20.9671');

    await tester.ensureVisible(find.text('Add waypoint'));
    await tester.tap(find.text('Add waypoint'));
    await tester.pumpAndSettle();

    expect(find.text('EPWA'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
    expect(find.text('No waypoints yet. Add your first one.'), findsNothing);
  });

  testWidgets('rejects invalid coordinates without adding a waypoint',
      (tester) async {
    await tester.pumpWidget(buildFlightPlanningScreen(
      routeRepository: TestRouteRepository(),
      loggerService: CapturingLoggerService(),
    ));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(1), 'Bad waypoint');
    await tester.enterText(textFields.at(2), '91');
    await tester.enterText(textFields.at(3), '20');

    await tester.ensureVisible(find.text('Add waypoint'));
    await tester.tap(find.text('Add waypoint'));
    await tester.pumpAndSettle();

    expect(find.text('Coordinates are out of range.'), findsOneWidget);
    expect(find.text('No waypoints yet. Add your first one.'), findsOneWidget);
  });
}
