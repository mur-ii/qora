import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/hotel_entity.dart';
import '../../domain/usecases/get_hotel_list.dart';
import 'hotel_list_event.dart';
import 'hotel_list_state.dart';

class HotelListBloc extends Bloc<HotelListEvent, HotelListState> {
  final GetHotelList getHotelList;
  List<HotelEntity> _allHotels = [];
  String? _activeSort;
  HotelListFilters _activeFilters = const HotelListFilters();

  HotelListBloc({required this.getHotelList})
    : super(const HotelListInitial()) {
    on<LoadHotelListEvent>(_onLoadHotelList);
    on<FilterHotelListEvent>(_onFilterHotelList);
    on<ApplyHotelFiltersEvent>(_onApplyHotelFilters);
    on<ResetHotelFiltersEvent>(_onResetHotelFilters);
  }

  Future<void> _onLoadHotelList(
    LoadHotelListEvent event,
    Emitter<HotelListState> emit,
  ) async {
    // Avoid loading if already loading
    if (state is HotelListLoading) return;

    emit(const HotelListLoading());

    _activeSort = event.initialSort;
    _activeFilters = event.initialFilters ?? const HotelListFilters();

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
        final filteredAndSorted = _applyFiltersAndSort(_allHotels);
        emit(
          HotelListLoaded(
            filteredAndSorted,
            activeFilter: _activeSort,
            activeFilters: _activeFilters,
          ),
        );
      }
    } catch (e) {
      emit(HotelListError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onFilterHotelList(
    FilterHotelListEvent event,
    Emitter<HotelListState> emit,
  ) {
    if (_allHotels.isEmpty) return;

    // Don't re-filter if same filter is already active
    if (_activeSort == event.filter) {
      return;
    }

    _activeSort = event.filter;
    final filteredAndSorted = _applyFiltersAndSort(_allHotels);

    emit(
      HotelListLoaded(
        filteredAndSorted,
        activeFilter: _activeSort,
        activeFilters: _activeFilters,
      ),
    );
  }

  void _onApplyHotelFilters(
    ApplyHotelFiltersEvent event,
    Emitter<HotelListState> emit,
  ) {
    if (_allHotels.isEmpty) return;

    _activeFilters = event.filters;
    final filteredAndSorted = _applyFiltersAndSort(_allHotels);

    if (filteredAndSorted.isEmpty) {
      emit(const HotelListEmpty());
    } else {
      emit(
        HotelListLoaded(
          filteredAndSorted,
          activeFilter: _activeSort,
          activeFilters: _activeFilters,
        ),
      );
    }
  }

  void _onResetHotelFilters(
    ResetHotelFiltersEvent event,
    Emitter<HotelListState> emit,
  ) {
    if (_allHotels.isEmpty) return;

    _activeSort = null;
    _activeFilters = const HotelListFilters();
    final filteredAndSorted = _applyFiltersAndSort(_allHotels);

    emit(
      HotelListLoaded(
        filteredAndSorted,
        activeFilter: _activeSort,
        activeFilters: _activeFilters,
      ),
    );
  }

  List<HotelEntity> _applyFiltersAndSort(List<HotelEntity> hotels) {
    List<HotelEntity> filteredHotels = List.from(hotels);

    if (_activeFilters.budgetKey != null) {
      final budgetRange = _budgetRanges[_activeFilters.budgetKey!];
      if (budgetRange != null) {
        filteredHotels = filteredHotels.where((hotel) {
          final price = hotel.pricePerNight;
          final min = budgetRange.min;
          final max = budgetRange.max;
          final aboveMin = min == null || price >= min;
          final belowMax = max == null || price <= max;
          return aboveMin && belowMax;
        }).toList();
      }
    }

    if (_activeFilters.types.isNotEmpty) {
      filteredHotels = filteredHotels.where((hotel) {
        return _activeFilters.types.any((type) => _matchesType(hotel, type));
      }).toList();
    }

    if (_activeFilters.amenities.isNotEmpty) {
      filteredHotels = filteredHotels.where((hotel) {
        final normalizedAmenities = hotel.amenities
            .map((amenity) => amenity.toLowerCase())
            .toSet();
        return _activeFilters.amenities.every(
          (amenity) => normalizedAmenities.any(
            (item) => item.contains(amenity.toLowerCase()),
          ),
        );
      }).toList();
    }

    switch (_activeSort) {
      case 'lowest_price':
        filteredHotels.sort(
          (a, b) => a.pricePerNight.compareTo(b.pricePerNight),
        );
        break;
      case 'highest_price':
        filteredHotels.sort(
          (a, b) => b.pricePerNight.compareTo(a.pricePerNight),
        );
        break;
      case 'highest_rating':
        filteredHotels.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'popular':
        filteredHotels.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }

    return filteredHotels;
  }

  bool _matchesType(HotelEntity hotel, String type) {
    final name = hotel.name.toLowerCase();
    switch (type) {
      case 'hotel':
        return name.contains('hotel');
      case 'apartemen':
        return name.contains('suite') || name.contains('residence');
      case 'guest_house':
        return name.contains('guest');
      case 'villa':
        return name.contains('villa');
      case 'resort':
        return name.contains('resort');
      default:
        return false;
    }
  }
}

class _BudgetRange {
  final double? min;
  final double? max;

  const _BudgetRange({this.min, this.max});
}

const Map<String, _BudgetRange> _budgetRanges = {
  'lt_200k': _BudgetRange(max: 200000),
  '200_500k': _BudgetRange(min: 200000, max: 500000),
  '500_1000k': _BudgetRange(min: 500000, max: 1000000),
  'gt_1000k': _BudgetRange(min: 1000000),
};
