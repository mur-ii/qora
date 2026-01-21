import '../entities/search_hotel_entity.dart';

abstract class SearchRepository {
  Future<List<SearchHotelEntity>> searchHotels({
    String? query,
    String? location,
  });
}
