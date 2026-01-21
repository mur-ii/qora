import '../entities/booking_entity.dart';
import '../entities/guest_form_entity.dart';

abstract class BookingRepository {
  Future<BookingEntity> getBookingSummary({
    required String hotelId,
    required String roomId,
    required String checkIn,
    required String checkOut,
    required int guests,
    required int rooms,
  });

  Future<BookingEntity> submitGuestInfo({
    required String bookingId,
    required GuestFormEntity guestInfo,
  });

  Future<BookingEntity> confirmBooking({
    required String bookingId,
    required String paymentMethod,
  });
}
