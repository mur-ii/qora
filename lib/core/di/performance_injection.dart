import 'package:hive/hive.dart';

import '../../features/performance/data/datasources/performance_local_datasource.dart';
import '../../features/performance/data/models/performance_summary.dart';
import '../../features/performance/data/repositories/performance_repository_impl.dart';
import '../../features/performance/presentation/bloc/performance_bloc.dart';

class PerformanceInjection {
  static PerformanceBloc? _performanceBloc;

  static PerformanceBloc getPerformanceBloc() {
    if (_performanceBloc != null) return _performanceBloc!;

    final box = Hive.box<PerformanceSummary>('performance_box');
    final localDataSource = PerformanceLocalDataSource(box: box);
    final repository = PerformanceRepositoryImpl(
      localDataSource: localDataSource,
    );

    _performanceBloc = PerformanceBloc(repository: repository);

    return _performanceBloc!;
  }

  static void dispose() {
    _performanceBloc?.close();
    _performanceBloc = null;
  }
}
