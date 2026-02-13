import 'package:equatable/equatable.dart';

import 'hotel_list_state.dart';

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

class ApplyHotelFiltersEvent extends HotelListEvent {
  final HotelListFilters filters;

  const ApplyHotelFiltersEvent(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ResetHotelFiltersEvent extends HotelListEvent {
  const ResetHotelFiltersEvent();
}
