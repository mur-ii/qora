import '../../domain/entities/search_hotel_entity.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<SearchHotelEntity>> searchHotels({
    String? query,
    String? location,
  }) async {
    final hotels = await remoteDataSource.searchHotels(
      query: query,
      location: location,
    );
    return hotels;
  }
}
