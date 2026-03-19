class BookingNetworkRequestMetric {
  const BookingNetworkRequestMetric({
    required this.sessionId,
    required this.requestName,
    required this.startedAt,
    required this.endedAt,
    required this.durationMs,
    required this.txBytes,
    required this.rxBytes,
    required this.success,
    this.error,
  });

  final String sessionId;
  final String requestName;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationMs;
  final int txBytes;
  final int rxBytes;
  final bool success;
  final String? error;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'session_id': sessionId,
      'request_name': requestName,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'duration_ms': durationMs,
      'tx_bytes': txBytes,
      'rx_bytes': rxBytes,
      'success': success,
      'error': error,
    };
  }
}

class BookingNetworkMetricsTracker {
  BookingNetworkMetricsTracker._internal();

  static final BookingNetworkMetricsTracker instance =
      BookingNetworkMetricsTracker._internal();

  final Map<String, List<BookingNetworkRequestMetric>> _sessionMetrics =
      <String, List<BookingNetworkRequestMetric>>{};

  String? _activeSessionId;

  void startSession(String sessionId) {
    final normalized = sessionId.trim();
    if (normalized.isEmpty) {
      return;
    }

    _activeSessionId = normalized;
    _sessionMetrics[normalized] = <BookingNetworkRequestMetric>[];
  }

  void endSession(String sessionId) {
    final normalized = sessionId.trim();
    if (_activeSessionId == normalized) {
      _activeSessionId = null;
    }
  }

  void recordRequest({
    required String requestName,
    required DateTime startedAt,
    required Duration duration,
    required int txBytes,
    required int rxBytes,
    required bool success,
    String? error,
    String? sessionId,
  }) {
    final resolvedSessionId = (sessionId ?? _activeSessionId)?.trim();
    if (resolvedSessionId == null || resolvedSessionId.isEmpty) {
      return;
    }

    final normalizedRequestName = requestName.trim();
    final metric = BookingNetworkRequestMetric(
      sessionId: resolvedSessionId,
      requestName: normalizedRequestName.isEmpty
          ? 'unknown_request'
          : normalizedRequestName,
      startedAt: startedAt,
      endedAt: startedAt.add(duration),
      durationMs: duration.inMilliseconds,
      txBytes: txBytes < 0 ? 0 : txBytes,
      rxBytes: rxBytes < 0 ? 0 : rxBytes,
      success: success,
      error: error,
    );

    final bucket = _sessionMetrics.putIfAbsent(
      resolvedSessionId,
      () => <BookingNetworkRequestMetric>[],
    );
    bucket.add(metric);
  }

  List<BookingNetworkRequestMetric> getSessionMetrics(String sessionId) {
    final normalized = sessionId.trim();
    if (normalized.isEmpty) {
      return const <BookingNetworkRequestMetric>[];
    }

    final entries = _sessionMetrics[normalized];
    if (entries == null || entries.isEmpty) {
      return const <BookingNetworkRequestMetric>[];
    }

    return List<BookingNetworkRequestMetric>.unmodifiable(entries);
  }

  List<Map<String, dynamic>> consumeSessionMetricsAsJson(String sessionId) {
    final normalized = sessionId.trim();
    if (normalized.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final entries = _sessionMetrics.remove(normalized);
    if (entries == null || entries.isEmpty) {
      if (_activeSessionId == normalized) {
        _activeSessionId = null;
      }
      return const <Map<String, dynamic>>[];
    }

    if (_activeSessionId == normalized) {
      _activeSessionId = null;
    }

    return entries
        .map((BookingNetworkRequestMetric metric) => metric.toJson())
        .toList(growable: false);
  }
}
