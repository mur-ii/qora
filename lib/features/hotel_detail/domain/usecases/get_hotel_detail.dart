import '../entities/hotel_detail_entity.dart';
import '../repositories/hotel_detail_repository.dart';

class GetHotelDetail {
  final HotelDetailRepository repository;

  GetHotelDetail(this.repository);

  Future<HotelDetailEntity> call(String hotelId) async {
    return await repository.getHotelDetail(hotelId);
  }
}
