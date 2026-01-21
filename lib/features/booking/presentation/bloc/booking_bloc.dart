import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/confirm_booking.dart';
import '../../domain/usecases/get_booking_summary.dart';
import '../../domain/usecases/submit_guest_info.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final GetBookingSummary getBookingSummary;
  final SubmitGuestInfo submitGuestInfo;
  final ConfirmBooking confirmBooking;

  String? _currentBookingId;

  BookingBloc({
    required this.getBookingSummary,
    required this.submitGuestInfo,
    required this.confirmBooking,
  }) : super(const BookingInitial()) {
    on<LoadBookingSummaryEvent>(_onLoadBookingSummary);
    on<UpdateBookingEvent>(_onUpdateBooking);
    on<SubmitGuestInfoEvent>(_onSubmitGuestInfo);
    on<ConfirmBookingEvent>(_onConfirmBooking);
  }

  Future<void> _onLoadBookingSummary(
    LoadBookingSummaryEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading());

    try {
      final booking = await getBookingSummary(
        hotelId: event.hotelId,
        roomId: event.roomId,
        checkIn: event.checkIn,
        checkOut: event.checkOut,
        guests: event.guests,
        rooms: event.rooms,
      );

      _currentBookingId = booking.bookingId;
      emit(BookingSummaryLoaded(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  void _onUpdateBooking(UpdateBookingEvent event, Emitter<BookingState> emit) {
    _currentBookingId = event.booking.bookingId;
    emit(BookingSummaryLoaded(event.booking));
  }

  Future<void> _onSubmitGuestInfo(
    SubmitGuestInfoEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (_currentBookingId == null) {
      emit(const BookingError('No active booking found'));
      return;
    }

    emit(const BookingLoading());

    try {
      final booking = await submitGuestInfo(
        bookingId: _currentBookingId!,
        guestInfo: event.guestInfo,
      );

      emit(GuestInfoSubmitted(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }

  Future<void> _onConfirmBooking(
    ConfirmBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    if (_currentBookingId == null) {
      emit(const BookingError('No active booking found'));
      return;
    }

    emit(const BookingLoading());

    try {
      final booking = await confirmBooking(
        bookingId: _currentBookingId!,
        paymentMethod: event.paymentMethod,
      );

      emit(BookingConfirmed(booking));
    } catch (e) {
      emit(BookingError(e.toString()));
    }
  }
}
