import '../entities/hotel_entity.dart';

abstract class HotelListRepository {
  Future<List<HotelEntity>> getHotels();
}
