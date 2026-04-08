import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/notification_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const String _databaseName = 'notifications.db';
  static const int _databaseVersion = 1;
  static const String _tableName = 'notifications';

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
  dateTime TEXT NOT NULL,
  chickenAge INTEGER NOT NULL,
  isRead INTEGER NOT NULL,
  severity TEXT NOT NULL
)
''');
      },
    );
  }

  Future<void> insertNotification(NotificationModel notification) async {
    final db = await database;
    await db.insert(
      _tableName,
      _toMap(notification),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<NotificationModel>> getNotifications() async {
    final db = await database;
    final rows = await db.query(_tableName, orderBy: 'dateTime DESC');
    return rows.map(_fromMap).toList();
  }

  Future<void> markAsRead(String id) async {
    final db = await database;
    await db.update(
      _tableName,
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }

  Map<String, Object?> _toMap(NotificationModel notification) {
    return {
      'id': notification.id,
      'type': notification.type,
      'title': notification.title,
      'description': notification.description,
      'dateTime': notification.dateTime.toIso8601String(),
      'chickenAge': notification.chickenAge,
      'isRead': notification.isRead ? 1 : 0,
      'severity': notification.severity,
    };
  }

  NotificationModel _fromMap(Map<String, Object?> map) {
    return NotificationModel(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      chickenAge: map['chickenAge'] as int,
      isRead: (map['isRead'] as int) == 1,
      severity: map['severity'] as String,
    );
  }
}
