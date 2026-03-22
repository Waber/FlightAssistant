class LegsTable {
  static const String tableName = 'legs';
  static const String routeId = 'route_id';
  static const String sequence = 'sequence';
  static const String fromWaypointId = 'from_waypoint_id';
  static const String toWaypointId = 'to_waypoint_id';
  static const String distanceNm = 'distance_nm';
  static const String trueCourseDeg = 'true_course_deg';

  static const String createTableSql = '''
CREATE TABLE $tableName (
  $routeId TEXT NOT NULL,
  $sequence INTEGER NOT NULL,
  $fromWaypointId TEXT NOT NULL,
  $toWaypointId TEXT NOT NULL,
  $distanceNm REAL NOT NULL,
  $trueCourseDeg REAL NOT NULL,
  PRIMARY KEY ($routeId, $sequence),
  FOREIGN KEY ($routeId) REFERENCES routes(id) ON DELETE CASCADE
)
''';

  static const String createRouteIndexSql = '''
CREATE INDEX idx_legs_route_sequence
ON $tableName ($routeId, $sequence)
''';
}
