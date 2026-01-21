import '../entities/hotel_detail_entity.dart';

abstract class HotelDetailRepository {
  Future<HotelDetailEntity> getHotelDetail(String hotelId);
}
