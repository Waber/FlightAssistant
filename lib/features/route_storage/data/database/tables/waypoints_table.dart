class WaypointsTable {
  static const String tableName = 'waypoints';
  static const String id = 'id';
  static const String routeId = 'route_id';
  static const String sequence = 'sequence';
  static const String name = 'name';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String type = 'type';

  static const String createTableSql = '''
CREATE TABLE $tableName (
  $id TEXT NOT NULL,
  $routeId TEXT NOT NULL,
  $sequence INTEGER NOT NULL,
  $name TEXT NOT NULL,
  $latitude REAL NOT NULL,
  $longitude REAL NOT NULL,
  $type TEXT NOT NULL,
  PRIMARY KEY ($routeId, $sequence),
  FOREIGN KEY ($routeId) REFERENCES routes(id) ON DELETE CASCADE
)
''';

  static const String createRouteIndexSql = '''
CREATE INDEX idx_waypoints_route_sequence
ON $tableName ($routeId, $sequence)
''';
}
