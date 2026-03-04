import '../../features/search/data/datasources/search_remote_datasource.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/usecases/search_hotels.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';

class SearchInjection {
  static SearchBloc createBloc() {
    final dataSource = SearchRemoteDataSourceImpl();
    final repository = SearchRepositoryImpl(dataSource);
    final useCase = SearchHotels(repository);
    return SearchBloc(searchHotels: useCase);
  }
}
