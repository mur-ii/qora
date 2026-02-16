import 'package:equatable/equatable.dart';

import '../../data/models/booking_record.dart';

abstract class BookingHistoryState extends Equatable {
  const BookingHistoryState();

  @override
  List<Object?> get props => [];
}

class BookingHistoryInitial extends BookingHistoryState {
  const BookingHistoryInitial();
}

class BookingHistoryLoading extends BookingHistoryState {
  const BookingHistoryLoading();
}

class BookingHistoryLoaded extends BookingHistoryState {
  final List<BookingRecord> ongoing;
  final List<BookingRecord> history;

  const BookingHistoryLoaded({required this.ongoing, required this.history});

  @override
  List<Object?> get props => [ongoing, history];
}

class BookingHistoryError extends BookingHistoryState {
  final String message;

  const BookingHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
