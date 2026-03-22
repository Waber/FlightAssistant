import 'package:flight_assistant/features/flight_planning/application/providers/flight_planning_providers.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final savedRoutesProvider = FutureProvider<List<RoutePlan>>((ref) async {
  final repository = ref.watch(routeRepositoryProvider);
  return repository.getRoutes();
});

