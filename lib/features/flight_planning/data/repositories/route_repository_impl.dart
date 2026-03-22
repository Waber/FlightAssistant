import 'package:flight_assistant/features/flight_planning/data/datasources/local_route_datasource.dart';
import 'package:flight_assistant/features/flight_planning/data/models/route_plan_model.dart';
import 'package:flight_assistant/features/flight_planning/domain/entities/route_plan.dart';
import 'package:flight_assistant/features/flight_planning/domain/repositories/route_repository.dart';

class RouteRepositoryImpl implements RouteRepository {
  RouteRepositoryImpl(this._localRouteDataSource);

  final LocalRouteDataSource _localRouteDataSource;

  @override
  Future<void> saveRoute(RoutePlan routePlan) {
    return _localRouteDataSource.saveRoute(RoutePlanModel.fromDomain(routePlan));
  }

  @override
  Future<List<RoutePlan>> getRoutes() async {
    final models = await _localRouteDataSource.getRoutes();
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<void> deleteRoute(String routeId) {
    return _localRouteDataSource.deleteRoute(routeId);
  }
}

