import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';

class CreateRouteUseCase {
  RoutePlan call({
    required String id,
    required String name,
  }) {
    return RoutePlan.empty(
      id: id,
      name: name,
    );
  }
}

