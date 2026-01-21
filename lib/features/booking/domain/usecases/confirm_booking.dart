import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class ConfirmBooking {
  final BookingRepository repository;

  ConfirmBooking(this.repository);

  Future<BookingEntity> call({
    required String bookingId,
    required String paymentMethod,
  }) {
    return repository.confirmBooking(
      bookingId: bookingId,
      paymentMethod: paymentMethod,
    );
  }
}
