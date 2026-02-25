import 'dart:io';

import 'package:flutter/scheduler.dart';

import 'alpha_test_logger.dart';

class PerformanceSample {
  final String pageName;
  final DateTime startTime;
  final DateTime endTime;
  final int frameCount;
  final double avgFrameTimeMs;
  final double avgBuildTimeMs;
  final double avgRasterTimeMs;
  final int jankCount;
  final double fps;
  final double? memoryMb;
  final int loadTimeMs;

  const PerformanceSample({
    required this.pageName,
    required this.startTime,
    required this.endTime,
    required this.frameCount,
    required this.avgFrameTimeMs,
    required this.avgBuildTimeMs,
    required this.avgRasterTimeMs,
    required this.jankCount,
    required this.fps,
    required this.memoryMb,
    required this.loadTimeMs,
  });

  Map<String, dynamic> toJson() {
    return {
      'page_name': pageName,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'frame_count': frameCount,
      'avg_frame_time_ms': avgFrameTimeMs,
      'avg_build_time_ms': avgBuildTimeMs,
      'avg_raster_time_ms': avgRasterTimeMs,
      'jank_count': jankCount,
      'fps': fps,
      'memory_mb': memoryMb,
      'load_time_ms': loadTimeMs,
      'ui_response_time_ms': loadTimeMs,
    };
  }
}

class PerformanceSampler {
  PerformanceSampler({required this.pageName});

  final String pageName;

  final List<FrameTiming> _frames = [];
  final Stopwatch _stopwatch = Stopwatch();
  final Stopwatch _loadStopwatch = Stopwatch();

  DateTime? _startTime;
  DateTime? _endTime;
  int? _loadTimeMs;
  bool _firstFrameRecorded = false;

  void start() {
    _startTime = DateTime.now();
    _stopwatch.start();
    _loadStopwatch.start();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_firstFrameRecorded) return;
      _firstFrameRecorded = true;
      _loadTimeMs = _loadStopwatch.elapsedMilliseconds;
    });
  }

  void stop() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    _endTime = DateTime.now();
    _stopwatch.stop();

    final sample = _buildSample();
    AlphaTestLogger.instance.logPerformanceSample(sample.toJson());
  }

  void _onTimings(List<FrameTiming> timings) {
    _frames.addAll(timings);
  }

  PerformanceSample _buildSample() {
    final startTime = _startTime ?? DateTime.now();
    final endTime = _endTime ?? DateTime.now();
    final frameCount = _frames.length;

    var totalFrameMs = 0.0;
    var totalBuildMs = 0.0;
    var totalRasterMs = 0.0;
    var jankCount = 0;

    for (final frame in _frames) {
      final frameMs = frame.totalSpan.inMicroseconds / 1000.0;
      final buildMs = frame.buildDuration.inMicroseconds / 1000.0;
      final rasterMs = frame.rasterDuration.inMicroseconds / 1000.0;

      totalFrameMs += frameMs;
      totalBuildMs += buildMs;
      totalRasterMs += rasterMs;

      if (frameMs > 16.7) {
        jankCount += 1;
      }
    }

    final elapsedSeconds = _stopwatch.elapsedMilliseconds / 1000.0;
    final fps = elapsedSeconds > 0 ? frameCount / elapsedSeconds : 0.0;
    final avgFrameTimeMs = frameCount > 0 ? totalFrameMs / frameCount : 0.0;
    final avgBuildTimeMs = frameCount > 0 ? totalBuildMs / frameCount : 0.0;
    final avgRasterTimeMs = frameCount > 0 ? totalRasterMs / frameCount : 0.0;

    double? memoryMb;
    try {
      memoryMb = ProcessInfo.currentRss / (1024 * 1024);
    } catch (_) {
      memoryMb = null;
    }

    return PerformanceSample(
      pageName: pageName,
      startTime: startTime,
      endTime: endTime,
      frameCount: frameCount,
      avgFrameTimeMs: avgFrameTimeMs,
      avgBuildTimeMs: avgBuildTimeMs,
      avgRasterTimeMs: avgRasterTimeMs,
      jankCount: jankCount,
      fps: fps,
      memoryMb: memoryMb,
      loadTimeMs: _loadTimeMs ?? 0,
    );
  }
}
