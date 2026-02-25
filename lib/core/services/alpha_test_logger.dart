import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/performance/data/models/performance_summary.dart';

class AlphaTestLogger {
  AlphaTestLogger._();

  static final AlphaTestLogger instance = AlphaTestLogger._();

  static const double _inputRatePerMillion = 0.60;
  static const double _outputRatePerMillion = 2.40;

  final List<Map<String, dynamic>> _events = [];
  Directory? _directory;
  Map<String, dynamic>? _session;
  bool _initialized = false;
  int _totalInputTokens = 0;
  int _totalOutputTokens = 0;
  int _turnCount = 0;

  Future<void> initialize() async {
    if (_initialized) return;
    _directory = await getApplicationDocumentsDirectory();
    _initialized = true;
  }

  Future<void> startSession({
    required InteractionMethod method,
    String? scenarioId,
    String? searchedLocation,
    String? testerSessionId,
  }) async {
    await initialize();

    final now = DateTime.now();
    final sessionId = now.microsecondsSinceEpoch.toString();
    _events.clear();
    _totalInputTokens = 0;
    _totalOutputTokens = 0;
    _turnCount = 0;

    _session = {
      'session_id': sessionId,
      'scenario_id': scenarioId ?? 'unknown',
      'method': method.name.toUpperCase(),
      'searched_location': searchedLocation ?? '',
      'tester_session_id': testerSessionId ?? '',
      'start_time': now.toIso8601String(),
      'device_info': _buildDeviceInfo(),
    };

    _logEvent('session_start', {'method': method.name});
  }

  void setScenario(String scenarioId) {
    if (_session == null) return;
    _session!['scenario_id'] = scenarioId;
  }

  void updateSearchedLocation(String location) {
    if (_session == null) return;
    _session!['searched_location'] = location;
  }

  void logPerformanceSample(Map<String, dynamic> sample) {
    _logEvent('performance_sample', sample);
  }

  void logNetworkLatency({required String endpoint, required int durationMs}) {
    _logEvent('network_latency', {
      'endpoint': endpoint,
      'duration_ms': durationMs,
    });
  }

  void logInteraction(String type) {
    _logEvent('interaction', {'type': type});
  }

  void logConversationTurn({
    required bool isUser,
    required String text,
    String? intent,
  }) {
    _turnCount += isUser ? 1 : 0;
    _logEvent('conversation_turn', {
      'turn': _turnCount,
      'speaker': isUser ? 'user' : 'assistant',
      'text': text,
      if (intent != null) 'intent': intent,
    });
  }

  void logIntent({required String intent, String? source}) {
    _logEvent('intent', {
      'intent': intent,
      if (source != null) 'source': source,
    });
  }

  void logFunctionCall({
    required String name,
    required Map<String, dynamic> arguments,
    required int durationMs,
    bool success = true,
    String? error,
  }) {
    _logEvent('function_call', {
      'name': name,
      'arguments': arguments,
      'duration_ms': durationMs,
      'success': success,
      if (error != null) 'error': error,
    });
  }

  void logRealtimeMetric(String name, int durationMs) {
    _logEvent('realtime_metric', {'name': name, 'duration_ms': durationMs});
  }

  void logStepStart(String stepName) {
    _logEvent('step_start', {'step': stepName});
  }

  void logStepEnd(String stepName, int durationSeconds) {
    _logEvent('step_end', {
      'step': stepName,
      'duration_seconds': durationSeconds,
    });
  }

  void logError({required String type, String? message}) {
    _logEvent('error', {'type': type, if (message != null) 'message': message});
  }

  void recordTokenUsage({
    required int inputTokens,
    required int outputTokens,
    String? responseId,
  }) {
    _totalInputTokens += inputTokens;
    _totalOutputTokens += outputTokens;

    _logEvent('token_usage', {
      'response_id': responseId,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'total_tokens': inputTokens + outputTokens,
      'estimated_cost_usd': _estimateCost(inputTokens, outputTokens),
    });
  }

  double _estimateCost(int inputTokens, int outputTokens) {
    final inputCost = (inputTokens / 1000000) * _inputRatePerMillion;
    final outputCost = (outputTokens / 1000000) * _outputRatePerMillion;
    return inputCost + outputCost;
  }

  Future<String?> endSession({PerformanceSummary? summary}) async {
    if (_session == null) return null;

    final now = DateTime.now();
    _session!['end_time'] = now.toIso8601String();

    final payload = {
      'session': _session,
      if (summary != null) 'performance_summary': _summaryToJson(summary),
      'token_totals': {
        'input_tokens': _totalInputTokens,
        'output_tokens': _totalOutputTokens,
        'total_tokens': _totalInputTokens + _totalOutputTokens,
        'estimated_cost_usd': _estimateCost(
          _totalInputTokens,
          _totalOutputTokens,
        ),
      },
      'events': _events,
    };

    final sessionId = _session!['session_id'] as String;
    final directory = _directory ?? await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}${Platform.pathSeparator}alpha_test_log_$sessionId.json';
    final file = File(filePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload),
    );

    _logEvent('session_end', {'file_path': filePath});
    _session = null;
    _events.clear();

    return filePath;
  }

  void _logEvent(String type, Map<String, dynamic> data) {
    if (_session == null) return;
    _events.add({
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      ...data,
    });
  }

  Map<String, dynamic> _summaryToJson(PerformanceSummary summary) {
    return {
      'session_id': summary.sessionId,
      'tester_session_id': summary.testerSessionId,
      'start_time': summary.startTime.toIso8601String(),
      'end_time': summary.endTime.toIso8601String(),
      'duration_seconds': summary.durationInSeconds,
      'interaction_method': summary.interactionMethod.name.toUpperCase(),
      'total_clicks': summary.totalClicks,
      'total_voice_commands': summary.totalVoiceCommands,
      'errors_count': summary.errorsCount,
      'error_types': summary.errorTypes,
      'task_completed': summary.taskCompleted,
      'searched_location': summary.searchedLocation,
      'selected_hotel_name': summary.selectedHotelName,
      'booking_success': summary.bookingSuccess,
      'search_duration_seconds': summary.searchDurationSeconds,
      'selection_duration_seconds': summary.selectionDurationSeconds,
      'payment_duration_seconds': summary.paymentDurationSeconds,
      'confirmation_duration_seconds': summary.confirmationDurationSeconds,
      'user_input_time_seconds': summary.userInputTimeSeconds,
      'correction_count': summary.correctionCount,
      'interaction_effort': summary.interactionEffortCount,
      'created_at': summary.createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> _buildDeviceInfo() {
    final localeName = Platform.localeName;
    return {
      'os': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'dart_version': Platform.version,
      'locale': localeName,
      'is_release': kReleaseMode,
    };
  }
}
