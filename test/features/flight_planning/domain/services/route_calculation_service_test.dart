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
  });
}

