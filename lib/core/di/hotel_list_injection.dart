import '../../features/hotel_list/data/datasources/hotel_list_remote_datasource.dart';
import '../../features/hotel_list/data/repositories/hotel_list_repository_impl.dart';
import '../../features/hotel_list/domain/usecases/get_hotel_list.dart';
import '../../features/hotel_list/presentation/bloc/hotel_list_bloc.dart';

class HotelListInjection {
  static HotelListBloc createBloc() {
    final dataSource = HotelListRemoteDataSourceImpl();
    final repository = HotelListRepositoryImpl(dataSource);
    final useCase = GetHotelList(repository);
    return HotelListBloc(getHotelList: useCase);
  }
}
