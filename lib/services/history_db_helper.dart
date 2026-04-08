import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/activity_model.dart';

class HistoryDatabaseHelper {
  static final HistoryDatabaseHelper _instance =
      HistoryDatabaseHelper._internal();
  factory HistoryDatabaseHelper() => _instance;
  HistoryDatabaseHelper._internal();

  static const String _databaseName = 'history.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'history_activities';

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
CREATE TABLE $_tableName (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  source TEXT NOT NULL,
  dateTime TEXT NOT NULL,
  chickenAge INTEGER NOT NULL,
  lampActive INTEGER NOT NULL,
  fanActive INTEGER NOT NULL,
  iconType TEXT NOT NULL
)
''');
      },
    );
  }

  Future<void> insertActivity(ActivityModel activity) async {
    final db = await database;
    await db.insert(
      _tableName,
      _toMap(activity),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ActivityModel>> getActivities({int? limit}) async {
    final db = await database;

    final rows = await db.query(
      _tableName,
      orderBy: 'dateTime DESC',
      limit: limit,
    );

    return rows.map(_fromMap).toList();
  }

  Future<void> deleteActivity(String id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllActivities() async {
    final db = await database;
    await db.delete(_tableName);
  }

  Future<void> trimToLimit(int maxRows) async {
    final db = await database;

    await db.delete(
      _tableName,
      where: 'id NOT IN (SELECT id FROM $_tableName ORDER BY dateTime DESC LIMIT ?)',
      whereArgs: [maxRows],
    );
  }

  Map<String, Object?> _toMap(ActivityModel activity) {
    return {
      'id': activity.id,
      'type': activity.type,
      'title': activity.title,
      'description': activity.description,
      'source': activity.source,
      'dateTime': activity.dateTime.toIso8601String(),
      'chickenAge': activity.chickenAge,
      'lampActive': activity.lampActive ? 1 : 0,
      'fanActive': activity.fanActive ? 1 : 0,
      'iconType': activity.iconType,
    };
  }

  ActivityModel _fromMap(Map<String, Object?> map) {
    return ActivityModel(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      source: map['source'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      chickenAge: map['chickenAge'] as int,
      lampActive: (map['lampActive'] as int) == 1,
      fanActive: (map['fanActive'] as int) == 1,
      iconType: map['iconType'] as String,
    );
  }
}
