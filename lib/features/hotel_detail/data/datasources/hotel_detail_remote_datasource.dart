import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/hotel_detail_model.dart';

abstract class HotelDetailRemoteDataSource {
  Future<HotelDetailModel> getHotelDetail(String hotelId);
}

class HotelDetailRemoteDataSourceImpl implements HotelDetailRemoteDataSource {
  @override
  Future<HotelDetailModel> getHotelDetail(String hotelId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Load mock data from JSON file
    final String response = await rootBundle.loadString(
      'lib/features/hotel_detail/mock/hotel_detail_response.json',
    );
    final Map<String, dynamic> data = json.decode(response);

    // Get hotel data by ID from the hotels map
    final Map<String, dynamic> hotels = data['hotels'];

    if (!hotels.containsKey(hotelId)) {
      throw Exception(
        'Detail hotel belum tersedia untuk area ini. Silakan pilih hotel lain.',
      );
    }

    final hotelData = hotels[hotelId];
    return HotelDetailModel.fromJson(hotelData);
  }
}
