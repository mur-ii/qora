import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/search_hotels.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchHotels searchHotels;

  SearchBloc({required this.searchHotels}) : super(const SearchInitial()) {
    on<SearchHotelsEvent>(_onSearchHotels);
    on<ClearSearchEvent>(_onClearSearch);
  }

  Future<void> _onSearchHotels(
    SearchHotelsEvent event,
    Emitter<SearchState> emit,
  ) async {
    // Don't search if both query and location are empty
    if ((event.query == null || event.query!.isEmpty) &&
        (event.location == null || event.location!.isEmpty)) {
      return;
    }

    emit(const SearchLoading());

    try {
      final hotels = await searchHotels(
        query: event.query,
        location: event.location,
      );

      if (hotels.isEmpty) {
        emit(const SearchEmpty('No hotels found matching your search'));
      } else {
        emit(
          SearchLoaded(
            hotels: hotels,
            query: event.query,
            location: event.location,
          ),
        );
      }
    } catch (e) {
      emit(SearchError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onClearSearch(ClearSearchEvent event, Emitter<SearchState> emit) {
    emit(const SearchInitial());
  }
}
