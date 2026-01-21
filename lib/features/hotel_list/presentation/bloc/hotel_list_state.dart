import 'package:equatable/equatable.dart';

import '../../domain/entities/hotel_entity.dart';

abstract class HotelListState extends Equatable {
  const HotelListState();

  @override
  List<Object?> get props => [];
}

class HotelListInitial extends HotelListState {
  const HotelListInitial();
}

class HotelListLoading extends HotelListState {
  const HotelListLoading();
}

class HotelListLoaded extends HotelListState {
  final List<HotelEntity> hotels;
  final String? activeFilter;

  const HotelListLoaded(this.hotels, {this.activeFilter});

  @override
  List<Object?> get props => [hotels, activeFilter];
}

class HotelListEmpty extends HotelListState {
  const HotelListEmpty();
}

class HotelListError extends HotelListState {
  final String message;

  const HotelListError(this.message);

  @override
  List<Object?> get props => [message];
}
