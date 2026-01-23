import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/services/navigation_service.dart';
import '../../../booking/domain/entities/booking_entity.dart';
import '../../domain/entities/agent_state_entity.dart';
import '../../domain/entities/function_call_entity.dart';

/// Agentic AI Service - handles function calling, state management, and navigation
class AgenticAIService {
  final NavigationService navigationService;

  AgentStateEntity _agentState = const AgentStateEntity();

  // Hotel booking data cache
  Map<String, dynamic> _hotelSearchResults = {};
  Map<String, dynamic> _selectedHotel = {};
  // Reserved for future room selection tracking
  // ignore: unused_field
  final Map<String, dynamic> _selectedRoom = {};
  Map<String, dynamic> _bookingData = {};

  AgenticAIService({required this.navigationService});

  AgentStateEntity get agentState => _agentState;

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Map<String, dynamic> _applyDefaultScenario(Map<String, dynamic> args) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    final updated = Map<String, dynamic>.from(args);

    updated['location'] = (updated['location'] ?? 'Jakarta').toString();
    updated['check_in'] = (updated['check_in'] ?? _formatDate(today))
        .toString();
    updated['check_out'] = (updated['check_out'] ?? _formatDate(tomorrow))
        .toString();

    if (updated['amenities'] == null) {
      updated['amenities'] = ['Free WiFi', 'Swimming Pool'];
    } else if (updated['amenities'] is String) {
      updated['amenities'] = [(updated['amenities'] as String).trim()];
    }

    return updated;
  }

  String? _resolveRoomId(Map<String, dynamic> args) {
    final roomId = args['room_id'] as String?;
    if (roomId != null && roomId.isNotEmpty) {
      return roomId;
    }

    final roomType = args['room_type']?.toString();
    final hotelRooms = _selectedHotel['roomTypes'] as List?;
    if (roomType != null && hotelRooms != null) {
      for (final room in hotelRooms) {
        final name = (room['name'] ?? '').toString().toLowerCase();
        if (name.contains(roomType.toLowerCase())) {
          return room['id']?.toString();
        }
      }
    }

    if (hotelRooms != null && hotelRooms.isNotEmpty) {
      return hotelRooms.first['id']?.toString();
    }

    return null;
  }

  Map<String, dynamic> _normalizeBookingArgs(Map<String, dynamic> args) {
    final normalized = Map<String, dynamic>.from(_applyDefaultScenario(args));
    final constraints = _agentState.userConstraints;

    normalized['check_in'] =
        (args['check_in'] ?? constraints['check_in'] ?? normalized['check_in'])
            .toString();
    normalized['check_out'] =
        (args['check_out'] ??
                constraints['check_out'] ??
                normalized['check_out'])
            .toString();

    normalized['guests'] = args['guests'] ?? constraints['guests'] ?? 2;
    normalized['rooms'] = args['rooms'] ?? constraints['rooms'] ?? 1;

    final hotelId =
        args['hotel_id'] ?? _selectedHotel['id'] ?? normalized['hotel_id'];
    if (hotelId != null) {
      normalized['hotel_id'] = hotelId.toString();
    }

    final roomId = _resolveRoomId(args) ?? normalized['room_id'];
    if (roomId != null) {
      normalized['room_id'] = roomId.toString();
    }

    return normalized;
  }

  BookingEntity? _buildBookingEntityFromCache() {
    if (_bookingData.isEmpty) return null;

    final hotel = _bookingData['hotel'] as Map<String, dynamic>?;
    final room = _bookingData['room'] as Map<String, dynamic>?;
    final bookingDetails =
        _bookingData['booking_details'] as Map<String, dynamic>?;
    final guestInfo = _bookingData['guest_info'] as Map<String, dynamic>?;
    final pricing = _bookingData['pricing'] as Map<String, dynamic>?;
    final cancellationPolicy =
        _bookingData['cancellation_policy'] as Map<String, dynamic>?;

    if (hotel == null ||
        room == null ||
        bookingDetails == null ||
        guestInfo == null ||
        pricing == null) {
      return null;
    }

    final primaryGuest =
        guestInfo['primaryGuest'] as Map<String, dynamic>? ?? {};

    return BookingEntity(
      bookingId:
          _bookingData['booking_id']?.toString() ??
          _bookingData['bookingId']?.toString() ??
          'temp-booking',
      confirmationNumber: _bookingData['confirmation_number']?.toString(),
      bookingStatus: _bookingData['status']?.toString() ?? 'pending',
      hotel: HotelInfoEntity(
        id: hotel['id'].toString(),
        name: hotel['name'].toString(),
        address: hotel['address'].toString(),
        rating: (hotel['rating'] as num).toDouble(),
        imageUrl: hotel['imageUrl'].toString(),
        phone: hotel['phone'].toString(),
        email: hotel['email'].toString(),
      ),
      room: RoomInfoEntity(
        id: room['id'].toString(),
        name: room['name'].toString(),
        imageUrl: room['imageUrl'].toString(),
        bedType: room['bedType'].toString(),
        maxGuests: (room['maxGuests'] as num).toInt(),
      ),
      bookingDetails: BookingDetailsEntity(
        checkIn: bookingDetails['checkIn'].toString(),
        checkOut: bookingDetails['checkOut'].toString(),
        checkInTime: bookingDetails['checkInTime'].toString(),
        checkOutTime: bookingDetails['checkOutTime'].toString(),
        nights: (bookingDetails['nights'] as num).toInt(),
        guests: (bookingDetails['guests'] as num).toInt(),
        rooms: (bookingDetails['rooms'] as num).toInt(),
      ),
      guestInfo: GuestInfoEntity(
        primaryGuest: PrimaryGuestEntity(
          title: primaryGuest['title'].toString(),
          fullName: primaryGuest['fullName'].toString(),
          email: primaryGuest['email'].toString(),
          phone: primaryGuest['phone'].toString(),
        ),
        specialRequests: guestInfo['specialRequests']?.toString(),
      ),
      pricing: PricingEntity(
        subtotal: (pricing['subtotal'] as num).toDouble(),
        taxes: (pricing['taxes'] as num).toDouble(),
        fees: (pricing['fees'] as num).toDouble(),
        discount: (pricing['discount'] as num).toDouble(),
        grandTotal: (pricing['grandTotal'] as num).toDouble(),
        currency: pricing['currency'].toString(),
        dueNow: pricing['dueNow'] == null
            ? null
            : (pricing['dueNow'] as num).toDouble(),
        dueAtProperty: pricing['dueAtProperty'] == null
            ? null
            : (pricing['dueAtProperty'] as num).toDouble(),
      ),
      cancellationPolicy: cancellationPolicy == null
          ? null
          : CancellationPolicyEntity(
              type: cancellationPolicy['type'].toString(),
              description: cancellationPolicy['description'].toString(),
              refundable: cancellationPolicy['refundable'] as bool,
              deadline: cancellationPolicy['deadline'] == null
                  ? null
                  : DateTime.tryParse(
                      cancellationPolicy['deadline'].toString(),
                    ),
            ),
    );
  }

  String _buildHotelListSpeech(List<Map<String, dynamic>> hotels, String city) {
    if (hotels.isEmpty) {
      return 'Maaf, saya tidak menemukan hotel yang sesuai di $city. '
          'Apakah Anda ingin mengubah tanggal atau fasilitas?';
    }

    final buffer = StringBuffer();
    buffer.writeln('Saya menemukan ${hotels.length} hotel di $city.');
    buffer.writeln('Berikut daftarnya:');

    for (var i = 0; i < hotels.length; i++) {
      final hotel = hotels[i];
      final name = hotel['name'] ?? 'Hotel';
      final location = hotel['location'] ?? city;
      final rating = hotel['rating'] ?? '-';
      final price = hotel['pricePerNight'] ?? '-';
      final amenities = (hotel['amenities'] as List?)?.cast<String>().join(
        ', ',
      );

      buffer.writeln(
        '${i + 1}. $name di $location, rating $rating, '
        'mulai IDR $price per malam'
        '${amenities != null ? ', fasilitas: $amenities' : ''}.',
      );
    }

    buffer.writeln('Hotel mana yang ingin Anda lihat detailnya?');
    return buffer.toString();
  }

  /// Get available function definitions for OpenAI
  List<Map<String, dynamic>> getFunctionDefinitions() {
    return [
      {
        'type': 'function',
        'name': 'search_hotels',
        'description':
            'Search for hotels based on location, dates, and guest requirements',
        'parameters': {
          'type': 'object',
          'properties': {
            'location': {
              'type': 'string',
              'description': 'City or location to search',
            },
            'check_in': {
              'type': 'string',
              'description': 'Check-in date (YYYY-MM-DD)',
            },
            'check_out': {
              'type': 'string',
              'description': 'Check-out date (YYYY-MM-DD)',
            },
            'guests': {'type': 'integer', 'description': 'Number of guests'},
            'rooms': {
              'type': 'integer',
              'description': 'Number of rooms',
              'default': 1,
            },
            'amenities': {
              'type': 'array',
              'items': {'type': 'string'},
              'description': 'Requested hotel amenities',
            },
          },
          'required': ['location', 'check_in', 'check_out', 'guests'],
        },
      },
      {
        'type': 'function',
        'name': 'get_hotel_details',
        'description': 'Get detailed information about a specific hotel',
        'parameters': {
          'type': 'object',
          'properties': {
            'hotel_id': {
              'type': 'string',
              'description': 'Unique hotel identifier',
            },
          },
          'required': ['hotel_id'],
        },
      },
      {
        'type': 'function',
        'name': 'check_availability',
        'description': 'Check room availability for specific dates',
        'parameters': {
          'type': 'object',
          'properties': {
            'hotel_id': {'type': 'string', 'description': 'Hotel identifier'},
            'room_type': {'type': 'string', 'description': 'Type of room'},
            'check_in': {'type': 'string', 'description': 'Check-in date'},
            'check_out': {'type': 'string', 'description': 'Check-out date'},
          },
          'required': ['hotel_id', 'room_type', 'check_in', 'check_out'],
        },
      },
      {
        'type': 'function',
        'name': 'get_pricing',
        'description': 'Get pricing information for a room',
        'parameters': {
          'type': 'object',
          'properties': {
            'hotel_id': {'type': 'string'},
            'room_id': {'type': 'string'},
            'check_in': {'type': 'string'},
            'check_out': {'type': 'string'},
            'guests': {'type': 'integer'},
          },
          'required': [
            'hotel_id',
            'room_id',
            'check_in',
            'check_out',
            'guests',
          ],
        },
      },
      {
        'type': 'function',
        'name': 'create_booking',
        'description': 'Create a new booking reservation',
        'parameters': {
          'type': 'object',
          'properties': {
            'hotel_id': {'type': 'string'},
            'room_id': {'type': 'string'},
            'check_in': {'type': 'string'},
            'check_out': {'type': 'string'},
            'guest_info': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'},
                'email': {'type': 'string'},
                'phone': {'type': 'string'},
              },
            },
          },
          'required': [
            'hotel_id',
            'room_id',
            'check_in',
            'check_out',
            'guest_info',
          ],
        },
      },
      {
        'type': 'function',
        'name': 'confirm_booking',
        'description': 'Confirm and finalize a booking',
        'parameters': {
          'type': 'object',
          'properties': {
            'booking_id': {'type': 'string'},
            'payment_method': {'type': 'string'},
          },
          'required': ['booking_id'],
        },
      },
      {
        'type': 'function',
        'name': 'navigate_to_screen',
        'description': 'Navigate to a specific screen in the app',
        'parameters': {
          'type': 'object',
          'properties': {
            'screen_name': {
              'type': 'string',
              'enum': [
                'home',
                'hotel_list',
                'hotel_detail',
                'booking_summary',
                'booking_guest_info',
                'booking_payment',
                'booking_confirmation',
                'search',
                'notifications',
              ],
            },
            'params': {'type': 'object', 'description': 'Screen parameters'},
          },
          'required': ['screen_name'],
        },
      },
      {
        'type': 'function',
        'name': 'update_booking_step',
        'description': 'Update the current booking step in the agent state',
        'parameters': {
          'type': 'object',
          'properties': {
            'step': {
              'type': 'string',
              'enum': [
                'idle',
                'searching',
                'selecting',
                'viewingDetails',
                'confirmingBooking',
                'bookingCompleted',
              ],
            },
          },
          'required': ['step'],
        },
      },
    ];
  }

  /// Execute a function call
  Future<FunctionResultEntity> executeFunction(
    FunctionCallEntity functionCall,
  ) async {
    print('Executing function: ${functionCall.name}');

    try {
      dynamic result;

      switch (functionCall.name) {
        case 'search_hotels':
          result = await _searchHotels(functionCall.arguments);
          break;

        case 'get_hotel_details':
          result = await _getHotelDetails(functionCall.arguments);
          break;

        case 'check_availability':
          result = await _checkAvailability(functionCall.arguments);
          break;

        case 'get_pricing':
          result = await _getPricing(functionCall.arguments);
          break;

        case 'create_booking':
          result = await _createBooking(functionCall.arguments);
          break;

        case 'confirm_booking':
          result = await _confirmBooking(functionCall.arguments);
          break;

        case 'navigate_to_screen':
          result = await _navigateToScreen(functionCall.arguments);
          break;

        case 'update_booking_step':
          result = await _updateBookingStep(functionCall.arguments);
          break;

        default:
          result = {'error': 'Unknown function: ${functionCall.name}'};
      }

      return FunctionResultEntity(callId: functionCall.callId, result: result);
    } catch (e) {
      print('Function execution error: $e');
      return FunctionResultEntity(
        callId: functionCall.callId,
        error: e.toString(),
      );
    }
  }

  // Function implementations

  Future<Map<String, dynamic>> _searchHotels(Map<String, dynamic> args) async {
    final normalizedArgs = _applyDefaultScenario(args);

    _updateAgentState(
      currentStep: BookingStep.searching,
      userConstraints: normalizedArgs,
    );

    // Load mock hotel list data
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

    _hotelSearchResults = {
      'hotels': filteredHotels,
      'total': filteredHotels.length,
      'location': normalizedArgs['location'],
      'check_in': normalizedArgs['check_in'],
      'check_out': normalizedArgs['check_out'],
      'amenities': normalizedArgs['amenities'],
    };

    // Navigate to hotel list
    await navigationService.navigateTo(
      screenName: 'hotel_list',
      params: normalizedArgs,
    );

    _updateAgentState(
      currentStep: BookingStep.selecting,
      currentScreen: 'hotel_list',
    );

    final assistantPrompt = _buildHotelListSpeech(
      filteredHotels,
      normalizedArgs['location'].toString(),
    );

    return {
      'success': true,
      'message':
          'Found ${_hotelSearchResults['total']} hotels in ${normalizedArgs['location']}',
      'hotels': _hotelSearchResults['hotels'],
      'assistant_prompt': assistantPrompt,
    };
  }

  Future<Map<String, dynamic>> _getHotelDetails(
    Map<String, dynamic> args,
  ) async {
    final hotelId = args['hotel_id'] as String;

    _updateAgentState(
      currentStep: BookingStep.viewingDetails,
      appState: {'selected_hotel_id': hotelId},
    );

    // Load mock hotel detail data
    final jsonString = await rootBundle.loadString(
      'lib/features/hotel_detail/mock/hotel_detail_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    // Find the hotel by ID
    _selectedHotel = jsonData['hotels'][hotelId] ?? jsonData['hotels']['1'];

    // Navigate to hotel detail
    await navigationService.navigateTo(
      screenName: 'hotel_detail',
      params: {'hotel_id': hotelId},
    );

    _updateAgentState(currentScreen: 'hotel_detail');

    return {
      'success': true,
      'hotel': _selectedHotel,
      'message': 'Hotel details retrieved for ${_selectedHotel['name']}',
    };
  }

  Future<Map<String, dynamic>> _checkAvailability(
    Map<String, dynamic> args,
  ) async {
    // Load mock room availability data
    final jsonString = await rootBundle.loadString(
      'lib/features/room/mock/room_list_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    final rooms = jsonData['data']['rooms'] as List;
    final availableRooms = rooms
        .where((room) => room['availableRooms'] > 0)
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

  Future<Map<String, dynamic>> _getPricing(Map<String, dynamic> args) async {
    // Load mock pricing data
    final jsonString = await rootBundle.loadString(
      'lib/features/booking/mock/price_calculation_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    final pricingData = jsonData['data'];

    return {
      'success': true,
      'pricing': {
        'subtotal': pricingData['totalPrice']['subtotal'],
        'taxes': pricingData['totalPrice']['totalTax'],
        'fees': pricingData['totalPrice']['totalFees'],
        'discount': pricingData['totalPrice']['discount'],
        'total': pricingData['totalPrice']['grandTotal'],
        'currency': pricingData['totalPrice']['currency'],
        'nights': pricingData['nights'],
        'price_per_night':
            pricingData['priceBreakdown']['roomRate']['pricePerNight'],
      },
      'message':
          'Total price: IDR ${pricingData['totalPrice']['grandTotal']} for ${pricingData['nights']} nights',
    };
  }

  Future<Map<String, dynamic>> _createBooking(Map<String, dynamic> args) async {
    final normalizedArgs = _normalizeBookingArgs(args);

    _updateAgentState(
      currentStep: BookingStep.confirmingBooking,
      appState: normalizedArgs,
    );

    // Load mock booking summary data
    final jsonString = await rootBundle.loadString(
      'lib/features/booking/mock/booking_summary_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    final bookingSeed = jsonData['data'] as Map<String, dynamic>;

    final selectedHotelId = normalizedArgs['hotel_id']?.toString();
    final selectedRoomId = normalizedArgs['room_id']?.toString();

    Map<String, dynamic> hotelData = _selectedHotel;
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

    final checkIn =
        normalizedArgs['check_in']?.toString() ??
        bookingSeed['bookingDetails']['checkIn'].toString();
    final checkOut =
        normalizedArgs['check_out']?.toString() ??
        bookingSeed['bookingDetails']['checkOut'].toString();
    final parsedCheckIn = DateTime.tryParse(checkIn);
    final parsedCheckOut = DateTime.tryParse(checkOut);
    var nights = bookingSeed['bookingDetails']['nights'] as int? ?? 1;
    if (parsedCheckIn != null && parsedCheckOut != null) {
      final diff = parsedCheckOut.difference(parsedCheckIn).inDays;
      if (diff > 0) {
        nights = diff;
      }
    }

    final guests =
        normalizedArgs['guests'] as int? ??
        bookingSeed['bookingDetails']['guests'] as int? ??
        2;
    final rooms =
        normalizedArgs['rooms'] as int? ??
        bookingSeed['bookingDetails']['rooms'] as int? ??
        1;

    final policy = hotelData.isNotEmpty
        ? hotelData['policies'] as Map<String, dynamic>?
        : null;

    final bookingDetails = {
      'checkIn': checkIn,
      'checkOut': checkOut,
      'checkInTime':
          policy?['checkIn'] ?? bookingSeed['bookingDetails']['checkInTime'],
      'checkOutTime':
          policy?['checkOut'] ?? bookingSeed['bookingDetails']['checkOutTime'],
      'nights': nights,
      'guests': guests,
      'rooms': rooms,
    };

    final basePricing = bookingSeed['pricing'] as Map<String, dynamic>;
    final pricePerNight =
        (roomData?['pricePerNight'] as num?)?.toDouble() ??
        (basePricing['subtotal'] as num).toDouble() /
            (bookingSeed['bookingDetails']['nights'] as int? ?? 1);
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
    final guestInfo = guestInfoArgs != null
        ? {
            'primaryGuest': {
              'title': 'Mr',
              'fullName':
                  guestInfoArgs['name']?.toString() ??
                  bookingSeed['guestInfo']['primaryGuest']['fullName'],
              'email':
                  guestInfoArgs['email']?.toString() ??
                  bookingSeed['guestInfo']['primaryGuest']['email'],
              'phone':
                  guestInfoArgs['phone']?.toString() ??
                  bookingSeed['guestInfo']['primaryGuest']['phone'],
            },
            'specialRequests': bookingSeed['guestInfo']['specialRequests'],
          }
        : bookingSeed['guestInfo'];

    final baseHotel = bookingSeed['hotel'] as Map<String, dynamic>;
    final mergedHotel = {
      ...baseHotel,
      if (hotelData.isNotEmpty) ...{
        'id': hotelData['id']?.toString() ?? baseHotel['id'],
        'name': hotelData['name'] ?? baseHotel['name'],
        'address': hotelData['address'] ?? baseHotel['address'],
        'rating': hotelData['rating'] ?? baseHotel['rating'],
        'imageUrl': hotelData['imageUrl'] ?? baseHotel['imageUrl'],
      },
    };

    final baseRoom = bookingSeed['room'] as Map<String, dynamic>;
    final mergedRoom = {
      ...baseRoom,
      if (roomData != null) ...{
        'id': roomData['id']?.toString() ?? baseRoom['id'],
        'name': roomData['name'] ?? baseRoom['name'],
        'imageUrl': roomData['imageUrl'] ?? baseRoom['imageUrl'],
        'bedType': roomData['bedType'] ?? baseRoom['bedType'],
        'maxGuests': roomData['maxGuests'] ?? baseRoom['maxGuests'],
      },
    };

    _bookingData = {
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

    final bookingEntity = _buildBookingEntityFromCache();
    final navigationParams = {
      ...normalizedArgs,
      if (bookingEntity != null) 'booking': bookingEntity,
    };

    // Navigate to booking summary
    await navigationService.navigateTo(
      screenName: 'booking_summary',
      params: navigationParams,
    );

    _updateAgentState(currentScreen: 'booking_summary');

    return {
      'success': true,
      'booking': _bookingData,
      'message':
          'Booking created. Please review the details before confirming.',
    };
  }

  Future<Map<String, dynamic>> _confirmBooking(
    Map<String, dynamic> args,
  ) async {
    _updateAgentState(currentStep: BookingStep.bookingCompleted);

    // Load mock booking confirmation data
    final jsonString = await rootBundle.loadString(
      'lib/features/booking/mock/booking_confirmation_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    final confirmationData = jsonData['data'];

    _bookingData['status'] = 'confirmed';
    _bookingData['confirmation_number'] =
        confirmationData['confirmationNumber'];
    _bookingData['booking_id'] = confirmationData['bookingId'];

    final message =
        '''
Pemesanan Anda telah berhasil dikonfirmasi dengan nomor konfirmasi ${confirmationData['confirmationNumber']}.

Hotel: ${confirmationData['hotel']['name']}
Kamar: ${confirmationData['room']['roomType']}
Check-in: ${confirmationData['bookingDetails']['checkIn']}
Check-out: ${confirmationData['bookingDetails']['checkOut']}

Untuk melanjutkan pembayaran, silakan lakukan pembayaran secara manual melalui halaman Pembayaran di aplikasi dengan total IDR ${confirmationData['pricing']['grandTotal']}.

Terima kasih telah menggunakan layanan kami. Semoga Anda menikmati pengalaman menginap Anda. Sampai jumpa!
''';

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

  Future<Map<String, dynamic>> _navigateToScreen(
    Map<String, dynamic> args,
  ) async {
    final screenName = args['screen_name'] as String;
    final params = args['params'] as Map<String, dynamic>?;
    final resolvedParams = params != null
        ? Map<String, dynamic>.from(params)
        : <String, dynamic>{};

    if (screenName == 'booking_payment' ||
        screenName == 'booking_guest_info' ||
        screenName == 'booking_confirmation') {
      if (!resolvedParams.containsKey('booking')) {
        final bookingEntity = _buildBookingEntityFromCache();
        if (bookingEntity != null) {
          resolvedParams['booking'] = bookingEntity;
        }
      }
    }

    await navigationService.navigateTo(
      screenName: screenName,
      params: resolvedParams,
    );

    _updateAgentState(currentScreen: screenName);

    return {'success': true, 'current_screen': screenName};
  }

  Future<Map<String, dynamic>> _updateBookingStep(
    Map<String, dynamic> args,
  ) async {
    final stepName = args['step'] as String;
    final step = BookingStep.values.firstWhere(
      (s) => s.name == stepName,
      orElse: () => BookingStep.idle,
    );

    _updateAgentState(currentStep: step);

    return {'success': true, 'step': stepName};
  }

  /// Update agent state
  void _updateAgentState({
    BookingStep? currentStep,
    Map<String, dynamic>? userConstraints,
    Map<String, dynamic>? appState,
    String? currentScreen,
  }) {
    _agentState = _agentState.copyWith(
      currentStep: currentStep,
      userConstraints: userConstraints ?? _agentState.userConstraints,
      appState: appState ?? _agentState.appState,
      currentScreen: currentScreen,
    );

    print('Agent state updated: ${_agentState.currentStep.name}');
  }

  /// Get system instructions for the AI agent
  String getSystemInstructions() {
    return '''
# IDENTITAS & PERAN

Anda adalah **Asisten Pemesanan Hotel Berbasis Suara** untuk aplikasi Qora Hotel Booking.
Anda harus **SELALU BERBICARA LEBIH DULU** dan **AKTIF MEMANDU** pengguna melalui proses pemesanan hotel dari awal hingga konfirmasi.

**Konteks Saat Ini:**
- Tahap Pemesanan: ${_agentState.currentStep.name}
- Layar Aktif: ${_agentState.currentScreen ?? 'tidak diketahui'}
- Data Pengguna: ${jsonEncode(_agentState.userConstraints)}

---

# PRINSIP INTI

## 1. PANDUAN SUARA PROAKTIF
- **SELALU mulai percakapan terlebih dahulu**
- **JANGAN PERNAH menunggu dalam keheningan** - jika pengguna tidak merespons, lanjutkan dengan panduan
- Ajukan pertanyaan yang jelas dan langsung
- Pastikan pengguna selalu tahu langkah berikutnya

## 2. ALUR PEMESANAN LANGKAH DEMI LANGKAH
Pandu pengguna melalui tahapan ini **SECARA BERURUTAN**:

1. **Lokasi Hotel** - "Di kota mana Anda ingin menginap?"
2. **Tanggal Check-in** - "Kapan Anda ingin check-in?"
3. **Tanggal Check-out** - "Kapan Anda berencana check-out?"
4. **Jumlah Tamu** - "Berapa jumlah tamu yang akan menginap?"
5. **Jumlah Kamar** - "Berapa kamar yang Anda butuhkan?"
6. **Pilih Hotel** - "Saya akan tampilkan hotel yang tersedia, hotel mana yang Anda minati?"
7. **Pilih Kamar** - "Tipe kamar apa yang Anda inginkan?"
8. **Review Ringkasan** - Setelah kamar dipilih, **WAJIB panggil** `create_booking` untuk menampilkan ringkasan pemesanan.
9. **Konfirmasi Pemesanan** - "Apakah Anda ingin mengkonfirmasi pemesanan ini?"

## 3. BAHASA & GAYA KOMUNIKASI
- **WAJIB berbicara dalam Bahasa Indonesia yang alami**
- Gunakan kalimat pendek, ramah, dan jelas
- Hindari istilah teknis
- Suara seperti resepsionis hotel yang membantu

---

# ATURAN KONTROL PERCAKAPAN

✅ **LAKUKAN:**
- Ajukan **SATU pertanyaan jelas** pada satu waktu
- Konfirmasi setiap input pengguna sebelum lanjut ke tahap berikutnya
- Akui setiap data yang diterima (contoh: "Baik, lokasi Jakarta sudah tercatat")
- Jika pengguna memberikan informasi tidak lengkap, minta klarifikasi dengan sopan
- Jika pengguna ingin mengubah data sebelumnya, bantu mereka dengan lancar

❌ **JANGAN LAKUKAN:**
- Menunggu dalam diam
- Bertanya banyak hal sekaligus
- Langsung melanjutkan tanpa konfirmasi
- Menggunakan Bahasa Inggris kecuali diminta
- Memproses pembayaran (Anda TIDAK memiliki akses ke fitur pembayaran)

---

# NAVIGASI APLIKASI & UI

Anda memiliki kemampuan untuk:
- Memahami bahwa UI aplikasi dapat berubah otomatis berdasarkan input pengguna
- Mengakui secara verbal ketika parameter pemesanan lengkap
- Menginstruksikan aplikasi untuk navigasi antar layar menggunakan fungsi internal
- **WAJIB melakukan navigasi otomatis** segera setelah data cukup (mis. setelah `search_hotels`, tampilkan daftar hotel)

Contoh Respons:
> "Baik, saya sudah mencatat lokasi dan tanggal menginap Anda. Saya akan menampilkan daftar hotel yang sesuai."

---

# TAHAP RINGKASAN & KONFIRMASI PEMESANAN

Ketika pengguna mencapai **Halaman Ringkasan Pemesanan**, Anda HARUS:

1. **Jelaskan dengan jelas:**
   - Nama hotel
   - Tipe kamar
   - Tanggal check-in dan check-out
   - Jumlah tamu
   - Total harga dalam IDR (Rupiah)

2. **Tanyakan konfirmasi:**
   > "Baik, ini detail pemesanan Anda:
   > Hotel [nama hotel], kamar [tipe kamar],
   > Check-in [tanggal], check-out [tanggal],
   > Untuk [jumlah] tamu,
   > Dengan total harga IDR [jumlah].
   > 
   > Apakah semua detail pemesanan ini sudah benar dan ingin Anda konfirmasi?"

---

# HALAMAN INFORMASI TAMU

Ketika pengguna berada di **Halaman Informasi Tamu**:
- **JANGAN minta nama, email, atau nomor telepon lagi** (sudah terisi otomatis)
- **Bacakan nama tamu utama** dan minta konfirmasi singkat
- **Tanya permintaan khusus** (special requests)
- Jika pengguna **tidak ada permintaan khusus**, **langsung lanjutkan ke pembayaran**

Contoh:
> "Data tamu utama atas nama [nama]. Apakah sudah benar? Ada permintaan khusus?"

Jika sudah benar dan tidak ada permintaan khusus, panggil `navigate_to_screen` ke `booking_payment`.

---

# PENANGANAN PEMBAYARAN (KRITIKAL)

⚠️ **ANDA TIDAK MEMILIKI AKSES KE FITUR PEMBAYARAN**

Setelah pengguna mengkonfirmasi pemesanan:

1. **Respons dengan pesan suara wajib:**
   > "Pemesanan Anda telah berhasil dikonfirmasi dengan nomor konfirmasi [nomor].
   > 
   > Untuk melanjutkan pembayaran, silakan lakukan pembayaran secara manual melalui halaman Pembayaran di aplikasi dengan total IDR [jumlah].
   > 
   > Terima kasih telah menggunakan layanan kami. Semoga Anda menikmati pengalaman menginap Anda. Sampai jumpa!"

2. **SETELAH pesan ini:**
   - **AKHIRI percakapan**
   - **JANGAN menunggu respons pengguna lagi**
   - Sistem akan otomatis memutuskan koneksi voice assistant

---

# FUNGSI YANG TERSEDIA

- `search_hotels` - Cari hotel berdasarkan lokasi dan tanggal (mengembalikan data hotel real)
- `get_hotel_details` - Lihat detail lengkap hotel dengan kamar dan fasilitas
- `check_availability` - Verifikasi ketersediaan kamar untuk tanggal tertentu
- `get_pricing` - Dapatkan rincian harga (termasuk pajak, biaya, diskon)
- `create_booking` - Mulai pemesanan (membuat ringkasan pemesanan)
- `confirm_booking` - Finalisasi reservasi (menghasilkan nomor konfirmasi)
- `navigate_to_screen` - Kontrol navigasi aplikasi untuk menampilkan layar yang relevan
- `update_booking_step` - Lacak progres pemesanan secara internal

---

# PENANGANAN ERROR & KASUS KHUSUS

**Jika pengguna bertanya tentang metode pembayaran:**
> "Untuk pembayaran, Anda dapat memilih metode pembayaran setelah konfirmasi pemesanan di halaman Pembayaran aplikasi."

**Jika pengguna mencoba berbicara setelah konfirmasi:**
> "Pemesanan Anda sudah dikonfirmasi. Silakan lanjutkan ke halaman Pembayaran untuk menyelesaikan transaksi. Terima kasih!"
[Kemudian putuskan koneksi]

**Jika pengguna bingung:**
> "Tidak masalah, saya akan bantu Anda. [ulangi pertanyaan terakhir dengan lebih jelas]"

**Jika data tidak valid (tanggal di masa lalu, tamu 0, dll):**
> "Maaf, [jelaskan masalahnya]. Bisakah Anda berikan [data yang benar]?"

---

# KEPRIBADIAN & NADA SUARA

✨ **Karakteristik:**
- Ramah dan hangat
- Profesional
- Tenang dan sabar
- Percaya diri
- Mendukung dan membantu

💬 **Contoh Sapaan Pembuka:**
> "Selamat datang di Qora! Saya asisten pemesanan hotel Anda. Saya akan membantu Anda menemukan dan memesan hotel yang sempurna. Mari kita mulai! Di kota mana Anda ingin menginap?"

---

# PANDUAN KHUSUS HARGA

- **SELALU gunakan mata uang IDR (Rupiah Indonesia)**
- Sebutkan harga dengan jelas dan lengkap dengan pajak
- Format: "IDR 1.500.000" atau "satu juta lima ratus ribu rupiah"
- Jelaskan rincian jika ditanya (tarif kamar, pajak layanan 10%, PPN 11%, biaya booking)

---

# SKENARIO UTAMA (FOKUS)

Gunakan fokus skenario berikut bila pengguna belum memberi detail lengkap:
- Lokasi: **Jakarta**
- Check-in: **hari ini**
- Check-out: **besok**
- Fasilitas: **Free WiFi** dan **Swimming Pool**

Jika pengguna setuju, lanjutkan otomatis ke pencarian dan navigasi daftar hotel.

---

**INGAT: Anda adalah pemandu, bukan pendengar pasif. SELALU ambil inisiatif dalam percakapan!**
''';
  }
}
