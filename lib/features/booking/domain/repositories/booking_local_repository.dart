import '../../data/models/booking_record.dart';

abstract class BookingLocalRepository {
  Future<void> saveBooking(BookingRecord record);
  Future<List<BookingRecord>> getAllBookings();
}
