import 'dart:async';

import '../../../../core/utils/app_logger.dart';
import '../entities/conversation_log.dart';
import '../repositories/conversation_repository.dart';
import 'calculate_session_cost.dart';
import 'log_conversation.dart';
import 'token_estimator.dart';

class VoiceTokenUsage {
  final int inputTokens;
  final int cachedTokens;
  final int outputTokens;
  final int totalTokens;

  const VoiceTokenUsage({
    required this.inputTokens,
    required this.cachedTokens,
    required this.outputTokens,
    required this.totalTokens,
  });

  const VoiceTokenUsage.empty()
    : inputTokens = 0,
      cachedTokens = 0,
      outputTokens = 0,
      totalTokens = 0;
}

class VoiceConversationLogger {
  VoiceConversationLogger({
    required LogConversation logConversationUseCase,
    required CalculateSessionCost calculateSessionCostUseCase,
    required ConversationRepository conversationRepository,
    TokenEstimator? tokenEstimator,
    String? modelName,
    String? sessionId,
  }) : _logConversationUseCase = logConversationUseCase,
       _calculateSessionCostUseCase = calculateSessionCostUseCase,
       _conversationRepository = conversationRepository,
       _tokenEstimator = tokenEstimator ?? TokenEstimator(),
       _modelName = _normalizeModel(modelName ?? 'unknown'),
       _sessionId = _normalizeSessionId(sessionId ?? _buildDefaultSessionId());

  static const double _inputCostPerM = 0.60;
  static const double _cachedCostPerM = 0.06;
  static const double _outputCostPerM = 2.40;
  static const int _oneMillion = 1000000;

  final LogConversation _logConversationUseCase;
  final CalculateSessionCost _calculateSessionCostUseCase;
  final ConversationRepository _conversationRepository;
  final TokenEstimator _tokenEstimator;

  String _modelName;
  String _sessionId;

  String? _pendingUserTranscript;
  DateTime? _pendingUserTimestamp;
  StringBuffer? _assistantBuffer;
  String? _pendingAssistantTranscript;
  VoiceTokenUsage? _pendingUsage;
  bool _responseDoneSeen = false;
  bool _isFinalizing = false;

  String get modelName => _modelName;
  String get sessionId => _sessionId;

  void setSessionId(String value) {
    _sessionId = _normalizeSessionId(value);
  }

  Future<double> calculateSessionCost(String sessionId) {
    return _calculateSessionCostUseCase(sessionId);
  }

  Future<List<ConversationLog>> getConversationLogsBySession(String sessionId) {
    return _conversationRepository.getConversationLogsBySession(sessionId);
  }

  Future<void> clearSessionLogs(String sessionId) {
    return _conversationRepository.clearSessionLogs(sessionId);
  }

  void setModelName(String? value) {
    if (value == null) return;
    final normalized = _normalizeModel(value);
    _modelName = normalized;
  }

  void logLifecycle(String message) {
    scheduleMicrotask(() {
      AppLogger.info('VoiceLifecycle', message);
    });
  }

  void logError(String message, {Object? error}) {
    scheduleMicrotask(() {
      AppLogger.error('VoiceLifecycle', message, error: error);
    });
  }

  Future<void> logSessionSummary() async {
    final totalCost = await calculateSessionCost(_sessionId);
    final summary = StringBuffer()
      ..writeln('[Session Summary]')
      ..writeln('Session: $_sessionId')
      ..writeln('Model: $_modelName')
      ..writeln('Total Cost (USD): ${totalCost.toStringAsFixed(6)}');
    AppLogger.info('VoiceSession', summary.toString());
  }

  void logRealtimeEvent(Map<String, dynamic> event) {
    scheduleMicrotask(() {
      final type = event['type']?.toString() ?? 'unknown';

      _updateModelFromEvent(event);

      switch (type) {
        case 'conversation.item.input_audio_transcription.completed':
          final transcript = event['transcript']?.toString();
          if (transcript != null && transcript.isNotEmpty) {
            _pendingUserTranscript = transcript;
            _pendingUserTimestamp = DateTime.now().toUtc();
            _assistantBuffer = null;
            _pendingAssistantTranscript = null;
            _pendingUsage = null;
            _responseDoneSeen = false;
          }
          break;

        case 'response.audio_transcript.delta':
          final delta =
              event['delta']?.toString() ?? event['transcript']?.toString();
          if (delta != null && delta.isNotEmpty) {
            _assistantBuffer ??= StringBuffer();
            _assistantBuffer!.write(delta);
          }
          break;

        case 'response.audio_transcript.done':
          final transcript = event['transcript']?.toString();
          final bufferText = _assistantBuffer?.toString();
          final resolvedTranscript =
              (transcript != null && transcript.isNotEmpty)
              ? transcript
              : (bufferText ?? '');
          if (resolvedTranscript.isNotEmpty) {
            _pendingAssistantTranscript = resolvedTranscript;
          }
          logLifecycle('Assistant response received');
          unawaited(_tryFinalizeTurn());
          break;

        case 'response.done':
          _pendingUsage = _parseUsage(event);
          _responseDoneSeen = true;
          unawaited(_tryFinalizeTurn());
          break;

        default:
          break;
      }
    });
  }

  Future<void> _tryFinalizeTurn() async {
    if (_isFinalizing) return;
    if (_pendingUserTranscript == null || _pendingAssistantTranscript == null) {
      return;
    }

    if (!_responseDoneSeen && _pendingUsage == null) {
      return;
    }

    _isFinalizing = true;

    final userMessage = _pendingUserTranscript!;
    final assistantMessage = _pendingAssistantTranscript!;
    final usage = _pendingUsage;

    final estimatedInput = _tokenEstimator.estimateTokens(userMessage);
    final estimatedOutput = _tokenEstimator.estimateTokens(assistantMessage);

    final inputTokens = usage?.inputTokens ?? estimatedInput;
    final outputTokens = usage?.outputTokens ?? estimatedOutput;
    final cachedTokens = usage?.cachedTokens ?? 0;
    final fallbackTotal = inputTokens + outputTokens + cachedTokens;
    final totalTokens = (usage == null || usage.totalTokens <= 0)
        ? fallbackTotal
        : usage.totalTokens;

    try {
      await logConversation(
        sessionId: _sessionId,
        userMessage: userMessage,
        assistantMessage: assistantMessage,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        cachedTokens: cachedTokens,
        timestamp: _pendingUserTimestamp,
        totalTokensOverride: totalTokens,
      );
    } finally {
      _resetPending();
      _isFinalizing = false;
    }
  }

  void _resetPending() {
    _pendingUserTranscript = null;
    _pendingUserTimestamp = null;
    _assistantBuffer = null;
    _pendingAssistantTranscript = null;
    _pendingUsage = null;
    _responseDoneSeen = false;
    _isFinalizing = false;
  }

  void _updateModelFromEvent(Map<String, dynamic> event) {
    final session = event['session'];
    if (session is Map) {
      setModelName(session['model']?.toString());
      return;
    }

    setModelName(event['model']?.toString());
  }

  VoiceTokenUsage? _parseUsage(Map<String, dynamic> event) {
    final response = event['response'];
    final usage = (event['usage'] is Map)
        ? event['usage']
        : (response is Map ? response['usage'] : null);

    if (usage is Map) {
      final inputTokens = _parseInt(usage['input_tokens']);
      final outputTokens = _parseInt(usage['output_tokens']);
      final totalTokens = _parseInt(usage['total_tokens']);
      final cachedTokens = _parseCachedTokens(usage);

      return VoiceTokenUsage(
        inputTokens: inputTokens,
        cachedTokens: cachedTokens,
        outputTokens: outputTokens,
        totalTokens: totalTokens,
      );
    }

    return null;
  }

  int _parseCachedTokens(Map usage) {
    final direct = _parseInt(usage['cached_tokens']);
    if (direct > 0) return direct;

    final details = usage['input_tokens_details'];
    if (details is Map) {
      return _parseInt(details['cached_tokens']);
    }

    return _parseInt(usage['cached_input_tokens']);
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _calculateCost({
    required int inputTokens,
    required int cachedTokens,
    required int outputTokens,
  }) {
    final inputCost = inputTokens * (_inputCostPerM / _oneMillion);
    final cachedCost = cachedTokens * (_cachedCostPerM / _oneMillion);
    final outputCost = outputTokens * (_outputCostPerM / _oneMillion);
    return inputCost + cachedCost + outputCost;
  }

  Future<void> logConversation({
    required String sessionId,
    required String userMessage,
    required String assistantMessage,
    required int inputTokens,
    required int outputTokens,
    required int cachedTokens,
    DateTime? timestamp,
    int? totalTokensOverride,
  }) async {
    final totalTokens =
        totalTokensOverride ?? inputTokens + outputTokens + cachedTokens;
    final estimatedCostUsd = _calculateCost(
      inputTokens: inputTokens,
      cachedTokens: cachedTokens,
      outputTokens: outputTokens,
    );

    final entry = ConversationLog(
      sessionId: sessionId,
      timestamp: (timestamp ?? DateTime.now()).toUtc(),
      userMessage: userMessage,
      assistantMessage: assistantMessage,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      cachedTokens: cachedTokens,
      totalTokens: totalTokens,
      estimatedCostUsd: estimatedCostUsd,
    );

    await _logConversationUseCase(entry);

    final message = StringBuffer()
      ..writeln('[Conversation Logged]')
      ..writeln('Session: ${entry.sessionId}')
      ..writeln('Timestamp: ${entry.timestamp.toIso8601String()}')
      ..writeln('Input Tokens: ${entry.inputTokens}')
      ..writeln('Output Tokens: ${entry.outputTokens}')
      ..writeln('Cached Tokens: ${entry.cachedTokens}')
      ..writeln('Total Tokens: ${entry.totalTokens}')
      ..writeln(
        'Estimated Cost (USD): ${entry.estimatedCostUsd.toStringAsFixed(6)}',
      );

    AppLogger.info('VoiceConversation', message.toString());
  }

  void reset() {
    _resetPending();
    logLifecycle('Memory reset');
  }

  static String _normalizeModel(String value) {
    return value.trim().isEmpty ? 'unknown' : value.trim();
  }

  static String _normalizeSessionId(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? _buildDefaultSessionId() : normalized;
  }

  static String _buildDefaultSessionId() {
    final now = DateTime.now().toUtc();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return 'booking_$year$month${day}_$hour$minute$second';
  }
}
