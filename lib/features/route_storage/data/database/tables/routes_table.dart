class RoutesTable {
  static const String tableName = 'routes';
  static const String id = 'id';
  static const String name = 'name';
  static const String totalDistanceNm = 'total_distance_nm';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static const String createTableSql = '''
CREATE TABLE $tableName (
  $id TEXT PRIMARY KEY,
  $name TEXT NOT NULL,
  $totalDistanceNm REAL NOT NULL,
  $createdAt TEXT NOT NULL,
  $updatedAt TEXT NOT NULL
)
''';
}
