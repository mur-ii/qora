import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/hotel_entity.dart';
import '../../domain/usecases/get_hotel_list.dart';
import 'hotel_list_event.dart';
import 'hotel_list_state.dart';

class HotelListBloc extends Bloc<HotelListEvent, HotelListState> {
  final GetHotelList getHotelList;
  List<HotelEntity> _allHotels = [];

  HotelListBloc({required this.getHotelList})
    : super(const HotelListInitial()) {
    on<LoadHotelListEvent>(_onLoadHotelList);
    on<FilterHotelListEvent>(_onFilterHotelList);
  }

  Future<void> _onLoadHotelList(
    LoadHotelListEvent event,
    Emitter<HotelListState> emit,
  ) async {
    // Avoid loading if already loading
    if (state is HotelListLoading) return;

    emit(const HotelListLoading());

    try {
      final hotels = await getHotelList();

      // Filter by location if provided
      List<HotelEntity> filteredHotels = hotels;
      if (event.location != null && event.location!.isNotEmpty) {
        final locationLower = event.location!.toLowerCase();
        filteredHotels = hotels.where((hotel) {
          final hotelLocationLower = hotel.location.toLowerCase();
          final hotelNameLower = hotel.name.toLowerCase();
          return hotelLocationLower.contains(locationLower) ||
              hotelNameLower.contains(locationLower);
        }).toList();
      }

      if (filteredHotels.isEmpty) {
        emit(const HotelListEmpty());
      } else {
        _allHotels = filteredHotels;
        emit(HotelListLoaded(filteredHotels));
      }
    } catch (e) {
      emit(HotelListError(e.toString()));
    }
  }

  void _onFilterHotelList(
    FilterHotelListEvent event,
    Emitter<HotelListState> emit,
  ) {
    if (_allHotels.isEmpty) return;

    // Don't re-filter if same filter is already active
    if (state is HotelListLoaded &&
        (state as HotelListLoaded).activeFilter == event.filter) {
      return;
    }

    List<HotelEntity> filteredHotels = List.from(_allHotels);

    switch (event.filter) {
      case 'lowest_price':
        filteredHotels.sort(
          (a, b) => a.pricePerNight.compareTo(b.pricePerNight),
        );
        break;
      case 'highest_rating':
        filteredHotels.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'popular':
        filteredHotels.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        filteredHotels = _allHotels;
    }

    emit(HotelListLoaded(filteredHotels, activeFilter: event.filter));
  }
}
