import 'package:flight_assistant/features/route_storage/data/database/tables/legs_table.dart';
import 'package:flight_assistant/features/route_storage/data/database/tables/routes_table.dart';
import 'package:flight_assistant/features/route_storage/data/database/tables/waypoints_table.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

typedef DatabasesPathProvider = Future<String> Function();

class AppDatabase {
  AppDatabase({
    DatabaseFactory? databaseFactory,
    DatabasesPathProvider? databasesPathProvider,
    String databaseName = _defaultDatabaseName,
  })  : _databaseFactory = databaseFactory,
        _databasesPathProvider = databasesPathProvider ?? getDatabasesPath,
        _databaseName = databaseName;

  static const String _defaultDatabaseName = 'flight_assistant.db';
  static const int _schemaVersion = 1;

  final DatabaseFactory? _databaseFactory;
  final DatabasesPathProvider _databasesPathProvider;
  final String _databaseName;

  Database? _database;
  Future<Database>? _openingDatabase;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }

    _openingDatabase ??= _openDatabase();
    _database = await _openingDatabase;
    _openingDatabase = null;
    return _database!;
  }

  Future<void> close() async {
    final db = _database;
    _database = null;
    _openingDatabase = null;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }

  Future<Database> _openDatabase() async {
    final databasesRootPath = await _databasesPathProvider();
    final databasePath = path.join(databasesRootPath, _databaseName);
    final options = OpenDatabaseOptions(
      version: _schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) async {
        await db.execute(RoutesTable.createTableSql);
        await db.execute(WaypointsTable.createTableSql);
        await db.execute(LegsTable.createTableSql);
        await db.execute(WaypointsTable.createRouteIndexSql);
        await db.execute(LegsTable.createRouteIndexSql);
      },
    );

    final factory = _databaseFactory;
    if (factory != null) {
      return factory.openDatabase(databasePath, options: options);
    }

    return openDatabase(
      databasePath,
      version: _schemaVersion,
      onConfigure: options.onConfigure,
      onCreate: options.onCreate,
    );
  }
}
