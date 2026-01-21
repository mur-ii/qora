import 'package:equatable/equatable.dart';

abstract class HotelListEvent extends Equatable {
  const HotelListEvent();

  @override
  List<Object?> get props => [];
}

class LoadHotelListEvent extends HotelListEvent {
  final String? location;

  const LoadHotelListEvent({this.location});

  @override
  List<Object?> get props => [location];
}

class FilterHotelListEvent extends HotelListEvent {
  final String filter; // 'lowest_price', 'highest_rating', 'popular'

  const FilterHotelListEvent(this.filter);

  @override
  List<Object?> get props => [filter];
}
