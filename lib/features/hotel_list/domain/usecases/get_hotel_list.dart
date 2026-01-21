import '../entities/hotel_entity.dart';
import '../repositories/hotel_list_repository.dart';

class GetHotelList {
  final HotelListRepository repository;

  GetHotelList(this.repository);

  Future<List<HotelEntity>> call() async {
    return await repository.getHotels();
  }
}
