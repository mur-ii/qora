import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class GetBookingSummary {
  final BookingRepository repository;

  GetBookingSummary(this.repository);

  Future<BookingEntity> call({
    required String hotelId,
    required String roomId,
    required String checkIn,
    required String checkOut,
    required int guests,
    required int rooms,
  }) {
    return repository.getBookingSummary(
      hotelId: hotelId,
      roomId: roomId,
      checkIn: checkIn,
      checkOut: checkOut,
      guests: guests,
      rooms: rooms,
    );
  }
}
