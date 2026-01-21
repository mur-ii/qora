import '../entities/booking_entity.dart';
import '../entities/guest_form_entity.dart';
import '../repositories/booking_repository.dart';

class SubmitGuestInfo {
  final BookingRepository repository;

  SubmitGuestInfo(this.repository);

  Future<BookingEntity> call({
    required String bookingId,
    required GuestFormEntity guestInfo,
  }) {
    return repository.submitGuestInfo(
      bookingId: bookingId,
      guestInfo: guestInfo,
    );
  }
}
