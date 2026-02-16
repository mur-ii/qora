import '../../domain/repositories/booking_local_repository.dart';
import '../datasources/booking_local_datasource.dart';
import '../models/booking_record.dart';

class BookingLocalRepositoryImpl implements BookingLocalRepository {
  final BookingLocalDataSource localDataSource;

  BookingLocalRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveBooking(BookingRecord record) async {
    await localDataSource.saveBooking(record);
  }

  @override
  Future<List<BookingRecord>> getAllBookings() async {
    final bookings = localDataSource.getAllBookings();
    bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return bookings;
  }
}
