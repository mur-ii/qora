import '../../data/models/performance_summary.dart';

abstract class PerformanceRepository {
  Future<void> saveSession(PerformanceSummary session);
  Future<List<PerformanceSummary>> getAllSessions();
  Future<String> exportSessionsToCsv();
}
