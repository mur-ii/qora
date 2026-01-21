import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/guest_form_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl(this.remoteDataSource);

  @override
  Future<BookingEntity> getBookingSummary({
    required String hotelId,
    required String roomId,
    required String checkIn,
    required String checkOut,
    required int guests,
    required int rooms,
  }) async {
    final model = await remoteDataSource.getBookingSummary(
      hotelId: hotelId,
      roomId: roomId,
      checkIn: checkIn,
      checkOut: checkOut,
      guests: guests,
      rooms: rooms,
    );
    return model.toEntity();
  }

  @override
  Future<BookingEntity> submitGuestInfo({
    required String bookingId,
    required GuestFormEntity guestInfo,
  }) async {
    final model = await remoteDataSource.submitGuestInfo(
      bookingId: bookingId,
      guestInfo: guestInfo,
    );
    return model.toEntity();
  }

  @override
  Future<BookingEntity> confirmBooking({
    required String bookingId,
    required String paymentMethod,
  }) async {
    final model = await remoteDataSource.confirmBooking(
      bookingId: bookingId,
      paymentMethod: paymentMethod,
    );
    return model.toEntity();
  }
}
