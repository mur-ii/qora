import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/guest_form_entity.dart';
import '../models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<BookingModel> getBookingSummary({
    required String hotelId,
    required String roomId,
    required String checkIn,
    required String checkOut,
    required int guests,
    required int rooms,
  });

  Future<BookingModel> submitGuestInfo({
    required String bookingId,
    required GuestFormEntity guestInfo,
  });

  Future<BookingModel> confirmBooking({
    required String bookingId,
    required String paymentMethod,
  });
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  @override
  Future<BookingModel> getBookingSummary({
    required String hotelId,
    required String roomId,
    required String checkIn,
    required String checkOut,
    required int guests,
    required int rooms,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Load mock data from JSON file
    final jsonString = await rootBundle.loadString(
      'lib/features/booking/mock/booking_summary_response.json',
    );
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;

    // Return booking model from mock data
    return BookingModel.fromJson(jsonData['data'] as Map<String, dynamic>);
  }

  @override
  Future<BookingModel> submitGuestInfo({
    required String bookingId,
    required GuestFormEntity guestInfo,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Load mock data and update with guest info
    final jsonString = await rootBundle.loadString(
      'lib/features/booking/mock/booking_summary_response.json',
    );
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final data = jsonData['data'] as Map<String, dynamic>;

    // Update guest info in the mock data
    data['guestInfo'] = {
      'primaryGuest': {
        'title': guestInfo.title,
        'fullName': guestInfo.fullName,
        'email': guestInfo.email,
        'phone': guestInfo.phone,
      },
      'specialRequests': guestInfo.specialRequests,
    };

    return BookingModel.fromJson(data);
  }

  @override
  Future<BookingModel> confirmBooking({
    required String bookingId,
    required String paymentMethod,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 1200));

    // Load mock confirmation data
    final jsonString = await rootBundle.loadString(
      'lib/features/booking/mock/booking_confirmation_response.json',
    );
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;

    return BookingModel.fromJson(jsonData['data'] as Map<String, dynamic>);
  }
}
