import 'package:equatable/equatable.dart';

import '../../domain/entities/hotel_entity.dart';

abstract class HotelListState extends Equatable {
  const HotelListState();

  @override
  List<Object?> get props => [];
}

class HotelListFilters extends Equatable {
  final String? budgetKey;
  final Set<String> types;
  final Set<String> amenities;

  const HotelListFilters({
    this.budgetKey,
    Set<String>? types,
    Set<String>? amenities,
  }) : types = types ?? const {},
       amenities = amenities ?? const {};

  bool get isEmpty => budgetKey == null && types.isEmpty && amenities.isEmpty;

  HotelListFilters copyWith({
    String? budgetKey,
    Set<String>? types,
    Set<String>? amenities,
  }) {
    return HotelListFilters(
      budgetKey: budgetKey ?? this.budgetKey,
      types: types ?? this.types,
      amenities: amenities ?? this.amenities,
    );
  }

  @override
  List<Object?> get props => [
    budgetKey,
    types.toList()..sort(),
    amenities.toList()..sort(),
  ];
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
  final HotelListFilters activeFilters;

  const HotelListLoaded(
    this.hotels, {
    this.activeFilter,
    this.activeFilters = const HotelListFilters(),
  });

  @override
  List<Object?> get props => [hotels, activeFilter, activeFilters];
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
