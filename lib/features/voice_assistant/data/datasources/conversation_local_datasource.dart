import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/conversation_log_model.dart';

class ConversationLocalDataSource {
  static const String _dbName = 'voice_assistant_logs.db';
  static const int _dbVersion = 1;
  static const String tableName = 'conversation_logs';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(appDocDir.path, _dbName);

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            user_message TEXT NOT NULL,
            assistant_message TEXT NOT NULL,
            input_tokens INTEGER NOT NULL,
            output_tokens INTEGER NOT NULL,
            cached_tokens INTEGER NOT NULL,
            total_tokens INTEGER NOT NULL,
            estimated_cost_usd REAL NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertConversationLog(ConversationLogModel log) async {
    final db = await database;
    final map = log.toMap()..remove('id');
    return db.insert(tableName, map);
  }

  Future<List<ConversationLogModel>> getLogsBySessionId(
    String sessionId,
  ) async {
    final db = await database;
    final rows = await db.query(
      tableName,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return rows.map(ConversationLogModel.fromMap).toList();
  }

  Future<double> getSessionCost(String sessionId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(estimated_cost_usd), 0) AS total_cost
      FROM $tableName
      WHERE session_id = ?
      ''',
      [sessionId],
    );

    if (result.isEmpty) return 0;
    return (result.first['total_cost'] as num?)?.toDouble() ?? 0;
  }

  Future<void> clearSessionLogs(String sessionId) async {
    final db = await database;
    await db.delete(tableName, where: 'session_id = ?', whereArgs: [sessionId]);
  }

  Future<void> close() async {
    if (_database == null) return;
    await _database!.close();
    _database = null;
  }
}
