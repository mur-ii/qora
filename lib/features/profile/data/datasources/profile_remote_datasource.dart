import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();
  Future<Map<String, dynamic>> getPaymentMethods();
  Future<Map<String, dynamic>> getTransactions();
  Future<Map<String, dynamic>> getPreferences();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  @override
  Future<ProfileModel> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final jsonString = await rootBundle.loadString(
      'lib/features/profile/mock/profile_response.json',
    );
    final jsonData = json.decode(jsonString);
    
    return ProfileModel.fromJson(jsonData['data'] as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> getPaymentMethods() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final jsonString = await rootBundle.loadString(
      'lib/features/profile/mock/payment_methods_response.json',
    );
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getTransactions() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final jsonString = await rootBundle.loadString(
      'lib/features/profile/mock/transactions_response.json',
    );
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getPreferences() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final jsonString = await rootBundle.loadString(
      'lib/features/profile/mock/preferences_response.json',
    );
    return json.decode(jsonString) as Map<String, dynamic>;
  }
}
