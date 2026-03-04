import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/booking_record.dart';
import '../../domain/repositories/booking_local_repository.dart';
import 'booking_history_event.dart';
import 'booking_history_state.dart';

class BookingHistoryBloc
    extends Bloc<BookingHistoryEvent, BookingHistoryState> {
  final BookingLocalRepository repository;

  BookingHistoryBloc({required this.repository})
    : super(const BookingHistoryInitial()) {
    on<LoadBookingHistory>(_onLoadBookingHistory);
  }

  Future<void> _onLoadBookingHistory(
    LoadBookingHistory event,
    Emitter<BookingHistoryState> emit,
  ) async {
    emit(const BookingHistoryLoading());

    try {
      final bookings = await repository.getAllBookings();
      final now = DateTime.now();
      final ongoing = <BookingRecord>[];
      final history = <BookingRecord>[];

      for (final booking in bookings) {
        final isHistory = booking.checkOut.isBefore(now);
        if (isHistory) {
          history.add(booking);
        } else {
          ongoing.add(booking);
        }
      }

      emit(BookingHistoryLoaded(ongoing: ongoing, history: history));
    } catch (e) {
      emit(BookingHistoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
