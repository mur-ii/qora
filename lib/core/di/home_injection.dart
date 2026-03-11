import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/usecases/get_home_data.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';

class HomeInjection {
  HomeInjection._();

  static HomeBloc createBloc() {
    final dataSource = HomeRemoteDataSourceImpl();
    final repository = HomeRepositoryImpl(dataSource);
    final useCase = GetHomeData(repository);
    return HomeBloc(getHomeData: useCase);
  }
}
