import '../../domain/entities/hotel_detail_entity.dart';
import '../../domain/repositories/hotel_detail_repository.dart';
import '../datasources/hotel_detail_remote_datasource.dart';

class HotelDetailRepositoryImpl implements HotelDetailRepository {
  final HotelDetailRemoteDataSource remoteDataSource;

  HotelDetailRepositoryImpl(this.remoteDataSource);

  @override
  Future<HotelDetailEntity> getHotelDetail(String hotelId) async {
    final hotel = await remoteDataSource.getHotelDetail(hotelId);
    return hotel;
  }
}
