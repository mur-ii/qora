import 'package:flutter/widgets.dart';

import '../di/voice_assistant_injection.dart';
import 'app_routes.dart';

class VoiceAssistantNavigationObserver extends NavigatorObserver {
  static const String _closingMessage =
      'Anda sudah berada di halaman Pembayaran. '
      'Silakan klik salah satu metode pembayaran yang tersedia, lalu klik tombol Bayar untuk melanjutkan. '
      'Saya hanya bisa membantu sampai halaman pembayaran ini karena tidak diizinkan mengakses payment gateway. '
      'Sesi voice assistant akan saya akhiri sekarang.';

  bool _isPaymentRoute(Route<dynamic>? route) {
    final routeName = route?.settings.name ?? '';
    return routeName == AppRoutes.bookingPaymentName ||
        routeName == AppRoutes.bookingGuestInfoName ||
        routeName == AppRoutes.bookingPaymentPath ||
        routeName == AppRoutes.bookingGuestInfoPath ||
        routeName.contains(AppRoutes.bookingPaymentPath) ||
        routeName.contains(AppRoutes.bookingGuestInfoPath);
  }

  void _handleRoute(Route<dynamic>? route) {
    if (_isPaymentRoute(route)) {
      try {
        final controller =
            VoiceAssistantInjection.getVoiceAssistantController();
        if (controller.isConnected) {
          controller.endSessionWithMessage(_closingMessage);
        }
      } on StateError {
        // Controller not initialized; ignore.
      }
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _handleRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _handleRoute(newRoute);
  }
}
