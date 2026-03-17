import 'dart:async';

import '../../../../core/utils/app_logger.dart';
import '../entities/conversation_log.dart';
import '../repositories/conversation_repository.dart';
import 'calculate_session_cost.dart';
import 'log_conversation.dart';
import 'token_estimator.dart';

class VoiceSessionTurnSummary {
  const VoiceSessionTurnSummary({
    required this.turn,
    required this.timestamp,
    required this.userMessage,
    required this.assistantMessage,
    required this.inputTokens,
    required this.outputTokens,
    required this.cachedTokens,
    required this.totalTokens,
    required this.inputCostUsd,
    required this.outputCostUsd,
    required this.cachedCostUsd,
    required this.totalCostUsd,
  });

  final int turn;
  final DateTime timestamp;
  final String userMessage;
  final String assistantMessage;
  final int inputTokens;
  final int outputTokens;
  final int cachedTokens;
  final int totalTokens;
  final double inputCostUsd;
  final double outputCostUsd;
  final double cachedCostUsd;
  final double totalCostUsd;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'turn': turn,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'user_message': userMessage,
      'assistant_message': assistantMessage,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'cached_tokens': cachedTokens,
      'total_tokens': totalTokens,
      'input_cost_usd': inputCostUsd,
      'output_cost_usd': outputCostUsd,
      'cached_cost_usd': cachedCostUsd,
      'total_cost_usd': totalCostUsd,
    };
  }
}

class VoiceSessionSummary {
  const VoiceSessionSummary({
    required this.sessionId,
    required this.model,
    required this.userConversation,
    required this.assistantConversation,
    required this.turns,
    required this.totalTurns,
    required this.inputTokens,
    required this.outputTokens,
    required this.cachedTokens,
    required this.totalTokens,
    required this.inputCostUsd,
    required this.outputCostUsd,
    required this.cachedCostUsd,
    required this.totalCostUsd,
  });

  const VoiceSessionSummary.empty({
    required this.sessionId,
    required this.model,
  }) : userConversation = const <String>[],
       assistantConversation = const <String>[],
       turns = const <VoiceSessionTurnSummary>[],
       totalTurns = 0,
       inputTokens = 0,
       outputTokens = 0,
       cachedTokens = 0,
       totalTokens = 0,
       inputCostUsd = 0,
       outputCostUsd = 0,
       cachedCostUsd = 0,
       totalCostUsd = 0;

  final String sessionId;
  final String model;
  final List<String> userConversation;
  final List<String> assistantConversation;
  final List<VoiceSessionTurnSummary> turns;
  final int totalTurns;
  final int inputTokens;
  final int outputTokens;
  final int cachedTokens;
  final int totalTokens;
  final double inputCostUsd;
  final double outputCostUsd;
  final double cachedCostUsd;
  final double totalCostUsd;

  Map<String, dynamic> toPerformanceDetails() {
    final transcript = <Map<String, dynamic>>[];

    for (final turn in turns) {
      if (turn.userMessage.trim().isNotEmpty) {
        transcript.add(<String, dynamic>{
          'index': transcript.length + 1,
          'speaker': 'user',
          'message': turn.userMessage,
          'timestamp': turn.timestamp.toUtc().toIso8601String(),
          'turn': turn.turn,
        });
      }

      if (turn.assistantMessage.trim().isNotEmpty) {
        transcript.add(<String, dynamic>{
          'index': transcript.length + 1,
          'speaker': 'assistant',
          'message': turn.assistantMessage,
          'timestamp': turn.timestamp.toUtc().toIso8601String(),
          'turn': turn.turn,
        });
      }
    }

    return <String, dynamic>{
      'session_id': sessionId,
      'model': model,
      'conversation_user': userConversation,
      'conversation_assistant': assistantConversation,
      'conversation_transcript': transcript,
      'turns_detail': turns.map((turn) => turn.toMap()).toList(growable: false),
      'total_turns': totalTurns,
      'token_usage': <String, dynamic>{
        'input_tokens': inputTokens,
        'output_tokens': outputTokens,
        'cached_tokens': cachedTokens,
        'total_tokens': totalTokens,
      },
      'cost_calculation': <String, dynamic>{
        'input_cost_usd': inputCostUsd,
        'output_cost_usd': outputCostUsd,
        'cached_cost_usd': cachedCostUsd,
        'total_cost_usd': totalCostUsd,
      },
    };
  }
}

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

  Future<VoiceSessionSummary> buildSessionSummary({String? sessionId}) async {
    final resolvedSessionId = _normalizeSessionId(sessionId ?? _sessionId);
    final logs = await getConversationLogsBySession(resolvedSessionId);

    if (logs.isEmpty) {
      return VoiceSessionSummary.empty(
        sessionId: resolvedSessionId,
        model: _modelName,
      );
    }

    final userConversation = <String>[];
    final assistantConversation = <String>[];
    final turnDetails = <VoiceSessionTurnSummary>[];

    var totalInputTokens = 0;
    var totalOutputTokens = 0;
    var totalCachedTokens = 0;
    var totalTokens = 0;
    var totalInputCost = 0.0;
    var totalOutputCost = 0.0;
    var totalCachedCost = 0.0;

    for (var i = 0; i < logs.length; i++) {
      final log = logs[i];
      final normalizedUser = _normalizeText(log.userMessage);
      final normalizedAssistant = _normalizeText(log.assistantMessage);

      if (normalizedUser.isNotEmpty) {
        userConversation.add(normalizedUser);
      }

      if (normalizedAssistant.isNotEmpty) {
        assistantConversation.add(normalizedAssistant);
      }

      final inputCost = _calculateInputCost(log.inputTokens);
      final outputCost = _calculateOutputCost(log.outputTokens);
      final cachedCost = _calculateCachedCost(log.cachedTokens);
      final totalCost = inputCost + outputCost + cachedCost;

      totalInputTokens += log.inputTokens;
      totalOutputTokens += log.outputTokens;
      totalCachedTokens += log.cachedTokens;
      totalTokens += log.totalTokens;
      totalInputCost += inputCost;
      totalOutputCost += outputCost;
      totalCachedCost += cachedCost;

      turnDetails.add(
        VoiceSessionTurnSummary(
          turn: i + 1,
          timestamp: log.timestamp.toUtc(),
          userMessage: normalizedUser,
          assistantMessage: normalizedAssistant,
          inputTokens: log.inputTokens,
          outputTokens: log.outputTokens,
          cachedTokens: log.cachedTokens,
          totalTokens: log.totalTokens,
          inputCostUsd: inputCost,
          outputCostUsd: outputCost,
          cachedCostUsd: cachedCost,
          totalCostUsd: totalCost,
        ),
      );
    }

    final persistedTotalCost = await calculateSessionCost(resolvedSessionId);
    final totalTurns = userConversation.length + assistantConversation.length;

    return VoiceSessionSummary(
      sessionId: resolvedSessionId,
      model: _modelName,
      userConversation: userConversation,
      assistantConversation: assistantConversation,
      turns: turnDetails,
      totalTurns: totalTurns,
      inputTokens: totalInputTokens,
      outputTokens: totalOutputTokens,
      cachedTokens: totalCachedTokens,
      totalTokens: totalTokens,
      inputCostUsd: totalInputCost,
      outputCostUsd: totalOutputCost,
      cachedCostUsd: totalCachedCost,
      totalCostUsd: persistedTotalCost,
    );
  }

  Future<VoiceSessionSummary> logSessionSummary({String? sessionId}) async {
    final summary = await buildSessionSummary(sessionId: sessionId);
    AppLogger.info('VoiceSession', _formatSessionSummaryLog(summary));
    return summary;
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
          if (_pendingUsage == null) {
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

  String _normalizeText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
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

  String _formatSessionSummaryLog(VoiceSessionSummary summary) {
    final buffer = StringBuffer()
      ..writeln('VOICE SESSION SUMMARY')
      ..writeln('Session ID: ${summary.sessionId}')
      ..writeln('Model: ${summary.model}')
      ..writeln('')
      ..writeln('Percakapan User:');

    if (summary.userConversation.isEmpty) {
      buffer.writeln('- (tidak ada)');
    } else {
      for (var i = 0; i < summary.userConversation.length; i++) {
        buffer.writeln('${i + 1}. User: ${summary.userConversation[i]}');
      }
    }

    buffer
      ..writeln('')
      ..writeln('Percakapan Assistant:');

    if (summary.assistantConversation.isEmpty) {
      buffer.writeln('- (tidak ada)');
    } else {
      for (var i = 0; i < summary.assistantConversation.length; i++) {
        buffer.writeln(
          '${i + 1}. Assistant: ${summary.assistantConversation[i]}',
        );
      }
    }

    buffer
      ..writeln('')
      ..writeln('Total Turns: ${summary.totalTurns}')
      ..writeln('')
      ..writeln('Token Usage:')
      ..writeln('Input Token: ${summary.inputTokens}')
      ..writeln('Output Token: ${summary.outputTokens}')
      ..writeln('Cached Token: ${summary.cachedTokens}')
      ..writeln('Total Token: ${summary.totalTokens}')
      ..writeln('')
      ..writeln('Cost Calculation:')
      ..writeln('Input Cost: \$${summary.inputCostUsd.toStringAsFixed(6)}')
      ..writeln('Output Cost: \$${summary.outputCostUsd.toStringAsFixed(6)}')
      ..writeln('Cache Cost: \$${summary.cachedCostUsd.toStringAsFixed(6)}')
      ..writeln(
        'Total Cost (1 Session): \$${summary.totalCostUsd.toStringAsFixed(6)}',
      )
      ..writeln('')
      ..writeln('Per Turn Token Usage:');

    if (summary.turns.isEmpty) {
      buffer.writeln('- (tidak ada)');
    } else {
      for (final turn in summary.turns) {
        buffer.writeln(
          '${turn.turn}. input=${turn.inputTokens}, output=${turn.outputTokens}, cached=${turn.cachedTokens}, total=${turn.totalTokens}, cost=\$${turn.totalCostUsd.toStringAsFixed(6)}',
        );
      }
    }

    return buffer.toString();
  }
}
