import 'dart:async';

import 'package:flutter/foundation.dart';

/// Debouncer utility to prevent rapid-fire function calls
/// Useful for search inputs, API calls, and expensive operations
class Debouncer {
  Debouncer({required this.duration});

  final Duration duration;
  Timer? _timer;

  /// Execute callback after debounce duration
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  /// Cancel pending debounced action
  void cancel() {
    _timer?.cancel();
  }

  /// Dispose of the debouncer
  void dispose() {
    _timer?.cancel();
  }
}

/// Throttler utility to limit function execution rate
/// Executes immediately, then blocks subsequent calls until duration passes
class Throttler {
  Throttler({required this.duration});

  final Duration duration;
  Timer? _timer;
  bool _isThrottled = false;

  /// Execute callback if not throttled
  void run(VoidCallback action) {
    if (!_isThrottled) {
      action();
      _isThrottled = true;
      _timer = Timer(duration, () {
        _isThrottled = false;
      });
    }
  }

  /// Cancel throttle timer
  void cancel() {
    _timer?.cancel();
    _isThrottled = false;
  }

  /// Dispose of the throttler
  void dispose() {
    _timer?.cancel();
  }
}

/// Extension on VoidCallback for easy debouncing
extension DebouncedCallback on VoidCallback {
  VoidCallback debounce(Duration duration) {
    final debouncer = Debouncer(duration: duration);
    return () => debouncer.run(this);
  }

  VoidCallback throttle(Duration duration) {
    final throttler = Throttler(duration: duration);
    return () => throttler.run(this);
  }
}
