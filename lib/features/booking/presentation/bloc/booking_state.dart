import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_entity.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class BookingSummaryLoaded extends BookingState {
  final BookingEntity booking;

  const BookingSummaryLoaded(this.booking);

  @override
  List<Object?> get props => [booking];
}

class GuestInfoSubmitted extends BookingState {
  final BookingEntity booking;

  const GuestInfoSubmitted(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingConfirmed extends BookingState {
  final BookingEntity booking;

  const BookingConfirmed(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object?> get props => [message];
}
