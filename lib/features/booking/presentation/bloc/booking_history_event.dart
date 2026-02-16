import 'package:equatable/equatable.dart';

abstract class BookingHistoryEvent extends Equatable {
  const BookingHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookingHistory extends BookingHistoryEvent {
  const LoadBookingHistory();
}
