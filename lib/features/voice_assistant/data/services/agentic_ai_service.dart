import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/services/navigation_service.dart';
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
    _updateAgentState(
      currentStep: BookingStep.searching,
      userConstraints: args,
    );

    // Load mock hotel list data
    final jsonString = await rootBundle.loadString(
      'lib/features/hotel_list/data/mock/hotel_list_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    _hotelSearchResults = {
      'hotels': jsonData['hotels'],
      'total': (jsonData['hotels'] as List).length,
      'location': args['location'],
      'check_in': args['check_in'],
      'check_out': args['check_out'],
    };

    // Navigate to hotel list
    await navigationService.navigateTo(screenName: 'hotel_list', params: args);

    return {
      'success': true,
      'message':
          'Found ${_hotelSearchResults['total']} hotels in ${args['location']}',
      'hotels': _hotelSearchResults['hotels'],
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
    _updateAgentState(
      currentStep: BookingStep.confirmingBooking,
      appState: args,
    );

    // Load mock booking summary data
    final jsonString = await rootBundle.loadString(
      'lib/features/booking/mock/booking_summary_response.json',
    );
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    _bookingData = {
      'booking_id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
      'status': 'pending',
      'hotel': jsonData['data']['hotel'],
      'room': jsonData['data']['room'],
      'booking_details': jsonData['data']['bookingDetails'],
      'pricing': jsonData['data']['pricing'],
      ...args,
    };

    // Navigate to booking summary
    await navigationService.navigateTo(
      screenName: 'booking_summary',
      params: args,
    );

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
Your booking has been confirmed successfully! 🎉

Confirmation Number: ${confirmationData['confirmationNumber']}
Hotel: ${confirmationData['hotel']['name']}
Check-in: ${confirmationData['bookingDetails']['checkIn']}
Check-out: ${confirmationData['bookingDetails']['checkOut']}

⚠️ IMPORTANT - PAYMENT REQUIRED
To complete your reservation, please proceed with manual payment. 
I cannot process payments directly, but you can:
1. Visit the Payment page in the app
2. Choose your preferred payment method
3. Complete the transaction

Total Amount Due: IDR ${confirmationData['pricing']['grandTotal']}

Thank you for using our voice assistant! Is there anything else I can help you with?
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
      'payment_amount': confirmationData['pricing']['grandTotal'],
      'payment_currency': confirmationData['pricing']['currency'],
    };
  }

  Future<Map<String, dynamic>> _navigateToScreen(
    Map<String, dynamic> args,
  ) async {
    final screenName = args['screen_name'] as String;
    final params = args['params'] as Map<String, dynamic>?;

    await navigationService.navigateTo(screenName: screenName, params: params);

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
You are a professional hotel booking assistant for Qora Hotel Booking App with access to real hotel data and booking capabilities.

**Current Context:**
- Booking Step: ${_agentState.currentStep.name}
- Current Screen: ${_agentState.currentScreen ?? 'unknown'}
- User Constraints: ${jsonEncode(_agentState.userConstraints)}

**Your Responsibilities:**
1. Help users find and book hotels through natural conversation
2. Ask clarifying questions when information is missing (location, dates, number of guests)
3. Use available functions to search hotels, check details, verify availability, and create bookings
4. Navigate the app programmatically to show relevant information to users
5. Confirm all booking details before finalizing
6. Guide users through the booking flow from search to confirmation
7. After booking confirmation, ALWAYS inform users to proceed with manual payment

**Booking Flow:**
1. Search Hotels - Ask for location, check-in/check-out dates, number of guests
2. View Hotel Details - Show amenities, rooms, reviews
3. Check Availability - Verify room availability for selected dates
4. Get Pricing - Display price breakdown with taxes and fees
5. Create Booking - Initiate reservation with all details
6. Confirm Booking - Finalize the reservation
7. Payment Notice - Inform user to complete payment manually (YOU CANNOT PROCESS PAYMENTS)

**Important Guidelines:**
- Always confirm booking details before creating a reservation
- Provide clear pricing information including taxes and fees
- Navigate to relevant screens when showing information
- Track the booking flow step by step
- Be conversational, friendly, and helpful
- Use Indonesian Rupiah (IDR) for all prices
- After confirming a booking, ALWAYS tell the user: "Your booking is confirmed! However, I cannot process payments. Please go to the Payment page to complete your reservation with your preferred payment method."

**Available Functions:**
- search_hotels: Find hotels by location and dates (returns real hotel data)
- get_hotel_details: View detailed hotel information with rooms and amenities
- check_availability: Verify room availability for specific dates
- get_pricing: Get detailed price breakdowns (includes taxes, fees, discounts)
- create_booking: Initiate a booking (creates booking summary)
- confirm_booking: Finalize the reservation (generates confirmation number)
- navigate_to_screen: Control app navigation to show relevant screens
- update_booking_step: Track booking progress internally

**Payment Limitation:**
YOU CANNOT AND MUST NOT attempt to process any payments. After confirming a booking, you MUST inform the user to complete payment manually through the app's payment feature.
''';
  }
}
