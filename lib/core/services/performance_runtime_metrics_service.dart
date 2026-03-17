import 'package:flutter/services.dart';

class SystemMetricsSnapshot {
  const SystemMetricsSnapshot({this.cpuPercent, this.memoryMb});

  final double? cpuPercent;
  final double? memoryMb;
}

class NetworkMetricsSnapshot {
  const NetworkMetricsSnapshot({
    required this.totalTxBytes,
    required this.totalRxBytes,
    required this.httpTxBytes,
    required this.httpRxBytes,
    required this.webRtcTxBytes,
    required this.webRtcRxBytes,
  });

  final int totalTxBytes;
  final int totalRxBytes;
  final int httpTxBytes;
  final int httpRxBytes;
  final int webRtcTxBytes;
  final int webRtcRxBytes;
}

class PerformanceRuntimeMetricsService {
  PerformanceRuntimeMetricsService._internal();

  static final PerformanceRuntimeMetricsService instance =
      PerformanceRuntimeMetricsService._internal();

  static const MethodChannel _channel = MethodChannel(
    'qora/performance_metrics',
  );

  int _httpTxBytes = 0;
  int _httpRxBytes = 0;
  int _webRtcTxBytes = 0;
  int _webRtcRxBytes = 0;

  Future<SystemMetricsSnapshot> getSystemMetrics() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getSystemMetrics',
      );

      if (result == null) {
        return const SystemMetricsSnapshot();
      }

      return SystemMetricsSnapshot(
        cpuPercent: _parseDouble(result['cpuPercent']),
        memoryMb: _parseDouble(result['memoryMb']),
      );
    } catch (_) {
      return const SystemMetricsSnapshot();
    }
  }

  void addHttpTraffic({required int txBytes, required int rxBytes}) {
    _httpTxBytes += txBytes < 0 ? 0 : txBytes;
    _httpRxBytes += rxBytes < 0 ? 0 : rxBytes;
  }

  void addWebRtcTraffic({required int txBytes, required int rxBytes}) {
    _webRtcTxBytes += txBytes < 0 ? 0 : txBytes;
    _webRtcRxBytes += rxBytes < 0 ? 0 : rxBytes;
  }

  NetworkMetricsSnapshot getNetworkSnapshot() {
    return NetworkMetricsSnapshot(
      totalTxBytes: _httpTxBytes + _webRtcTxBytes,
      totalRxBytes: _httpRxBytes + _webRtcRxBytes,
      httpTxBytes: _httpTxBytes,
      httpRxBytes: _httpRxBytes,
      webRtcTxBytes: _webRtcTxBytes,
      webRtcRxBytes: _webRtcRxBytes,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
