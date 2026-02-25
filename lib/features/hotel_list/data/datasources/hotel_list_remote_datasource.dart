import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/services/alpha_test_logger.dart';
import '../models/hotel_model.dart';

abstract class HotelListRemoteDataSource {
  Future<List<HotelModel>> getHotels();
}

class HotelListRemoteDataSourceImpl implements HotelListRemoteDataSource {
  @override
  Future<List<HotelModel>> getHotels() async {
    final stopwatch = Stopwatch()..start();
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Load mock data from JSON file
    final String response = await rootBundle.loadString(
      'lib/features/hotel_list/data/mock/hotel_list_response.json',
    );
    final Map<String, dynamic> data = json.decode(response);

    final List<dynamic> hotelsJson = data['hotels'];
    final result = hotelsJson.map((json) => HotelModel.fromJson(json)).toList();
    stopwatch.stop();
    AlphaTestLogger.instance.logNetworkLatency(
      endpoint: 'hotel_list',
      durationMs: stopwatch.elapsedMilliseconds,
    );
    return result;
  }
}
