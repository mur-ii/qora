import 'package:equatable/equatable.dart';

abstract class HotelDetailEvent extends Equatable {
  const HotelDetailEvent();

  @override
  List<Object?> get props => [];
}

class LoadHotelDetailEvent extends HotelDetailEvent {
  final String hotelId;

  const LoadHotelDetailEvent(this.hotelId);

  @override
  List<Object?> get props => [hotelId];
}
