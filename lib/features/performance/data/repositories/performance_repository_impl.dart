import '../../domain/entities/performance_scenario.dart';
import '../../domain/repositories/performance_repository.dart';
import '../datasources/performance_local_datasource.dart';

class PerformanceRepositoryImpl implements PerformanceRepository {
  PerformanceRepositoryImpl({required this.localDataSource});

  final PerformanceLocalDataSource localDataSource;

  @override
  Future<void> upsertScenario(PerformanceScenario scenario) {
    return localDataSource.upsertScenario(scenario);
  }

  @override
  Future<List<PerformanceScenario>> getAllScenarios() {
    return localDataSource.getAllScenarios();
  }

  @override
  Future<PerformanceScenario?> getScenarioById(String scenarioId) {
    return localDataSource.getScenarioById(scenarioId);
  }

  @override
  Future<void> deleteScenario(String scenarioId) {
    return localDataSource.deleteScenario(scenarioId);
  }
}
