import 'package:equatable/equatable.dart';

import 'hotel_list_state.dart';

abstract class HotelListEvent extends Equatable {
  const HotelListEvent();

  @override
  List<Object?> get props => [];
}

class LoadHotelListEvent extends HotelListEvent {
  final String? location;
  final String? initialSort;
  final HotelListFilters? initialFilters;

  const LoadHotelListEvent({
    this.location,
    this.initialSort,
    this.initialFilters,
  });

  @override
  List<Object?> get props => [location, initialSort, initialFilters];
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
