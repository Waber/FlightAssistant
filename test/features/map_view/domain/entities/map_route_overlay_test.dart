import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/map_view/domain/entities/map_route_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MapRouteOverlay', () {
    test('hasRoute is false for 0 or 1 points', () {
      const empty = MapRouteOverlay(points: <MapPoint>[]);
      const single = MapRouteOverlay(
        points: <MapPoint>[MapPoint(latitude: 52.1, longitude: 21.0)],
      );

      expect(empty.hasRoute, isFalse);
      expect(single.hasRoute, isFalse);
    });

    test('fromWaypoints maps coordinates in order and enables route for 2+ points',
        () {
      final overlay = MapRouteOverlay.fromWaypoints(const [
        Waypoint(
          id: 'wp-1',
          name: 'Start',
          latitude: 52.1657,
          longitude: 20.9671,
          type: WaypointType.departure,
        ),
        Waypoint(
          id: 'wp-2',
          name: 'End',
          latitude: 50.0777,
          longitude: 19.7848,
          type: WaypointType.destination,
        ),
      ]);

      expect(overlay.points, hasLength(2));
      expect(overlay.points.first.latitude, closeTo(52.1657, 0.00001));
      expect(overlay.points.first.longitude, closeTo(20.9671, 0.00001));
      expect(overlay.points.last.latitude, closeTo(50.0777, 0.00001));
      expect(overlay.points.last.longitude, closeTo(19.7848, 0.00001));
      expect(overlay.hasRoute, isTrue);
    });
  });
}
