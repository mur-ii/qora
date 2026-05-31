import '../models/booking_record.dart';

class BookingLocalDataSource {
  static final Map<String, BookingRecord> _records = <String, BookingRecord>{};

  BookingLocalDataSource();

  Future<void> saveBooking(BookingRecord record) async {
    _records[record.bookingId] = record;
  }

  List<BookingRecord> getAllBookings() {
    return _records.values.toList(growable: false);
  }
}
