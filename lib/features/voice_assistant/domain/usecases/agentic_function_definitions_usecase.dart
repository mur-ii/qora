import '../../../../core/router/app_routes.dart';

/// Provides function schemas consumed by OpenAI realtime function calling.
class AgenticFunctionDefinitionsUseCase {
  List<Map<String, dynamic>> call() {
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
}
