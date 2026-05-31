import '../../features/hotel_detail/data/datasources/hotel_detail_remote_datasource.dart';
import '../../features/hotel_detail/data/repositories/hotel_detail_repository_impl.dart';
import '../../features/hotel_detail/domain/usecases/get_hotel_detail.dart';
import '../../features/hotel_detail/presentation/bloc/hotel_detail_bloc.dart';

class HotelDetailInjection {
  static HotelDetailBloc createBloc() {
    final dataSource = HotelDetailRemoteDataSourceImpl();
    final repository = HotelDetailRepositoryImpl(dataSource);
    final useCase = GetHotelDetail(repository);
    return HotelDetailBloc(getHotelDetail: useCase);
  }
}
