import 'package:hive/hive.dart';

import '../models/performance_summary.dart';

class PerformanceLocalDataSource {
  final Box<PerformanceSummary> box;

  PerformanceLocalDataSource({required this.box});

  Future<void> saveSession(PerformanceSummary session) async {
    await box.put(session.sessionId, session);
  }

  List<PerformanceSummary> getAllSessions() {
    return box.values.toList(growable: false);
  }

  Future<void> clearSessions() async {
    await box.clear();
  }
}
