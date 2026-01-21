import '../entities/search_hotel_entity.dart';
import '../repositories/search_repository.dart';

class SearchHotels {
  final SearchRepository repository;

  SearchHotels(this.repository);

  Future<List<SearchHotelEntity>> call({
    String? query,
    String? location,
  }) async {
    return await repository.searchHotels(query: query, location: location);
  }
}
