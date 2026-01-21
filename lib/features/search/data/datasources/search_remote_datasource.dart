import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/search_hotel_model.dart';

abstract class SearchRemoteDataSource {
  Future<List<SearchHotelModel>> searchHotels({
    String? query,
    String? location,
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  @override
  Future<List<SearchHotelModel>> searchHotels({
    String? query,
    String? location,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Load mock data from JSON file
    final String response = await rootBundle.loadString(
      'lib/features/search/mock/search_hotels_response.json',
    );
    final Map<String, dynamic> data = json.decode(response);

    final List<dynamic> hotelsJson = data['hotels'];
    List<SearchHotelModel> hotels = hotelsJson
        .map((json) => SearchHotelModel.fromJson(json))
        .toList();

    // Filter by location if provided
    if (location != null && location.isNotEmpty) {
      hotels = hotels.where((hotel) {
        return hotel.city.toLowerCase().contains(location.toLowerCase()) ||
            hotel.location.toLowerCase().contains(location.toLowerCase());
      }).toList();
    }

    // Filter by query (hotel name) if provided
    if (query != null && query.isNotEmpty) {
      hotels = hotels.where((hotel) {
        return hotel.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    return hotels;
  }
}
