import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../features/booking/domain/usecases/run_booking_alpha_loop.dart';
import '../di/booking_injection.dart';
import '../utils/app_logger.dart';

class BookingAlphaTestLauncher {
  BookingAlphaTestLauncher._();

  static bool _isRunning = false;

  static const bool _debugAutoRunEnabled = bool.fromEnvironment(
    'ENABLE_ALPHA_BOOKING_LOOP',
    defaultValue: false,
  );

  static const int _debugLoopCount = int.fromEnvironment(
    'ALPHA_BOOKING_LOOP_COUNT',
    defaultValue: BookingAlphaLoopConfig.recommendedLoopCount,
  );

  static Future<BookingAlphaLoopResult?> runAlphaLoop({
    int loopCount = BookingAlphaLoopConfig.recommendedLoopCount,
    String trigger = 'manual',
  }) async {
    if (_isRunning) {
      return null;
    }

    _isRunning = true;
    try {
      final runner = BookingInjection.createBookingAlphaLoopRunner();
      final result = await runner(
        config: BookingAlphaLoopConfig(loopCount: loopCount),
      );

      final rawExists = await File(result.rawLogPath).exists();
      final summaryExists = await File(result.summaryLogPath).exists();

      AppLogger.info(
        'BookingAlphaTest',
        'Loop selesai via $trigger. raw=${result.rawLogPath} (exists=$rawExists), summary=${result.summaryLogPath} (exists=$summaryExists)',
      );
      return result;
    } finally {
      _isRunning = false;
    }
  }

  static Future<void> runDefaultDebugLoopIfEnabled() async {
    if (!kDebugMode || !_debugAutoRunEnabled) {
      return;
    }

    await runAlphaLoop(loopCount: _debugLoopCount, trigger: 'debug_auto_run');
  }
}
