import 'package:equatable/equatable.dart';

import '../../domain/entities/hotel_detail_entity.dart';

abstract class HotelDetailState extends Equatable {
  const HotelDetailState();

  @override
  List<Object?> get props => [];
}

class HotelDetailInitial extends HotelDetailState {
  const HotelDetailInitial();
}

class HotelDetailLoading extends HotelDetailState {
  const HotelDetailLoading();
}

class HotelDetailLoaded extends HotelDetailState {
  final HotelDetailEntity hotel;

  const HotelDetailLoaded(this.hotel);

  @override
  List<Object?> get props => [hotel];
}

class HotelDetailError extends HotelDetailState {
  final String message;

  const HotelDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
