import '../entities/performance_scenario.dart';

abstract class PerformanceRepository {
  Future<void> upsertScenario(PerformanceScenario scenario);

  Future<List<PerformanceScenario>> getAllScenarios();

  Future<PerformanceScenario?> getScenarioById(String scenarioId);

  Future<void> deleteScenario(String scenarioId);
}
