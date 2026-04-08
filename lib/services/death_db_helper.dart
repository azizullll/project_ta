import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/death_model.dart';

class DeathDatabaseHelper {
  static final DeathDatabaseHelper _instance = DeathDatabaseHelper._internal();
  factory DeathDatabaseHelper() => _instance;
  DeathDatabaseHelper._internal();

  static const String _databaseName = 'death_records.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'death_records';

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
  dateTime TEXT NOT NULL,
  count INTEGER NOT NULL,
  cause TEXT NOT NULL,
  chickenAge INTEGER NOT NULL,
  notes TEXT
)
''');
      },
    );
  }

  Future<List<DeathModel>> getRecords() async {
    final db = await database;
    final rows = await db.query(_tableName, orderBy: 'dateTime DESC');
    return rows.map(DeathModel.fromMap).toList();
  }

  Future<void> insertRecord(DeathModel record) async {
    final db = await database;
    await db.insert(
      _tableName,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteRecord(String id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllRecords() async {
    final db = await database;
    await db.delete(_tableName);
  }
}
