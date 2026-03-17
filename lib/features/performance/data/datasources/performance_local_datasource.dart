import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/performance_scenario.dart';

class PerformanceLocalDataSource {
  PerformanceLocalDataSource();

  static const String _dbName = 'qora_performance.db';
  static const int _dbVersion = 1;
  static const String _tableName = 'performance_runs';

  Database? _database;

  Future<Database> _openDatabase() async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scenario_id TEXT NOT NULL UNIQUE,
            method TEXT NOT NULL,
            scenario_name TEXT NOT NULL,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            latency_ms INTEGER,
            avg_cpu_percent REAL,
            peak_memory_mb REAL,
            network_tx_kb REAL,
            network_rx_kb REAL,
            session_cost_usd REAL NOT NULL DEFAULT 0,
            total_tokens INTEGER NOT NULL DEFAULT 0,
            total_turns INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'running',
            details_json TEXT NOT NULL DEFAULT '{}'
          )
        ''');
      },
    );

    return _database!;
  }

  Future<void> upsertScenario(PerformanceScenario scenario) async {
    final db = await _openDatabase();
    await db.insert(
      _tableName,
      scenario.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PerformanceScenario>> getAllScenarios() async {
    final db = await _openDatabase();
    final maps = await db.query(_tableName, orderBy: 'started_at DESC');

    return maps
        .map((map) => PerformanceScenario.fromMap(map))
        .toList(growable: false);
  }

  Future<PerformanceScenario?> getScenarioById(String scenarioId) async {
    final db = await _openDatabase();
    final maps = await db.query(
      _tableName,
      where: 'scenario_id = ?',
      whereArgs: <Object>[scenarioId],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return PerformanceScenario.fromMap(maps.first);
  }

  Future<void> deleteScenario(String scenarioId) async {
    final db = await _openDatabase();
    await db.delete(
      _tableName,
      where: 'scenario_id = ?',
      whereArgs: <Object>[scenarioId],
    );
  }
}
