import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/flight_planning/presentation/widgets/waypoint_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows an empty state when no waypoints are available',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WaypointList(
            waypoints: <Waypoint>[],
            onDelete: _noopDelete,
            onMoveUp: _noopMove,
            onMoveDown: _noopMove,
          ),
        ),
      ),
    );

    expect(find.text('No waypoints yet. Add your first one.'), findsOneWidget);
  });

  testWidgets('renders waypoint rows and forwards interaction callbacks',
      (tester) async {
    final deletedIds = <String>[];
    final moveUpIndexes = <int>[];
    final moveDownIndexes = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WaypointList(
            waypoints: const [
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
            onDelete: deletedIds.add,
            onMoveUp: moveUpIndexes.add,
            onMoveDown: moveDownIndexes.add,
          ),
        ),
      ),
    );

    expect(find.text('EPWA'), findsOneWidget);
    expect(find.text('EPKK'), findsOneWidget);

    await tester.tap(find.byTooltip('Move down').first);
    await tester.pump();
    await tester.tap(find.byTooltip('Move up').last);
    await tester.pump();
    await tester.tap(find.byTooltip('Delete waypoint').first);
    await tester.pump();

    expect(moveDownIndexes, [0]);
    expect(moveUpIndexes, [1]);
    expect(deletedIds, ['wp-1']);
  });
}

void _noopDelete(String value) {}

void _noopMove(int value) {}
