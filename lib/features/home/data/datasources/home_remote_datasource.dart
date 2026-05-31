import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/home_model.dart';

abstract class HomeRemoteDataSource {
  Future<HomeModel> getHomeData();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  @override
  Future<HomeModel> getHomeData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final jsonString = await rootBundle.loadString(
      'lib/features/home/data/mock/home_response.json',
    );
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return HomeModel.fromJson(json);
  }
}
