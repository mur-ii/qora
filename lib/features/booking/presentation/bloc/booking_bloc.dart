import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_entity.dart';
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
      emit(BookingSummaryLoaded(_applyBookingOverrides(booking, event)));
    } catch (e) {
      emit(BookingError(e.toString().replaceAll('Exception: ', '')));
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
      emit(BookingError(e.toString().replaceAll('Exception: ', '')));
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
      emit(BookingError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  BookingEntity _applyBookingOverrides(
    BookingEntity booking,
    LoadBookingSummaryEvent event,
  ) {
    final parsedCheckIn = DateTime.tryParse(event.checkIn);
    final parsedCheckOut = DateTime.tryParse(event.checkOut);
    var nights = booking.bookingDetails.nights;

    if (parsedCheckIn != null && parsedCheckOut != null) {
      final diff = parsedCheckOut.difference(parsedCheckIn).inDays;
      if (diff > 0) {
        nights = diff;
      }
    }

    final updatedDetails = BookingDetailsEntity(
      checkIn: event.checkIn,
      checkOut: event.checkOut,
      checkInTime: booking.bookingDetails.checkInTime,
      checkOutTime: booking.bookingDetails.checkOutTime,
      nights: nights,
      guests: event.guests,
      rooms: event.rooms,
    );

    return BookingEntity(
      bookingId: booking.bookingId,
      confirmationNumber: booking.confirmationNumber,
      bookingStatus: booking.bookingStatus,
      bookingDate: booking.bookingDate,
      hotel: booking.hotel,
      room: booking.room,
      bookingDetails: updatedDetails,
      guestInfo: booking.guestInfo,
      pricing: booking.pricing,
      payment: booking.payment,
      cancellationPolicy: booking.cancellationPolicy,
    );
  }
}
