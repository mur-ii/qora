import 'package:hive/hive.dart';

import '../models/booking_record.dart';

class BookingLocalDataSource {
  final Box<BookingRecord> box;

  BookingLocalDataSource({required this.box});

  Future<void> saveBooking(BookingRecord record) async {
    await box.put(record.bookingId, record);
  }

  List<BookingRecord> getAllBookings() {
    return box.values.toList(growable: false);
  }
}
