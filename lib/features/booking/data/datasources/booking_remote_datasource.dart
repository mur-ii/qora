import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/services/booking_network_metrics_tracker.dart';
import '../../../../core/services/performance_runtime_metrics_service.dart';
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
  final PerformanceRuntimeMetricsService _runtimeMetrics =
      PerformanceRuntimeMetricsService.instance;
  final BookingNetworkMetricsTracker _networkMetricsTracker =
      BookingNetworkMetricsTracker.instance;

  @override
  Future<BookingModel> getBookingSummary({
    required String hotelId,
    required String roomId,
    required String checkIn,
    required String checkOut,
    required int guests,
    required int rooms,
  }) async {
    final startedAt = DateTime.now();
    final requestBytes = _estimatePayloadBytes(<String, dynamic>{
      'hotel_id': hotelId,
      'room_id': roomId,
      'check_in': checkIn,
      'check_out': checkOut,
      'guests': guests,
      'rooms': rooms,
    });
    final stopwatch = Stopwatch()..start();

    try {
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
          (data['bookingDetails'] as Map<String, dynamic>)['nights'] as int? ??
          1;
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
      stopwatch.stop();
      final responseBytes = _estimatePayloadBytes(result.toJson());
      _recordRequest(
        requestName: 'get_booking_summary',
        startedAt: startedAt,
        duration: stopwatch.elapsed,
        txBytes: requestBytes,
        rxBytes: responseBytes,
        success: true,
      );
      return result;
    } catch (error) {
      stopwatch.stop();
      _recordRequest(
        requestName: 'get_booking_summary',
        startedAt: startedAt,
        duration: stopwatch.elapsed,
        txBytes: requestBytes,
        rxBytes: 0,
        success: false,
        error: error.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<BookingModel> submitGuestInfo({
    required String bookingId,
    required GuestFormEntity guestInfo,
  }) async {
    final startedAt = DateTime.now();
    final requestBytes = _estimatePayloadBytes(<String, dynamic>{
      'booking_id': bookingId,
      'guest_info': <String, dynamic>{
        'title': guestInfo.title,
        'full_name': guestInfo.fullName,
        'email': guestInfo.email,
        'phone': guestInfo.phone,
        'special_requests': guestInfo.specialRequests,
      },
    });
    final stopwatch = Stopwatch()..start();

    try {
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
      stopwatch.stop();
      final responseBytes = _estimatePayloadBytes(result.toJson());
      _recordRequest(
        requestName: 'submit_guest_info',
        startedAt: startedAt,
        duration: stopwatch.elapsed,
        txBytes: requestBytes,
        rxBytes: responseBytes,
        success: true,
      );
      return result;
    } catch (error) {
      stopwatch.stop();
      _recordRequest(
        requestName: 'submit_guest_info',
        startedAt: startedAt,
        duration: stopwatch.elapsed,
        txBytes: requestBytes,
        rxBytes: 0,
        success: false,
        error: error.toString(),
      );
      rethrow;
    }
  }

  @override
  Future<BookingModel> confirmBooking({
    required String bookingId,
    required String paymentMethod,
  }) async {
    final startedAt = DateTime.now();
    final requestBytes = _estimatePayloadBytes(<String, dynamic>{
      'booking_id': bookingId,
      'payment_method': paymentMethod,
    });
    final stopwatch = Stopwatch()..start();

    try {
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
      stopwatch.stop();
      final responseBytes = _estimatePayloadBytes(result.toJson());
      _recordRequest(
        requestName: 'confirm_booking',
        startedAt: startedAt,
        duration: stopwatch.elapsed,
        txBytes: requestBytes,
        rxBytes: responseBytes,
        success: true,
      );
      return result;
    } catch (error) {
      stopwatch.stop();
      _recordRequest(
        requestName: 'confirm_booking',
        startedAt: startedAt,
        duration: stopwatch.elapsed,
        txBytes: requestBytes,
        rxBytes: 0,
        success: false,
        error: error.toString(),
      );
      rethrow;
    }
  }

  int _estimatePayloadBytes(Map<String, dynamic> payload) {
    return utf8.encode(json.encode(payload)).length;
  }

  void _recordRequest({
    required String requestName,
    required DateTime startedAt,
    required Duration duration,
    required int txBytes,
    required int rxBytes,
    required bool success,
    String? error,
  }) {
    _runtimeMetrics.addHttpTraffic(txBytes: txBytes, rxBytes: rxBytes);
    _networkMetricsTracker.recordRequest(
      requestName: requestName,
      startedAt: startedAt,
      duration: duration,
      txBytes: txBytes,
      rxBytes: rxBytes,
      success: success,
      error: error,
    );
  }
}
