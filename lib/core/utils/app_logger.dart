import 'package:flutter/foundation.dart';

/// Lightweight app logger with release-safe behavior.
class AppLogger {
  static void info(String tag, String message) {
    if (kReleaseMode) return;
    debugPrint('[INFO][$tag] $message');
  }

  static void warn(String tag, String message) {
    if (kReleaseMode) return;
    debugPrint('[WARN][$tag] $message');
  }

  static void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kReleaseMode) return;
    debugPrint('[ERROR][$tag] $message');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
