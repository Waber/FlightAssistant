import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/waypoint.dart';
import 'package:flight_assistant/features/flight_planning/domain/services/route_calculation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteCalculationService.calculate', () {
    test('creates legs and total distance from waypoint list', () {
      final service = RouteCalculationService();
      final route = RoutePlan.empty(id: 'route-1', name: 'Demo route').copyWith(
        waypoints: const [
          Waypoint(
            id: 'w1',
            name: 'EPWA',
            latitude: 52.1657,
            longitude: 20.9671,
            type: WaypointType.departure,
          ),
          Waypoint(
            id: 'w2',
            name: 'EPKK',
            latitude: 50.0777,
            longitude: 19.7848,
            type: WaypointType.destination,
          ),
        ],
      );

      final result = service.calculate(route);

      expect(result.legs.length, 1);
      expect(result.totalDistanceNm, greaterThan(100));
    });

    test('buildLegs creates consecutive legs for a multi-waypoint route', () {
      final service = RouteCalculationService();
      final waypoints = [
        const Waypoint(
          id: 'w1',
          name: 'Start',
          latitude: 52.2297,
          longitude: 21.0122,
          type: WaypointType.departure,
        ),
        const Waypoint(
          id: 'w2',
          name: 'Middle',
          latitude: 51.7592,
          longitude: 19.4560,
          type: WaypointType.enroute,
        ),
        const Waypoint(
          id: 'w3',
          name: 'End',
          latitude: 50.0647,
          longitude: 19.9450,
          type: WaypointType.destination,
        ),
      ];

      final legs = service.buildLegs(waypoints);

      expect(legs, hasLength(2));
      expect(legs.first.fromWaypoint.name, 'Start');
      expect(legs.first.toWaypoint.name, 'Middle');
      expect(legs.last.fromWaypoint.name, 'Middle');
      expect(legs.last.toWaypoint.name, 'End');
    });
  });
}
