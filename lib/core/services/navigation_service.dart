import 'package:go_router/go_router.dart';

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
      print('Router not initialized');
      return;
    }

    try {
      switch (screenName) {
        case 'home':
          _router!.go('/');
          break;

        case 'hotel_list':
          final queryParams = _buildQueryParams(params);
          _router!.go('/hotel-list?$queryParams');
          break;

        case 'hotel_detail':
          final hotelId = params?['hotel_id'] as String?;
          if (hotelId != null) {
            _router!.go('/hotel-detail/$hotelId');
          }
          break;

        case 'booking_summary':
          final queryParams = _buildQueryParams(params);
          _router!.go('/booking/summary?$queryParams');
          break;

        case 'search':
          _router!.go('/search');
          break;

        case 'notifications':
          _router!.go('/notifications');
          break;

        default:
          print('Unknown screen: $screenName');
      }

      print('Navigated to: $screenName');
    } catch (e) {
      print('Navigation error: $e');
      rethrow;
    }
  }

  /// Build query parameters string
  String _buildQueryParams(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';

    return params.entries
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
