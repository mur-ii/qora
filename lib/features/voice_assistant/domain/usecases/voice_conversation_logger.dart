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
  final Map<String, dynamic> inputTokenDetails;
  final Map<String, dynamic> outputTokenDetails;
  final String? responseId;

  const VoiceTokenUsage({
    required this.inputTokens,
    required this.cachedTokens,
    required this.outputTokens,
    required this.totalTokens,
    this.inputTokenDetails = const <String, dynamic>{},
    this.outputTokenDetails = const <String, dynamic>{},
    this.responseId,
  });

  const VoiceTokenUsage.empty()
    : inputTokens = 0,
      cachedTokens = 0,
      outputTokens = 0,
      totalTokens = 0,
      inputTokenDetails = const <String, dynamic>{},
      outputTokenDetails = const <String, dynamic>{},
      responseId = null;
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
    final logs = await getConversationLogsBySession(_sessionId);
    final totalInputTokens = logs.fold<int>(
      0,
      (sum, log) => sum + log.inputTokens,
    );
    final totalOutputTokens = logs.fold<int>(
      0,
      (sum, log) => sum + log.outputTokens,
    );
    final totalCachedTokens = logs.fold<int>(
      0,
      (sum, log) => sum + log.cachedTokens,
    );
    final totalTokens = logs.fold<int>(0, (sum, log) => sum + log.totalTokens);
    final totalCost = await calculateSessionCost(_sessionId);

    final summary = StringBuffer()
      ..writeln('[Session Summary]')
      ..writeln('Session: $_sessionId')
      ..writeln('Model: $_modelName')
      ..writeln('Total Turns: ${logs.length}')
      ..writeln('Total Input Tokens: $totalInputTokens')
      ..writeln('Total Output Tokens: $totalOutputTokens')
      ..writeln('Total Cached Tokens: $totalCachedTokens')
      ..writeln('Total Tokens: $totalTokens')
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
            _logConversationBySentence(
              speaker: 'User',
              eventType: type,
              text: transcript,
            );
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
            _logConversationBySentence(
              speaker: 'Assistant',
              eventType: type,
              text: resolvedTranscript,
            );
          }
          logLifecycle('Assistant response received');
          unawaited(_tryFinalizeTurn());
          break;

        case 'response.done':
          _pendingUsage = _parseUsage(event);
          if (_pendingUsage != null) {
            _logRealtimeUsageBreakdown(_pendingUsage!);
          } else {
            AppLogger.warn(
              'VoiceToken',
              '[OpenAI Usage] response.done received without usage payload',
            );
          }
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

    _logTurnTokenSource(
      usedRealtimeUsage: usage != null,
      estimatedInput: estimatedInput,
      estimatedOutput: estimatedOutput,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      cachedTokens: cachedTokens,
      totalTokens: totalTokens,
    );

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
      final inputTokenDetails = _toStringDynamicMap(
        usage['input_tokens_details'] ?? usage['input_token_details'],
      );
      final outputTokenDetails = _toStringDynamicMap(
        usage['output_tokens_details'] ?? usage['output_token_details'],
      );
      final responseId = (response is Map ? response['id'] : null)?.toString();

      return VoiceTokenUsage(
        inputTokens: inputTokens,
        cachedTokens: cachedTokens,
        outputTokens: outputTokens,
        totalTokens: totalTokens,
        inputTokenDetails: inputTokenDetails,
        outputTokenDetails: outputTokenDetails,
        responseId: responseId,
      );
    }

    return null;
  }

  Map<String, dynamic> _toStringDynamicMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
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

  double _calculateInputCost(int tokens) {
    return tokens * (_inputCostPerM / _oneMillion);
  }

  double _calculateCachedCost(int tokens) {
    return tokens * (_cachedCostPerM / _oneMillion);
  }

  double _calculateOutputCost(int tokens) {
    return tokens * (_outputCostPerM / _oneMillion);
  }

  void _logRealtimeUsageBreakdown(VoiceTokenUsage usage) {
    final inputCost = _calculateInputCost(usage.inputTokens);
    final cachedCost = _calculateCachedCost(usage.cachedTokens);
    final outputCost = _calculateOutputCost(usage.outputTokens);
    final totalCost = inputCost + cachedCost + outputCost;

    final message = StringBuffer()
      ..writeln('[OpenAI Usage]')
      ..writeln('Session: $_sessionId')
      ..writeln('Model: $_modelName')
      ..writeln('Response ID: ${usage.responseId ?? '-'}')
      ..writeln('Input Tokens: ${usage.inputTokens}')
      ..writeln('Output Tokens: ${usage.outputTokens}')
      ..writeln('Cached Tokens: ${usage.cachedTokens}')
      ..writeln('Total Tokens: ${usage.totalTokens}')
      ..writeln(
        'Input Details: ${_formatUsageDetails(usage.inputTokenDetails)}',
      )
      ..writeln(
        'Output Details: ${_formatUsageDetails(usage.outputTokenDetails)}',
      )
      ..writeln('Cost Input (USD): ${inputCost.toStringAsFixed(6)}')
      ..writeln('Cost Cached (USD): ${cachedCost.toStringAsFixed(6)}')
      ..writeln('Cost Output (USD): ${outputCost.toStringAsFixed(6)}')
      ..writeln('Cost Total (USD): ${totalCost.toStringAsFixed(6)}');

    AppLogger.info('VoiceToken', message.toString());
  }

  void _logTurnTokenSource({
    required bool usedRealtimeUsage,
    required int estimatedInput,
    required int estimatedOutput,
    required int inputTokens,
    required int outputTokens,
    required int cachedTokens,
    required int totalTokens,
  }) {
    final source = usedRealtimeUsage ? 'openai_usage' : 'estimation_fallback';
    final message = StringBuffer()
      ..writeln('[Turn Token Source]')
      ..writeln('Session: $_sessionId')
      ..writeln('Model: $_modelName')
      ..writeln('Source: $source')
      ..writeln('Estimated Input Tokens: $estimatedInput')
      ..writeln('Estimated Output Tokens: $estimatedOutput')
      ..writeln('Resolved Input Tokens: $inputTokens')
      ..writeln('Resolved Output Tokens: $outputTokens')
      ..writeln('Resolved Cached Tokens: $cachedTokens')
      ..writeln('Resolved Total Tokens: $totalTokens');

    AppLogger.info('VoiceToken', message.toString());
  }

  void _logConversationBySentence({
    required String speaker,
    required String eventType,
    required String text,
  }) {
    final normalized = _normalizeText(text);
    if (normalized.isEmpty) return;

    final sentences = _splitSentences(normalized);
    AppLogger.info(
      'VoiceConversation',
      '[Conversation][$speaker] event=$eventType session=$_sessionId model=$_modelName sentence_count=${sentences.length}',
    );

    for (var i = 0; i < sentences.length; i++) {
      AppLogger.info(
        'VoiceConversation',
        '[Conversation][$speaker][Sentence ${i + 1}] ${sentences[i]}',
      );
    }
  }

  String _normalizeText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> _splitSentences(String text) {
    final normalized = _normalizeText(text);
    if (normalized.isEmpty) {
      return const <String>[];
    }

    final matches = RegExp(r'[^.!?]+[.!?]?').allMatches(normalized);
    final sentences = <String>[];
    for (final match in matches) {
      final sentence = _normalizeText(match.group(0) ?? '');
      if (sentence.isNotEmpty) {
        sentences.add(sentence);
      }
    }

    if (sentences.isEmpty) {
      return <String>[normalized];
    }

    return sentences;
  }

  String _formatUsageDetails(Map<String, dynamic> details) {
    if (details.isEmpty) {
      return '-';
    }

    return details.entries
        .map((entry) => '${entry.key}=${_detailValueToString(entry.value)}')
        .join(', ');
  }

  String _detailValueToString(dynamic value) {
    if (value == null) {
      return 'null';
    }
    if (value is String) {
      return value;
    }
    if (value is num || value is bool) {
      return value.toString();
    }
    if (value is List) {
      return value.join('|');
    }
    if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}:${_detailValueToString(entry.value)}')
          .join(';');
    }
    return value.toString();
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

    final runningSessionCost = await calculateSessionCost(sessionId);
    final inputCost = _calculateInputCost(entry.inputTokens);
    final cachedCost = _calculateCachedCost(entry.cachedTokens);
    final outputCost = _calculateOutputCost(entry.outputTokens);

    final message = StringBuffer()
      ..writeln('[Conversation Logged]')
      ..writeln('Session: ${entry.sessionId}')
      ..writeln('Timestamp: ${entry.timestamp.toIso8601String()}')
      ..writeln('User Message: ${_normalizeText(entry.userMessage)}')
      ..writeln('Assistant Message: ${_normalizeText(entry.assistantMessage)}')
      ..writeln('Input Tokens: ${entry.inputTokens}')
      ..writeln('Output Tokens: ${entry.outputTokens}')
      ..writeln('Cached Tokens: ${entry.cachedTokens}')
      ..writeln('Total Tokens: ${entry.totalTokens}')
      ..writeln('Input Cost (USD): ${inputCost.toStringAsFixed(6)}')
      ..writeln('Cached Cost (USD): ${cachedCost.toStringAsFixed(6)}')
      ..writeln('Output Cost (USD): ${outputCost.toStringAsFixed(6)}')
      ..writeln(
        'Estimated Cost (USD): ${entry.estimatedCostUsd.toStringAsFixed(6)}',
      )
      ..writeln(
        'Session Running Cost (USD): ${runningSessionCost.toStringAsFixed(6)}',
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
