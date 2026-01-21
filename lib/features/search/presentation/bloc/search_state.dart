import 'package:equatable/equatable.dart';

import '../../domain/entities/search_hotel_entity.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final List<SearchHotelEntity> hotels;
  final String? query;
  final String? location;

  const SearchLoaded({required this.hotels, this.query, this.location});

  @override
  List<Object?> get props => [hotels, query, location];
}

class SearchEmpty extends SearchState {
  final String message;

  const SearchEmpty(this.message);

  @override
  List<Object?> get props => [message];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
