import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/utils/app_logger.dart';
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

  void reset() {
    _agentState = const AgentStateEntity();
    _hotelSearchResults = {};
    _selectedHotel = {};
    _bookingData = {};
  }

  void previewUserConstraints(Map<String, dynamic> args) {
    final normalized = Map<String, dynamic>.from(_applyDefaultScenario(args));
    final constraints = _agentState.userConstraints;

    normalized['rooms'] = args['rooms'] ?? constraints['rooms'] ?? 1;
    normalized['guests'] = args['guests'] ?? constraints['guests'] ?? 2;

    _updateAgentState(userConstraints: normalized);
  }

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
        phone: hotel['phone']?.toString() ?? '',
        email: hotel['email']?.toString() ?? '',
      ),
      room: RoomInfoEntity(
        id: room['id'].toString(),
        name: room['name'].toString(),
        bedType: room['bedType']?.toString() ?? 'Double',
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
        'name': 'select_room',
        'description': 'Select a room type and update UI selection',
        'parameters': {
          'type': 'object',
          'properties': {
            'hotel_id': {'type': 'string'},
            'room_id': {'type': 'string'},
            'room_type': {'type': 'string'},
            'check_in': {'type': 'string'},
            'check_out': {'type': 'string'},
            'guests': {'type': 'integer'},
            'rooms': {'type': 'integer'},
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
                AppRoutes.screenHome,
                AppRoutes.screenHotelList,
                AppRoutes.screenHotelDetail,
                AppRoutes.screenBookingSummary,
                AppRoutes.screenBookingGuestInfo,
                AppRoutes.screenBookingPayment,
                AppRoutes.screenBookingConfirmation,
                AppRoutes.screenSearch,
                AppRoutes.screenNotifications,
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
    AppLogger.info('AgenticAI', 'Executing function: ${functionCall.name}');

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

        case 'select_room':
          result = await _selectRoom(functionCall.arguments);
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
    } catch (e, stackTrace) {
      AppLogger.error(
        'AgenticAI',
        'Function execution error',
        error: e,
        stackTrace: stackTrace,
      );
      return FunctionResultEntity(
        callId: functionCall.callId,
        error: e.toString(),
      );
    }
  }

  // Function implementations

  Future<Map<String, dynamic>> _searchHotels(Map<String, dynamic> args) async {
    final normalizedArgs = _applyDefaultScenario(args);
    normalizedArgs['searchKey'] = DateTime.now().millisecondsSinceEpoch
        .toString();

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
      screenName: AppRoutes.screenHotelList,
      params: normalizedArgs,
    );

    _updateAgentState(
      currentStep: BookingStep.selecting,
      currentScreen: AppRoutes.screenHotelList,
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
      screenName: AppRoutes.screenHotelDetail,
      params: {'hotel_id': hotelId},
    );

    _updateAgentState(currentScreen: AppRoutes.screenHotelDetail);

    return {
      'success': true,
      'hotel': _selectedHotel,
      'message': 'Hotel details retrieved for ${_selectedHotel['name']}',
      'assistant_prompt': _buildHotelDetailPrompt(),
    };
  }

  String _buildHotelDetailPrompt() {
    if (_selectedHotel.isEmpty) {
      return 'Detail hotel tersedia. Silakan pilih tipe kamar.';
    }

    final name = _selectedHotel['name']?.toString() ?? 'Hotel ini';
    final rating = _selectedHotel['rating']?.toString() ?? '-';
    final city =
        _selectedHotel['city']?.toString() ??
        _selectedHotel['location']?.toString() ??
        '';

    final roomTypes = _selectedHotel['roomTypes'] as List<dynamic>? ?? [];
    final roomNames = roomTypes
        .map((room) => (room as Map<String, dynamic>)['name']?.toString())
        .whereType<String>()
        .take(3)
        .toList();

    final roomsText = roomNames.isNotEmpty
        ? 'Pilihan kamar: ${roomNames.join(', ')}.'
        : 'Silakan pilih tipe kamar.';

    return '$name, rating $rating${city.isNotEmpty ? ' di $city' : ''}. '
        '$roomsText Sebutkan tipe kamar yang Anda inginkan.';
  }

  Future<Map<String, dynamic>> _selectRoom(Map<String, dynamic> args) async {
    final normalizedArgs = _normalizeBookingArgs(args);
    final roomId = normalizedArgs['room_id']?.toString();

    String? roomName;
    if (_selectedHotel.isNotEmpty) {
      final roomTypes = _selectedHotel['roomTypes'] as List<dynamic>? ?? [];
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
          (roomTypes.isNotEmpty ? roomTypes.first['name']?.toString() : null) ??
          'kamar pilihan';
    }

    _updateAgentState(
      currentStep: BookingStep.selecting,
      appState: normalizedArgs,
      currentScreen: 'hotel_detail',
    );

    return {
      'success': true,
      'selected_room_id': roomId,
      'message': 'Room selected',
      'assistant_prompt':
          'Kamar ${roomName ?? 'pilihan Anda'} sudah dipilih. Lanjutkan pemesanan? Jika ya, panggil create_booking.',
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
      screenName: AppRoutes.screenBookingSummary,
      params: navigationParams,
    );

    _updateAgentState(currentScreen: AppRoutes.screenBookingSummary);

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

    if (screenName == AppRoutes.screenBookingPayment ||
        screenName == AppRoutes.screenBookingGuestInfo ||
        screenName == AppRoutes.screenBookingConfirmation) {
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

    // Intentionally no-op: keep agent state updates quiet in production logs.
  }

  /// Get system instructions for the AI agent
  String getSystemInstructions() {
    return '''
  Kamu adalah asisten pemesanan hotel berbasis suara untuk Qora.
  Gunakan Bahasa Indonesia yang singkat, jelas, dan langsung.

  Konteks:
  - Tahap: ${_agentState.currentStep.name}
  - Layar: ${_agentState.currentScreen ?? 'tidak diketahui'}
  - Data: ${jsonEncode(_agentState.userConstraints)}

  Aturan ringkas:
  1) Jangan bertele-tele. Maksimal 1 pertanyaan per respons.
  2) Setelah detail hotel ditampilkan, jelaskan singkat lalu tawarkan tipe kamar.
  3) Saat user menyebut tipe kamar, panggil `select_room` untuk menandai pilihan.
  4) Setelah `select_room`, katakan kamar dipilih dan tanya lanjut booking.
  5) Jika user setuju, panggil `create_booking` (navigasi ke ringkasan).
  6) Di ringkasan, baca singkat dan arahkan ke pembayaran jika setuju.
  7) Jangan minta data tamu lagi. Fitur data tamu tidak dipakai.

  Contoh singkat:
  "Hotel A, rating 4.8. Pilih kamar: Deluxe, Suite. Kamar mana?"
  "Kamar Deluxe dipilih. Lanjutkan pemesanan?"

  Fungsi: search_hotels, get_hotel_details, select_room, create_booking, confirm_booking, navigate_to_screen, update_booking_step.
''';
  }
}
