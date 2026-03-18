import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../entities/agent_state_entity.dart';
import 'agentic_ai_context.dart';

class SearchHotelsUseCase {
  final AgenticAiContext context;
  final NavigationService navigationService;

  SearchHotelsUseCase({required this.context, required this.navigationService});

  Future<Map<String, dynamic>> call(Map<String, dynamic> args) async {
    final normalizedArgs = context.applyDefaultScenario(args);
    normalizedArgs['searchKey'] = DateTime.now().millisecondsSinceEpoch
        .toString();

    context.updateAgentState(
      currentStep: BookingStep.searching,
      userConstraints: normalizedArgs,
    );

    final jsonString = await rootBundle.loadString(
      'lib/features/hotel_list/data/mock/hotel_list_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    final hotels = (jsonData['hotels'] as List).cast<Map<String, dynamic>>();
    final requestedAmenities =
        (normalizedArgs['amenities'] as List?)?.cast<String>() ?? [];

    final filteredHotels = hotels.where((hotel) {
      final hotelLocation = (hotel['location'] ?? '').toString().toLowerCase();
      final locationMatch = hotelLocation.contains(
        normalizedArgs['location'].toString().toLowerCase(),
      );

      if (!locationMatch) return false;

      if (requestedAmenities.isEmpty) return true;

      final hotelAmenities =
          (hotel['amenities'] as List?)?.cast<String>() ?? [];
      return requestedAmenities.every(
        (amenity) => hotelAmenities.any(
          (hotelAmenity) => hotelAmenity.toLowerCase() == amenity.toLowerCase(),
        ),
      );
    }).toList();

    context.hotelSearchResults = {
      'hotels': filteredHotels,
      'total': filteredHotels.length,
      'location': normalizedArgs['location'],
      'check_in': normalizedArgs['check_in'],
      'check_out': normalizedArgs['check_out'],
      'amenities': normalizedArgs['amenities'],
    };

    await navigationService.navigateTo(
      screenName: AppRoutes.screenHotelList,
      params: normalizedArgs,
    );

    context.updateAgentState(
      currentStep: BookingStep.selecting,
      currentScreen: AppRoutes.screenHotelList,
    );

    final assistantHotels = filteredHotels
        .map(
          (hotel) => <String, dynamic>{
            'id': hotel['id']?.toString(),
            'name': hotel['name']?.toString(),
          },
        )
        .take(6)
        .toList(growable: false);

    return {
      'success': true,
      'message': 'Pencarian hotel berhasil.',
      'hotels': assistantHotels,
      'assistant_prompt': context.buildHotelListSpeech(
        filteredHotels,
        normalizedArgs['location'].toString(),
      ),
    };
  }
}

class HotelDetailsUseCase {
  final AgenticAiContext context;
  final NavigationService navigationService;

  HotelDetailsUseCase({required this.context, required this.navigationService});

  Future<Map<String, dynamic>> call(Map<String, dynamic> args) async {
    final hotelId = args['hotel_id'] as String;

    context.updateAgentState(
      currentStep: BookingStep.viewingDetails,
      appState: {'selected_hotel_id': hotelId},
    );

    final jsonString = await rootBundle.loadString(
      'lib/features/hotel_detail/mock/hotel_detail_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    final hotels = jsonData['hotels'] as Map<String, dynamic>;
    context.selectedHotel =
        (hotels[hotelId] as Map<String, dynamic>?) ??
        (hotels['1'] as Map<String, dynamic>? ?? {});

    await navigationService.navigateTo(
      screenName: AppRoutes.screenHotelDetail,
      params: {'hotel_id': hotelId},
    );

    context.updateAgentState(currentScreen: AppRoutes.screenHotelDetail);

    final roomTypes =
        (context.selectedHotel['roomTypes'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map>()
            .map(
              (room) => <String, dynamic>{
                'id': room['id']?.toString(),
                'name': room['name']?.toString(),
                'price_per_night': room['pricePerNight'],
              },
            )
            .take(4)
            .toList(growable: false);

    return {
      'success': true,
      'hotel': <String, dynamic>{
        'id': context.selectedHotel['id']?.toString(),
        'name': context.selectedHotel['name']?.toString(),
        'rating': context.selectedHotel['rating'],
        'location': context.selectedHotel['location']?.toString(),
      },
      'room_types': roomTypes,
      'message': 'Detail hotel siap.',
      'assistant_prompt': context.buildHotelDetailPrompt(),
    };
  }
}

class SelectRoomUseCase {
  final AgenticAiContext context;

  SelectRoomUseCase({required this.context});

  Future<Map<String, dynamic>> call(Map<String, dynamic> args) async {
    final normalizedArgs = context.normalizeBookingArgs(args);
    final roomId = normalizedArgs['room_id']?.toString();

    String? roomName;
    if (context.selectedHotel.isNotEmpty) {
      final roomTypes =
          context.selectedHotel['roomTypes'] as List<dynamic>? ?? [];
      if (roomId != null) {
        for (final room in roomTypes) {
          final roomMap = room as Map<String, dynamic>;
          if (roomMap['id']?.toString() == roomId) {
            roomName = roomMap['name']?.toString();
            break;
          }
        }
      }

      roomName ??=
          (roomTypes.isNotEmpty
              ? (roomTypes.first as Map<String, dynamic>)['name']?.toString()
              : null) ??
          'kamar pilihan';
    }

    context.updateAgentState(
      currentStep: BookingStep.selecting,
      appState: normalizedArgs,
      currentScreen: 'hotel_detail',
    );

    return {
      'success': true,
      'selected_room_id': roomId,
      'message': 'Kamar dipilih.',
      'assistant_prompt':
          'Kamar ${roomName ?? 'pilihan Anda'} dipilih. Lanjutkan pemesanan?',
    };
  }
}

class CheckAvailabilityUseCase {
  Future<Map<String, dynamic>> call(Map<String, dynamic> args) async {
    final jsonString = await rootBundle.loadString(
      'lib/features/room/mock/room_list_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    final rooms = jsonData['data']['rooms'] as List;
    final availableRooms = rooms
        .where((room) => (room as Map<String, dynamic>)['availableRooms'] > 0)
        .toList();

    return {
      'success': true,
      'available': availableRooms.isNotEmpty,
      'rooms_available': availableRooms.length,
      'rooms': availableRooms,
      'message': availableRooms.isNotEmpty
          ? 'Found ${availableRooms.length} available rooms for your dates'
          : 'No rooms available for selected dates',
    };
  }
}

class PricingUseCase {
  Future<Map<String, dynamic>> call(Map<String, dynamic> args) async {
    final jsonString = await rootBundle.loadString(
      'lib/features/booking/mock/price_calculation_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    final pricingData = jsonData['data'] as Map<String, dynamic>;
    final totalPrice = pricingData['totalPrice'] as Map<String, dynamic>;
    final priceBreakdown =
        pricingData['priceBreakdown'] as Map<String, dynamic>;
    final roomRate = priceBreakdown['roomRate'] as Map<String, dynamic>;

    return {
      'success': true,
      'pricing': {
        'subtotal': totalPrice['subtotal'],
        'taxes': totalPrice['totalTax'],
        'fees': totalPrice['totalFees'],
        'discount': totalPrice['discount'],
        'total': totalPrice['grandTotal'],
        'currency': totalPrice['currency'],
        'nights': pricingData['nights'],
        'price_per_night': roomRate['pricePerNight'],
      },
      'message':
          'Total price: IDR ${totalPrice['grandTotal']} for ${pricingData['nights']} nights',
    };
  }
}

class CreateBookingUseCase {
  final AgenticAiContext context;
  final NavigationService navigationService;

  CreateBookingUseCase({
    required this.context,
    required this.navigationService,
  });

  Future<Map<String, dynamic>> call(Map<String, dynamic> args) async {
    final normalizedArgs = context.normalizeBookingArgs(args);

    context.updateAgentState(
      currentStep: BookingStep.confirmingBooking,
      appState: normalizedArgs,
    );

    final jsonString = await rootBundle.loadString(
      'lib/features/booking/mock/booking_summary_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    final bookingSeed = jsonData['data'] as Map<String, dynamic>;

    final selectedHotelId = normalizedArgs['hotel_id']?.toString();
    final selectedRoomId = normalizedArgs['room_id']?.toString();

    Map<String, dynamic> hotelData = context.selectedHotel;
    if (hotelData.isEmpty ||
        selectedHotelId != null &&
            hotelData['id']?.toString() != selectedHotelId) {
      final hotelDetailString = await rootBundle.loadString(
        'lib/features/hotel_detail/mock/hotel_detail_response.json',
      );
      final hotelDetailData =
          jsonDecode(hotelDetailString) as Map<String, dynamic>;
      final hotels = hotelDetailData['hotels'] as Map<String, dynamic>?;
      hotelData = selectedHotelId != null
          ? (hotels?[selectedHotelId] as Map<String, dynamic>? ?? {})
          : {};
    }

    Map<String, dynamic>? roomData;
    if (hotelData.isNotEmpty) {
      final roomTypes = hotelData['roomTypes'] as List<dynamic>? ?? [];
      for (final room in roomTypes) {
        final roomMap = room as Map<String, dynamic>;
        if (selectedRoomId != null &&
            roomMap['id']?.toString() == selectedRoomId) {
          roomData = roomMap;
          break;
        }
      }
    }

    final seedBookingDetails =
        bookingSeed['bookingDetails'] as Map<String, dynamic>;
    final checkIn =
        normalizedArgs['check_in']?.toString() ??
        seedBookingDetails['checkIn'].toString();
    final checkOut =
        normalizedArgs['check_out']?.toString() ??
        seedBookingDetails['checkOut'].toString();

    final parsedCheckIn = DateTime.tryParse(checkIn);
    final parsedCheckOut = DateTime.tryParse(checkOut);
    var nights = seedBookingDetails['nights'] as int? ?? 1;
    if (parsedCheckIn != null && parsedCheckOut != null) {
      final diff = parsedCheckOut.difference(parsedCheckIn).inDays;
      if (diff > 0) {
        nights = diff;
      }
    }

    final guests =
        normalizedArgs['guests'] as int? ??
        seedBookingDetails['guests'] as int? ??
        2;
    final rooms =
        normalizedArgs['rooms'] as int? ??
        seedBookingDetails['rooms'] as int? ??
        1;

    final policy = hotelData.isNotEmpty
        ? hotelData['policies'] as Map<String, dynamic>?
        : null;

    final bookingDetails = {
      'checkIn': checkIn,
      'checkOut': checkOut,
      'checkInTime': policy?['checkIn'] ?? seedBookingDetails['checkInTime'],
      'checkOutTime': policy?['checkOut'] ?? seedBookingDetails['checkOutTime'],
      'nights': nights,
      'guests': guests,
      'rooms': rooms,
    };

    final basePricing = bookingSeed['pricing'] as Map<String, dynamic>;
    final seedNights = seedBookingDetails['nights'] as int? ?? 1;
    final pricePerNight =
        (roomData?['pricePerNight'] as num?)?.toDouble() ??
        (basePricing['subtotal'] as num).toDouble() / seedNights;
    final subtotal = pricePerNight * nights * rooms;
    final taxes = subtotal * 0.1;
    final fees = (basePricing['fees'] as num?)?.toDouble() ?? 0.0;
    final discount = (basePricing['discount'] as num?)?.toDouble() ?? 0.0;
    final grandTotal = subtotal + taxes + fees - discount;
    final previousGrandTotal =
        (basePricing['grandTotal'] as num?)?.toDouble() ?? grandTotal;
    final previousDueNow = (basePricing['dueNow'] as num?)?.toDouble();
    final dueNowRatio = (previousDueNow != null && previousGrandTotal > 0)
        ? (previousDueNow / previousGrandTotal)
        : 0.3;
    final dueNow = grandTotal * dueNowRatio;

    final pricing = {
      'subtotal': subtotal,
      'taxes': taxes,
      'fees': fees,
      'discount': discount,
      'grandTotal': grandTotal,
      'currency': basePricing['currency'] ?? 'IDR',
      'dueNow': dueNow,
      'dueAtProperty': grandTotal - dueNow,
    };

    final guestInfoArgs = args['guest_info'] as Map<String, dynamic>?;
    final seedGuestInfo = bookingSeed['guestInfo'] as Map<String, dynamic>;
    final seedPrimaryGuest =
        seedGuestInfo['primaryGuest'] as Map<String, dynamic>? ?? {};
    final guestInfo = guestInfoArgs != null
        ? {
            'primaryGuest': {
              'title': 'Mr',
              'fullName':
                  guestInfoArgs['name']?.toString() ??
                  seedPrimaryGuest['fullName'],
              'email':
                  guestInfoArgs['email']?.toString() ??
                  seedPrimaryGuest['email'],
              'phone':
                  guestInfoArgs['phone']?.toString() ??
                  seedPrimaryGuest['phone'],
            },
            'specialRequests': seedGuestInfo['specialRequests'],
          }
        : seedGuestInfo;

    final baseHotel = bookingSeed['hotel'] as Map<String, dynamic>;
    final mergedHotel = {
      ...baseHotel,
      if (hotelData.isNotEmpty) ...{
        'id': hotelData['id']?.toString() ?? baseHotel['id'],
        'name': hotelData['name'] ?? baseHotel['name'],
        'address': hotelData['address'] ?? baseHotel['address'],
        'rating': hotelData['rating'] ?? baseHotel['rating'],
      },
    };

    final baseRoom = bookingSeed['room'] as Map<String, dynamic>;
    final mergedRoom = {
      ...baseRoom,
      if (roomData != null) ...{
        'id': roomData['id']?.toString() ?? baseRoom['id'],
        'name': roomData['name'] ?? baseRoom['name'],
        'bedType': roomData['bedType'] ?? baseRoom['bedType'],
        'maxGuests': roomData['maxGuests'] ?? baseRoom['maxGuests'],
      },
    };

    context.bookingData = {
      'booking_id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
      'status': 'pending',
      'hotel': mergedHotel,
      'room': mergedRoom,
      'booking_details': bookingDetails,
      'guest_info': guestInfo,
      'pricing': pricing,
      'cancellation_policy': bookingSeed['cancellationPolicy'],
      ...normalizedArgs,
    };

    final bookingEntity = context.buildBookingEntityFromCache();
    final navigationParams = {
      ...normalizedArgs,
      if (bookingEntity != null) 'booking': bookingEntity,
    };

    await navigationService.navigateTo(
      screenName: AppRoutes.screenBookingSummary,
      params: navigationParams,
    );

    context.updateAgentState(currentScreen: AppRoutes.screenBookingSummary);

    return {
      'success': true,
      'booking': <String, dynamic>{
        'booking_id': context.bookingData['booking_id'],
        'hotel_name': mergedHotel['name'],
        'room_name': mergedRoom['name'],
        'check_in': bookingDetails['checkIn'],
        'check_out': bookingDetails['checkOut'],
        'grand_total': pricing['grandTotal'],
        'currency': pricing['currency'],
      },
      'message': 'Booking dibuat. Silakan konfirmasi.',
    };
  }
}

class ConfirmBookingUseCase {
  final AgenticAiContext context;

  ConfirmBookingUseCase({required this.context});

  Future<Map<String, dynamic>> call(Map<String, dynamic> args) async {
    context.updateAgentState(currentStep: BookingStep.bookingCompleted);

    final jsonString = await rootBundle.loadString(
      'lib/features/booking/mock/booking_confirmation_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    final confirmationData = jsonData['data'] as Map<String, dynamic>;

    context.bookingData = {
      ...context.bookingData,
      'status': 'confirmed',
      'confirmation_number': confirmationData['confirmationNumber'],
      'booking_id': confirmationData['bookingId'],
    };

    final message =
        'Booking dikonfirmasi. Nomor ${confirmationData['confirmationNumber']}. '
        'Hotel ${confirmationData['hotel']['name']}, '
        'kamar ${confirmationData['room']['roomType']}.';

    return {
      'success': true,
      'booking': {
        'id': confirmationData['bookingId'],
        'confirmation_number': confirmationData['confirmationNumber'],
        'status': confirmationData['bookingStatus'],
        'hotel': confirmationData['hotel'],
        'room': confirmationData['room'],
        'booking_details': confirmationData['bookingDetails'],
        'guest_info': confirmationData['guestInfo'],
        'pricing': confirmationData['pricing'],
      },
      'message': message,
      'requires_payment': true,
      'requires_disconnect': true,
      'payment_amount': confirmationData['pricing']['grandTotal'],
      'payment_currency': confirmationData['pricing']['currency'],
    };
  }
}

class NavigateToScreenUseCase {
  final AgenticAiContext context;
  final NavigationService navigationService;

  NavigateToScreenUseCase({
    required this.context,
    required this.navigationService,
  });

  Future<Map<String, dynamic>> call(Map<String, dynamic> args) async {
    final screenName = args['screen_name'] as String;
    final params = args['params'] as Map<String, dynamic>?;
    final resolvedParams = params != null
        ? Map<String, dynamic>.from(params)
        : <String, dynamic>{};

    if (screenName == AppRoutes.screenBookingPayment ||
        screenName == AppRoutes.screenBookingGuestInfo ||
        screenName == AppRoutes.screenBookingConfirmation) {
      if (!resolvedParams.containsKey('booking')) {
        final bookingEntity = context.buildBookingEntityFromCache();
        if (bookingEntity != null) {
          resolvedParams['booking'] = bookingEntity;
        }
      }
    }

    await navigationService.navigateTo(
      screenName: screenName,
      params: resolvedParams,
    );

    context.updateAgentState(currentScreen: screenName);

    return {'success': true, 'current_screen': screenName};
  }
}

class UpdateBookingStepUseCase {
  final AgenticAiContext context;

  UpdateBookingStepUseCase({required this.context});

  Future<Map<String, dynamic>> call(Map<String, dynamic> args) async {
    final stepName = args['step'] as String;
    final step = BookingStep.values.firstWhere(
      (value) => value.name == stepName,
      orElse: () => BookingStep.idle,
    );

    context.updateAgentState(currentStep: step);

    return {'success': true, 'step': stepName};
  }
}
