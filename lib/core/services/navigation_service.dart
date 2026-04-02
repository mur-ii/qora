import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import '../utils/app_logger.dart';

/// Service to handle programmatic navigation from AI function calls
class NavigationService {
  GoRouter? _router;

  void setRouter(GoRouter router) {
    _router = router;
  }

  /// Navigate to a specific screen
  Future<void> navigateTo({
    required String screenName,
    Map<String, dynamic>? params,
  }) async {
    if (_router == null) {
      AppLogger.error('Navigation', 'Router not initialized');
      return;
    }

    try {
      switch (screenName) {
        case AppRoutes.screenHome:
          _router!.go(AppRoutes.homePath);
          break;

        case AppRoutes.screenHotelList:
          final queryParams = _buildQueryParams(params);
          _router!.go(AppRoutes.hotelListPathWithQuery(queryParams));
          break;

        case AppRoutes.screenHotelDetail:
          final hotelId = params?['hotel_id'] as String?;
          if (hotelId != null) {
            _router!.push(AppRoutes.hotelDetailPathFor(hotelId));
          }
          break;

        case AppRoutes.screenBookingSummary:
          final queryParams = _buildQueryParams(params);
          final booking = params?['booking'];
          if (booking != null) {
            _router!.go(
              AppRoutes.bookingSummaryPathWithQuery(queryParams),
              extra: booking,
            );
          } else {
            _router!.go(AppRoutes.bookingSummaryPathWithQuery(queryParams));
          }
          break;

        case AppRoutes.screenBookingGuestInfo:
          final booking = params?['booking'];
          if (booking != null) {
            _router!.go(AppRoutes.bookingGuestInfoPath, extra: booking);
          }
          break;

        case AppRoutes.screenBookingPayment:
          final booking = params?['booking'];
          if (booking != null) {
            _router!.go(AppRoutes.bookingPaymentPath, extra: booking);
          }
          break;

        case AppRoutes.screenBookingConfirmation:
          final booking = params?['booking'];
          if (booking != null) {
            _router!.go(AppRoutes.bookingConfirmationPath, extra: booking);
          }
          break;

        default:
          AppLogger.warn('Navigation', 'Unknown screen: $screenName');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Navigation',
        'Navigation error',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Build query parameters string
  String _buildQueryParams(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';

    final normalizedParams = <String, dynamic>{};
    for (final entry in params.entries) {
      if (entry.key == 'booking') {
        continue;
      }
      switch (entry.key) {
        case 'check_in':
          normalizedParams['checkIn'] = entry.value;
          break;
        case 'check_out':
          normalizedParams['checkOut'] = entry.value;
          break;
        case 'hotel_id':
          normalizedParams['hotelId'] = entry.value;
          break;
        case 'room_id':
          normalizedParams['roomId'] = entry.value;
          break;
        default:
          normalizedParams[entry.key] = entry.value;
      }
    }

    return normalizedParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
  }

  /// Go back
  void goBack() {
    _router?.pop();
  }

  /// Get current location
  String? getCurrentLocation() {
    return _router?.routeInformationProvider.value.uri.path;
  }
}
