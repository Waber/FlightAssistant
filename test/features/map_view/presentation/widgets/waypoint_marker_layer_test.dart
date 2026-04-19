import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/map_view/presentation/widgets/waypoint_marker_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre/maplibre.dart';

void main() {
  testWidgets('renders WidgetLayer when waypoints are provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WaypointMarkerLayer(
            waypoints: [
              Waypoint(
                id: 'wp-1',
                name: 'EPWA',
                latitude: 52.1657,
                longitude: 20.9671,
                type: WaypointType.departure,
              ),
              Waypoint(
                id: 'wp-2',
                name: 'EPKK',
                latitude: 50.0777,
                longitude: 19.7848,
                type: WaypointType.destination,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(WidgetLayer), findsOneWidget);
  });

  testWidgets('renders nothing for empty waypoint list', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WaypointMarkerLayer(waypoints: []),
        ),
      ),
    );

    expect(find.byType(WidgetLayer), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });
}
