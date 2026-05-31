import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class FramePerformanceMonitor {
  FramePerformanceMonitor._();

  static final FramePerformanceMonitor instance = FramePerformanceMonitor._();

  static const String _logPrefix = '[FramePerf]';
  static const double _fallbackThresholdMs = 16.0;

  bool _isMonitoring = false;
  DateTime? _sessionStart;
  DateTime? _sessionEnd;

  int _totalFrames = 0;
  int _jankFrames = 0;
  int _accumulatedFrameTimeMicros = 0;

  double _jankThresholdMs = _fallbackThresholdMs;

  late final TimingsCallback _timingsCallback = _onFrameTimings;

  bool get isMonitoring => _isMonitoring;

  int get totalFrames => _totalFrames;

  int get jankFrames => _jankFrames;

  double get averageFrameTimeMs {
    if (_totalFrames == 0) {
      return 0;
    }
    return (_accumulatedFrameTimeMicros / _totalFrames) / 1000;
  }

  double get jankThresholdMs => _jankThresholdMs;

  void startMonitoring({
    double? jankThresholdMs,
    bool adaptToDisplayRefreshRate = true,
  }) {
    if (_isMonitoring) {
      debugPrint('$_logPrefix Monitoring already active.');
      return;
    }

    _resetCounters();
    _sessionStart = DateTime.now();
    _sessionEnd = null;
    _jankThresholdMs = _resolveThreshold(
      customThresholdMs: jankThresholdMs,
      adaptToDisplayRefreshRate: adaptToDisplayRefreshRate,
    );

    SchedulerBinding.instance.addTimingsCallback(_timingsCallback);
    _isMonitoring = true;

    debugPrint(
      '$_logPrefix Started monitoring. '
      'Jank threshold: ${_jankThresholdMs.toStringAsFixed(2)}ms',
    );
  }

  void stopMonitoring({bool logSummary = true}) {
    if (!_isMonitoring) {
      return;
    }

    SchedulerBinding.instance.removeTimingsCallback(_timingsCallback);
    _sessionEnd = DateTime.now();
    _isMonitoring = false;

    if (logSummary) {
      _printSummary(synchronousLogging: true);
    }
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!_isMonitoring || timings.isEmpty) {
      return;
    }

    for (final timing in timings) {
      final frameTimeMicros = timing.totalSpan.inMicroseconds;
      final frameTimeMs = frameTimeMicros / 1000;

      _totalFrames++;
      _accumulatedFrameTimeMicros += frameTimeMicros;

      if (frameTimeMs > _jankThresholdMs) {
        _jankFrames++;
      }
    }
  }

  double _resolveThreshold({
    required double? customThresholdMs,
    required bool adaptToDisplayRefreshRate,
  }) {
    if (customThresholdMs != null && customThresholdMs > 0) {
      return customThresholdMs;
    }

    if (!adaptToDisplayRefreshRate) {
      return _fallbackThresholdMs;
    }

    final views = PlatformDispatcher.instance.views;
    if (views.isEmpty) {
      return _fallbackThresholdMs;
    }

    final refreshRate = views.first.display.refreshRate;
    if (refreshRate <= 0) {
      return _fallbackThresholdMs;
    }

    return 1000 / refreshRate;
  }

  void _resetCounters() {
    _totalFrames = 0;
    _jankFrames = 0;
    _accumulatedFrameTimeMicros = 0;
  }

  void _printSummary({bool synchronousLogging = false}) {
    final startedAt = _sessionStart;
    final endedAt = _sessionEnd ?? DateTime.now();
    final duration = startedAt == null
        ? Duration.zero
        : endedAt.difference(startedAt);

    final lines = <String>[
      '==================================================',
      '[FRAME PERFORMANCE SUMMARY]',
      '==================================================',
      '[METADATA]',
      '  Task Completion Time : ${_formatDuration(duration)}',
      '',
      '[FRAME STATS]',
      '  Total Frames       : $_totalFrames',
      '  Jank Frames        : $_jankFrames',
      '  Avg Frame Time     : ${averageFrameTimeMs.toStringAsFixed(2)}ms',
      '',
      '==================================================',
    ];

    for (final line in lines) {
      final message = '$_logPrefix $line';
      if (synchronousLogging) {
        debugPrintSynchronously(message);
      } else {
        debugPrint(message);
      }
    }
  }

  String _formatDuration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    final milliseconds = value.inMilliseconds.remainder(1000);

    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');

    return '${twoDigits(hours)}:${twoDigits(minutes)}:'
        '${twoDigits(seconds)}.${threeDigits(milliseconds)}';
  }
}
