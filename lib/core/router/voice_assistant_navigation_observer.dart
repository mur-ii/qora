import 'package:flutter/widgets.dart';

import '../../features/voice_assistant/di/voice_assistant_injection.dart';
import 'app_routes.dart';

class VoiceAssistantNavigationObserver extends NavigatorObserver {
  static const String _closingMessage =
      'Baik, saya sudah membantu sampai tahap pemesanan. '
      'Untuk proses pembayaran silakan pilih metode pembayaran di layar. '
      'Saya tidak dapat membantu proses pembayaran, jadi sesi voice assistant '
      'akan saya akhiri di sini.';

  void _handleRoute(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == AppRoutes.bookingPaymentName ||
        name == AppRoutes.bookingGuestInfoName) {
      try {
        final controller =
            VoiceAssistantInjection.getVoiceAssistantController();
        controller.endSessionWithMessage(_closingMessage);
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
