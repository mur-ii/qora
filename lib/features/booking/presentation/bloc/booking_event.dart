import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/guest_form_entity.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookingSummaryEvent extends BookingEvent {
  final String hotelId;
  final String roomId;
  final String checkIn;
  final String checkOut;
  final int guests;
  final int rooms;

  const LoadBookingSummaryEvent({
    required this.hotelId,
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.rooms,
  });

  @override
  List<Object?> get props => [
    hotelId,
    roomId,
    checkIn,
    checkOut,
    guests,
    rooms,
  ];
}

class UpdateBookingEvent extends BookingEvent {
  final BookingEntity booking;

  const UpdateBookingEvent(this.booking);

  @override
  List<Object?> get props => [booking];
}

class SubmitGuestInfoEvent extends BookingEvent {
  final GuestFormEntity guestInfo;

  const SubmitGuestInfoEvent(this.guestInfo);

  @override
  List<Object?> get props => [guestInfo];
}

class ConfirmBookingEvent extends BookingEvent {
  final String paymentMethod;

  const ConfirmBookingEvent(this.paymentMethod);

  @override
  List<Object?> get props => [paymentMethod];
}
