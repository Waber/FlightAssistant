import 'package:flight_assistant/features/flight_planning/data/models/route_plan_model.dart';
import 'package:flight_assistant/features/route_storage/data/database/app_database.dart';
import 'package:flight_assistant/features/route_storage/data/database/tables/legs_table.dart';
import 'package:flight_assistant/features/route_storage/data/database/tables/routes_table.dart';
import 'package:flight_assistant/features/route_storage/data/database/tables/waypoints_table.dart';
import 'package:sqflite/sqflite.dart';

class LocalRouteDataSource {
  LocalRouteDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<void> saveRoute(RoutePlanModel routePlanModel) async {
    final database = await _appDatabase.database;
    await database.transaction((txn) async {
      await txn.insert(
        RoutesTable.tableName,
        <String, Object?>{
          RoutesTable.id: routePlanModel.id,
          RoutesTable.name: routePlanModel.name,
          RoutesTable.totalDistanceNm: routePlanModel.totalDistanceNm,
          RoutesTable.createdAt: routePlanModel.createdAtIso,
          RoutesTable.updatedAt: routePlanModel.updatedAtIso,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        WaypointsTable.tableName,
        where: '${WaypointsTable.routeId} = ?',
        whereArgs: <Object?>[routePlanModel.id],
      );
      await txn.delete(
        LegsTable.tableName,
        where: '${LegsTable.routeId} = ?',
        whereArgs: <Object?>[routePlanModel.id],
      );

      for (var index = 0; index < routePlanModel.waypoints.length; index++) {
        final waypoint = routePlanModel.waypoints[index];
        await txn.insert(
          WaypointsTable.tableName,
          <String, Object?>{
            WaypointsTable.id: waypoint.id,
            WaypointsTable.routeId: routePlanModel.id,
            WaypointsTable.sequence: index,
            WaypointsTable.name: waypoint.name,
            WaypointsTable.latitude: waypoint.latitude,
            WaypointsTable.longitude: waypoint.longitude,
            WaypointsTable.type: waypoint.type,
          },
        );
      }

      for (var index = 0; index < routePlanModel.legs.length; index++) {
        final leg = routePlanModel.legs[index];
        await txn.insert(
          LegsTable.tableName,
          <String, Object?>{
            LegsTable.routeId: routePlanModel.id,
            LegsTable.sequence: index,
            LegsTable.fromWaypointId: leg.fromWaypointId,
            LegsTable.toWaypointId: leg.toWaypointId,
            LegsTable.distanceNm: leg.distanceNm,
            LegsTable.trueCourseDeg: leg.trueCourseDeg,
          },
        );
      }
    });
  }

  Future<List<RoutePlanModel>> getRoutes() async {
    final database = await _appDatabase.database;
    final routeRows = await database.query(
      RoutesTable.tableName,
      orderBy: '${RoutesTable.updatedAt} DESC',
    );

    final routes = <RoutePlanModel>[];
    for (final routeRow in routeRows) {
      final routeId = routeRow[RoutesTable.id] as String;

      final waypointRows = await database.query(
        WaypointsTable.tableName,
        where: '${WaypointsTable.routeId} = ?',
        whereArgs: <Object?>[routeId],
        orderBy: '${WaypointsTable.sequence} ASC',
      );
      final legRows = await database.query(
        LegsTable.tableName,
        where: '${LegsTable.routeId} = ?',
        whereArgs: <Object?>[routeId],
        orderBy: '${LegsTable.sequence} ASC',
      );

      routes.add(
        RoutePlanModel.fromMap(<String, dynamic>{
          'id': routeId,
          'name': routeRow[RoutesTable.name] as String,
          'waypoints': waypointRows.map(_waypointRowToMap).toList(),
          'legs': legRows.map(_legRowToMap).toList(),
          'totalDistanceNm':
              (routeRow[RoutesTable.totalDistanceNm] as num).toDouble(),
          'createdAtIso': routeRow[RoutesTable.createdAt] as String,
          'updatedAtIso': routeRow[RoutesTable.updatedAt] as String,
        }),
      );
    }

    return routes;
  }

  Future<void> deleteRoute(String routeId) async {
    final database = await _appDatabase.database;
    await database.delete(
      RoutesTable.tableName,
      where: '${RoutesTable.id} = ?',
      whereArgs: <Object?>[routeId],
    );
  }

  Map<String, dynamic> _waypointRowToMap(Map<String, Object?> row) {
    return <String, dynamic>{
      'id': row[WaypointsTable.id] as String,
      'name': row[WaypointsTable.name] as String,
      'latitude': (row[WaypointsTable.latitude] as num).toDouble(),
      'longitude': (row[WaypointsTable.longitude] as num).toDouble(),
      'type': row[WaypointsTable.type] as String,
    };
  }

  Map<String, dynamic> _legRowToMap(Map<String, Object?> row) {
    return <String, dynamic>{
      'fromWaypointId': row[LegsTable.fromWaypointId] as String,
      'toWaypointId': row[LegsTable.toWaypointId] as String,
      'distanceNm': (row[LegsTable.distanceNm] as num).toDouble(),
      'trueCourseDeg': (row[LegsTable.trueCourseDeg] as num).toDouble(),
    };
  }
}
