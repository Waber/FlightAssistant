import 'dart:io';

import 'package:flight_assistant/features/flight_planning/data/datasources/local_route_datasource.dart';
import 'package:flight_assistant/features/flight_planning/data/models/leg_model.dart';
import 'package:flight_assistant/features/flight_planning/data/models/route_plan_model.dart';
import 'package:flight_assistant/features/flight_planning/data/models/waypoint_model.dart';
import 'package:flight_assistant/features/route_storage/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('LocalRouteDataSource (SQLite)', () {
    late Directory tempDir;
    late AppDatabase appDatabase;
    late LocalRouteDataSource dataSource;

    setUp(() async {
      sqfliteFfiInit();
      tempDir = await Directory.systemTemp.createTemp('fa_route_ds_');
      appDatabase = AppDatabase(
        databaseFactory: databaseFactoryFfi,
        databasesPathProvider: () async => tempDir.path,
        databaseName: 'routes_test.db',
      );
      dataSource = LocalRouteDataSource(appDatabase);
    });

    tearDown(() async {
      await appDatabase.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('saveRoute and getRoutes persist route with waypoints and legs',
        () async {
      final route = _buildRoute(
        id: 'route-1',
        updatedAtIso: '2026-03-22T10:00:00.000Z',
      );

      await dataSource.saveRoute(route);
      final routes = await dataSource.getRoutes();

      expect(routes, hasLength(1));
      expect(routes.first.id, 'route-1');
      expect(routes.first.name, 'Training route');
      expect(routes.first.waypoints.map((waypoint) => waypoint.id),
          ['wp-1', 'wp-2']);
      expect(routes.first.legs, hasLength(1));
      expect(routes.first.legs.first.fromWaypointId, 'wp-1');
      expect(routes.first.legs.first.toWaypointId, 'wp-2');
      expect(routes.first.totalDistanceNm, closeTo(123.4, 0.001));
    });

    test('getRoutes returns routes sorted by updatedAt descending', () async {
      final olderRoute = _buildRoute(
        id: 'route-old',
        updatedAtIso: '2026-03-21T10:00:00.000Z',
      );
      final newerRoute = _buildRoute(
        id: 'route-new',
        updatedAtIso: '2026-03-22T10:00:00.000Z',
      );

      await dataSource.saveRoute(olderRoute);
      await dataSource.saveRoute(newerRoute);
      final routes = await dataSource.getRoutes();

      expect(routes.map((route) => route.id), ['route-new', 'route-old']);
    });

    test('deleteRoute removes persisted route', () async {
      final route = _buildRoute(
        id: 'route-delete',
        updatedAtIso: '2026-03-22T10:00:00.000Z',
      );

      await dataSource.saveRoute(route);
      await dataSource.deleteRoute('route-delete');
      final routes = await dataSource.getRoutes();

      expect(routes, isEmpty);
    });
  });
}

RoutePlanModel _buildRoute({
  required String id,
  required String updatedAtIso,
}) {
  return RoutePlanModel(
    id: id,
    name: 'Training route',
    waypoints: const [
      WaypointModel(
        id: 'wp-1',
        name: 'EPWA',
        latitude: 52.1657,
        longitude: 20.9671,
        type: 'departure',
      ),
      WaypointModel(
        id: 'wp-2',
        name: 'EPKK',
        latitude: 50.0777,
        longitude: 19.7848,
        type: 'destination',
      ),
    ],
    legs: const [
      LegModel(
        fromWaypointId: 'wp-1',
        toWaypointId: 'wp-2',
        distanceNm: 123.4,
        trueCourseDeg: 201.0,
      ),
    ],
    totalDistanceNm: 123.4,
    createdAtIso: '2026-03-20T10:00:00.000Z',
    updatedAtIso: updatedAtIso,
  );
}
