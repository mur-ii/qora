import '../../domain/entities/hotel_entity.dart';
import '../../domain/repositories/hotel_list_repository.dart';
import '../datasources/hotel_list_remote_datasource.dart';

class HotelListRepositoryImpl implements HotelListRepository {
  final HotelListRemoteDataSource remoteDataSource;

  HotelListRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<HotelEntity>> getHotels() async {
    final hotels = await remoteDataSource.getHotels();
    return hotels;
  }
}
