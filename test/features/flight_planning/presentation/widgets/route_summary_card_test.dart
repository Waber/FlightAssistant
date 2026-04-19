import 'package:flight_assistant/features/flight_planning/application/use_cases/calculate_route_summary_use_case.dart';
import 'package:flight_assistant/features/flight_planning/presentation/widgets/route_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders summary values with nautical mile formatting',
      (tester) async {
    const summary = RouteSummary(
      totalDistanceNm: 145.2,
      legCount: 2,
      waypointCount: 3,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RouteSummaryCard(summary: summary),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('145.2 NM'), findsOneWidget);
    expect(find.text('Waypoints'), findsOneWidget);
    expect(find.text('Legs'), findsOneWidget);
    expect(find.text('Distance'), findsOneWidget);
  });
}
