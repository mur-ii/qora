import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchHotelsEvent extends SearchEvent {
  final String? query;
  final String? location;

  const SearchHotelsEvent({
    this.query,
    this.location,
  });

  @override
  List<Object?> get props => [query, location];
}

class ClearSearchEvent extends SearchEvent {
  const ClearSearchEvent();
}
