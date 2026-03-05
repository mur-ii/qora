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
    final data = Map<String, dynamic>.from(
      jsonData['data'] as Map<String, dynamic>,
    );

    // Load hotel detail data to align with selected hotel/room
    final hotelDetailString = await rootBundle.loadString(
      'lib/features/hotel_detail/mock/hotel_detail_response.json',
    );
    final hotelDetailData =
        json.decode(hotelDetailString) as Map<String, dynamic>;
    final hotels = hotelDetailData['hotels'] as Map<String, dynamic>?;
    final selectedHotel = hotels?[hotelId] as Map<String, dynamic>?;

    Map<String, dynamic>? selectedRoom;
    if (selectedHotel != null) {
      final roomTypes = selectedHotel['roomTypes'] as List<dynamic>? ?? [];
      for (final room in roomTypes) {
        final roomMap = room as Map<String, dynamic>;
        if (roomMap['id']?.toString() == roomId) {
          selectedRoom = roomMap;
          break;
        }
      }
    }

    if (selectedHotel != null) {
      final existingHotel = Map<String, dynamic>.from(
        data['hotel'] as Map<String, dynamic>,
      );
      data['hotel'] = {
        ...existingHotel,
        'id': selectedHotel['id']?.toString() ?? existingHotel['id'],
        'name': selectedHotel['name'] ?? existingHotel['name'],
        'address': selectedHotel['address'] ?? existingHotel['address'],
        'rating': selectedHotel['rating'] ?? existingHotel['rating'],
      };
    }

    if (selectedRoom != null) {
      data['room'] = {
        'id': selectedRoom['id']?.toString(),
        'name': selectedRoom['name'],
        'bedType': selectedRoom['bedType'],
        'maxGuests': selectedRoom['maxGuests'],
      };
    }

    final parsedCheckIn = DateTime.tryParse(checkIn);
    final parsedCheckOut = DateTime.tryParse(checkOut);
    var nights =
        (data['bookingDetails'] as Map<String, dynamic>)['nights'] as int? ?? 1;
    if (parsedCheckIn != null && parsedCheckOut != null) {
      final diff = parsedCheckOut.difference(parsedCheckIn).inDays;
      if (diff > 0) {
        nights = diff;
      }
    }

    final hotelPolicies = selectedHotel?['policies'] as Map<String, dynamic>?;
    data['bookingDetails'] = {
      'checkIn': checkIn,
      'checkOut': checkOut,
      'checkInTime':
          hotelPolicies?['checkIn'] ??
          (data['bookingDetails'] as Map<String, dynamic>)['checkInTime'],
      'checkOutTime':
          hotelPolicies?['checkOut'] ??
          (data['bookingDetails'] as Map<String, dynamic>)['checkOutTime'],
      'nights': nights,
      'guests': guests,
      'rooms': rooms,
    };

    final pricing = Map<String, dynamic>.from(
      data['pricing'] as Map<String, dynamic>,
    );
    final basePrice =
        (selectedRoom?['pricePerNight'] as num?)?.toDouble() ??
        (pricing['subtotal'] as num).toDouble();
    final subtotal = basePrice * nights * rooms;
    final taxes = subtotal * 0.1;
    final fees = (pricing['fees'] as num?)?.toDouble() ?? 0.0;
    final discount = (pricing['discount'] as num?)?.toDouble() ?? 0.0;
    final grandTotal = subtotal + taxes + fees - discount;
    final previousGrandTotal =
        (pricing['grandTotal'] as num?)?.toDouble() ?? grandTotal;
    final previousDueNow = (pricing['dueNow'] as num?)?.toDouble();
    final dueNowRatio = (previousDueNow != null && previousGrandTotal > 0)
        ? (previousDueNow / previousGrandTotal)
        : 0.3;
    final dueNow = grandTotal * dueNowRatio;

    data['pricing'] = {
      'subtotal': subtotal,
      'taxes': taxes,
      'fees': fees,
      'discount': discount,
      'grandTotal': grandTotal,
      'currency': pricing['currency'] ?? 'IDR',
      'dueNow': dueNow,
      'dueAtProperty': grandTotal - dueNow,
    };

    final result = BookingModel.fromJson(data);
    return result;
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

    final result = BookingModel.fromJson(data);
    return result;
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

    final result = BookingModel.fromJson(
      jsonData['data'] as Map<String, dynamic>,
    );
    return result;
  }
}
