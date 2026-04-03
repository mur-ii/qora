import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../../core/utils/app_logger.dart';
import '../entities/conversation_log.dart';
import '../repositories/conversation_repository.dart';
import 'calculate_session_cost.dart';
import 'log_conversation.dart';
import 'token_estimator.dart';

enum Modality { text, voice }

String formatCurrency(double value) => value.toStringAsFixed(6);

String modalityLabel(Modality type) {
  switch (type) {
    case Modality.text:
      return 'TEXT';
    case Modality.voice:
      return 'VOICE';
  }
}

class SessionMetadata {
  const SessionMetadata({
    required this.sessionId,
    required this.model,
    required this.totalTurns,
  });

  final String sessionId;
  final String model;
  final int totalTurns;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'session_id': sessionId,
      'model': model,
      'total_turns': totalTurns,
    };
  }
}

class ConversationTurn {
  const ConversationTurn({
    required this.userText,
    required this.assistantText,
    required this.userModality,
    required this.assistantModality,
    required this.timestamp,
  });

  final String userText;
  final String assistantText;
  final Modality userModality;
  final Modality assistantModality;
  final DateTime timestamp;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'timestamp': timestamp.toUtc().toIso8601String(),
      'user_text': userText,
      'assistant_text': assistantText,
      'user_modality': modalityLabel(userModality),
      'assistant_modality': modalityLabel(assistantModality),
    };
  }
}

class TokenUsage {
  const TokenUsage({
    required this.input,
    required this.output,
    required this.cached,
    required this.inputCostUsd,
    required this.outputCostUsd,
    required this.cachedCostUsd,
  });

  const TokenUsage.zero()
    : input = 0,
      output = 0,
      cached = 0,
      inputCostUsd = 0,
      outputCostUsd = 0,
      cachedCostUsd = 0;

  final int input;
  final int output;
  final int cached;
  final double inputCostUsd;
  final double outputCostUsd;
  final double cachedCostUsd;

  int get total => input + output + cached;
  double get totalCostUsd => inputCostUsd + outputCostUsd + cachedCostUsd;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'input_tokens': input,
      'output_tokens': output,
      'cached_tokens': cached,
      'total_tokens': total,
      'input_cost_usd': inputCostUsd,
      'output_cost_usd': outputCostUsd,
      'cached_cost_usd': cachedCostUsd,
      'total_cost_usd': totalCostUsd,
    };
  }
}

class TurnUsage {
  const TurnUsage({
    required this.turnNumber,
    required this.usage,
    required this.inputModality,
    required this.outputModality,
  });

  final int turnNumber;
  final TokenUsage usage;
  final Modality inputModality;
  final Modality outputModality;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'turn': turnNumber,
      'tokens': usage.toMap(),
      'input_modality': modalityLabel(inputModality),
      'output_modality': modalityLabel(outputModality),
    };
  }
}

class VoiceSessionSummary {
  const VoiceSessionSummary({
    required this.metadata,
    required this.conversationTurns,
    required this.aggregatedUsage,
    required this.turnUsages,
  });

  factory VoiceSessionSummary.empty({
    required String sessionId,
    required String model,
  }) {
    return VoiceSessionSummary(
      metadata: SessionMetadata(
        sessionId: sessionId,
        model: model,
        totalTurns: 0,
      ),
      conversationTurns: const <ConversationTurn>[],
      aggregatedUsage: const TokenUsage.zero(),
      turnUsages: const <TurnUsage>[],
    );
  }

  final SessionMetadata metadata;
  final List<ConversationTurn> conversationTurns;
  final TokenUsage aggregatedUsage;
  final List<TurnUsage> turnUsages;

  String get sessionId => metadata.sessionId;
  String get model => metadata.model;
  int get totalTurns => metadata.totalTurns;
  int get inputTokens => aggregatedUsage.input;
  int get outputTokens => aggregatedUsage.output;
  int get cachedTokens => aggregatedUsage.cached;
  int get totalTokens => aggregatedUsage.total;
  double get inputCostUsd => aggregatedUsage.inputCostUsd;
  double get outputCostUsd => aggregatedUsage.outputCostUsd;
  double get cachedCostUsd => aggregatedUsage.cachedCostUsd;
  double get totalCostUsd => aggregatedUsage.totalCostUsd;
  List<String> get userConversation => conversationTurns
      .map((turn) => turn.userText)
      .where((text) => text.trim().isNotEmpty)
      .toList(growable: false);
  List<String> get assistantConversation => conversationTurns
      .map((turn) => turn.assistantText)
      .where((text) => text.trim().isNotEmpty)
      .toList(growable: false);
  List<TurnUsage> get turns => turnUsages;

  Map<String, dynamic> toPerformanceDetails() {
    final transcript = <Map<String, dynamic>>[];

    for (var i = 0; i < conversationTurns.length; i++) {
      final turn = conversationTurns[i];
      if (turn.userText.trim().isNotEmpty) {
        transcript.add(<String, dynamic>{
          'index': transcript.length + 1,
          'speaker': 'user',
          'message': turn.userText,
          'timestamp': turn.timestamp.toUtc().toIso8601String(),
          'turn': i + 1,
          'modality': modalityLabel(turn.userModality),
        });
      }

      if (turn.assistantText.trim().isNotEmpty) {
        transcript.add(<String, dynamic>{
          'index': transcript.length + 1,
          'speaker': 'assistant',
          'message': turn.assistantText,
          'timestamp': turn.timestamp.toUtc().toIso8601String(),
          'turn': i + 1,
          'modality': modalityLabel(turn.assistantModality),
        });
      }
    }

    return <String, dynamic>{
      'session_id': metadata.sessionId,
      'model': metadata.model,
      'conversation_user': userConversation,
      'conversation_assistant': assistantConversation,
      'conversation_transcript': transcript,
      'turns_detail': turnUsages
          .map((turn) => turn.toMap())
          .toList(growable: false),
      'total_turns': metadata.totalTurns,
      'token_usage': aggregatedUsage.toMap(),
      'metadata': metadata.toMap(),
    };
  }
}

class _TurnModalityPair {
  const _TurnModalityPair({required this.input, required this.output});

  final Modality input;
  final Modality output;
}

class _VoiceTokenUsage {
  final int inputTokens;
  final int cachedTokens;
  final int outputTokens;
  final int totalTokens;
  final Map<String, dynamic> inputTokenDetails;
  final Map<String, dynamic> outputTokenDetails;
  final String? responseId;

  const _VoiceTokenUsage({
    required this.inputTokens,
    required this.cachedTokens,
    required this.outputTokens,
    required this.totalTokens,
    this.inputTokenDetails = const <String, dynamic>{},
    this.outputTokenDetails = const <String, dynamic>{},
    this.responseId,
  });
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
  Modality _pendingUserModality = Modality.voice;
  StringBuffer? _assistantBuffer;
  String? _pendingAssistantTranscript;
  Modality _pendingAssistantModality = Modality.voice;
  _VoiceTokenUsage? _pendingUsage;
  bool _responseDoneSeen = false;
  bool _isFinalizing = false;
  final List<_TurnModalityPair> _turnModalities = <_TurnModalityPair>[];

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

    final conversationTurns = <ConversationTurn>[];
    final turnDetails = <TurnUsage>[];

    var totalInputTokens = 0;
    var totalOutputTokens = 0;
    var totalCachedTokens = 0;
    var totalInputCost = 0.0;
    var totalOutputCost = 0.0;
    var totalCachedCost = 0.0;

    for (var i = 0; i < logs.length; i++) {
      final log = logs[i];
      final normalizedUser = _normalizeText(log.userMessage);
      final normalizedAssistant = _normalizeText(log.assistantMessage);

      final modalities = i < _turnModalities.length
          ? _turnModalities[i]
          : const _TurnModalityPair(
              input: Modality.voice,
              output: Modality.voice,
            );

      final inputCost = _calculateInputCost(log.inputTokens);
      final outputCost = _calculateOutputCost(log.outputTokens);
      final cachedCost = _calculateCachedCost(log.cachedTokens);
      final usage = TokenUsage(
        input: math.max(0, log.inputTokens),
        output: math.max(0, log.outputTokens),
        cached: math.max(0, log.cachedTokens),
        inputCostUsd: inputCost,
        outputCostUsd: outputCost,
        cachedCostUsd: cachedCost,
      );

      conversationTurns.add(
        ConversationTurn(
          userText: normalizedUser,
          assistantText: normalizedAssistant,
          userModality: modalities.input,
          assistantModality: modalities.output,
          timestamp: log.timestamp.toUtc(),
        ),
      );

      totalInputTokens += usage.input;
      totalOutputTokens += usage.output;
      totalCachedTokens += usage.cached;
      totalInputCost += inputCost;
      totalOutputCost += outputCost;
      totalCachedCost += cachedCost;

      turnDetails.add(
        TurnUsage(
          turnNumber: i + 1,
          usage: usage,
          inputModality: modalities.input,
          outputModality: modalities.output,
        ),
      );
    }

    final pendingTurn = _buildPendingTurn();
    if (pendingTurn != null) {
      final pendingUsage = pendingTurn.$2;
      final turnNumber = turnDetails.length + 1;

      conversationTurns.add(pendingTurn.$1);
      turnDetails.add(
        TurnUsage(
          turnNumber: turnNumber,
          usage: pendingUsage,
          inputModality: pendingTurn.$1.userModality,
          outputModality: pendingTurn.$1.assistantModality,
        ),
      );

      totalInputTokens += pendingUsage.input;
      totalOutputTokens += pendingUsage.output;
      totalCachedTokens += pendingUsage.cached;
      totalInputCost += pendingUsage.inputCostUsd;
      totalOutputCost += pendingUsage.outputCostUsd;
      totalCachedCost += pendingUsage.cachedCostUsd;
    }

    final totalTurns = conversationTurns.length;
    final aggregatedUsage = TokenUsage(
      input: totalInputTokens,
      output: totalOutputTokens,
      cached: totalCachedTokens,
      inputCostUsd: totalInputCost,
      outputCostUsd: totalOutputCost,
      cachedCostUsd: totalCachedCost,
    );

    return VoiceSessionSummary(
      metadata: SessionMetadata(
        sessionId: resolvedSessionId,
        model: _modelName,
        totalTurns: totalTurns,
      ),
      conversationTurns: conversationTurns,
      aggregatedUsage: aggregatedUsage,
      turnUsages: turnDetails,
    );
  }

  Future<VoiceSessionSummary> printSessionSummary({String? sessionId}) async {
    final summary = await buildSessionSummary(sessionId: sessionId);
    _printSafely(_formatSessionSummaryLog(summary));
    return summary;
  }

  Future<VoiceSessionSummary> logSessionSummary({String? sessionId}) async {
    final summary = await printSessionSummary(sessionId: sessionId);
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
            _pendingUserModality = Modality.voice;
            _assistantBuffer = null;
            _pendingAssistantTranscript = null;
            _pendingAssistantModality = Modality.voice;
            _pendingUsage = null;
            _responseDoneSeen = false;
          }
          break;

        case 'conversation.item.input_text.completed':
          final transcript =
              event['text']?.toString() ?? event['transcript']?.toString();
          if (transcript != null && transcript.isNotEmpty) {
            _pendingUserTranscript = transcript;
            _pendingUserTimestamp = DateTime.now().toUtc();
            _pendingUserModality = Modality.text;
            _assistantBuffer = null;
            _pendingAssistantTranscript = null;
            _pendingAssistantModality = Modality.text;
            _pendingUsage = null;
            _responseDoneSeen = false;
          }
          break;

        case 'conversation.item.created':
          final item = event['item'];
          if (item is Map) {
            final role = item['role']?.toString();
            final extractedText = _extractTextFromItem(item);
            if (role == 'user' && extractedText.isNotEmpty) {
              _pendingUserTranscript = extractedText;
              _pendingUserTimestamp = DateTime.now().toUtc();
              _pendingUserModality = Modality.text;
            }
          }
          break;

        case 'response.audio_transcript.delta':
          final delta =
              event['delta']?.toString() ?? event['transcript']?.toString();
          if (delta != null && delta.isNotEmpty) {
            _assistantBuffer ??= StringBuffer();
            _assistantBuffer!.write(delta);
            _pendingAssistantModality = Modality.voice;
          }
          break;

        case 'response.text.delta':
          final delta = event['delta']?.toString() ?? event['text']?.toString();
          if (delta != null && delta.isNotEmpty) {
            _assistantBuffer ??= StringBuffer();
            _assistantBuffer!.write(delta);
            _pendingAssistantModality = Modality.text;
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
            _pendingAssistantModality = Modality.voice;
          }
          logLifecycle('Assistant response received');
          unawaited(_tryFinalizeTurn());
          break;

        case 'response.text.done':
          final transcript =
              event['text']?.toString() ?? event['transcript']?.toString();
          final bufferText = _assistantBuffer?.toString();
          final resolvedTranscript =
              (transcript != null && transcript.isNotEmpty)
              ? transcript
              : (bufferText ?? '');
          if (resolvedTranscript.isNotEmpty) {
            _pendingAssistantTranscript = resolvedTranscript;
            _pendingAssistantModality = Modality.text;
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
    final inputModality = _pendingUserModality;
    final outputModality = _pendingAssistantModality;

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
      _turnModalities.add(
        _TurnModalityPair(input: inputModality, output: outputModality),
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
    _pendingUserModality = Modality.voice;
    _pendingAssistantModality = Modality.voice;
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

  _VoiceTokenUsage? _parseUsage(Map<String, dynamic> event) {
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

      return _VoiceTokenUsage(
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
    _turnModalities.clear();
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

  (ConversationTurn, TokenUsage)? _buildPendingTurn() {
    final userText = _normalizeText(_pendingUserTranscript ?? '');
    final assistantText = _normalizeText(_pendingAssistantTranscript ?? '');

    if (userText.isEmpty && assistantText.isEmpty) {
      return null;
    }

    final usage = _pendingUsage;
    final inputTokens =
        usage?.inputTokens ??
        (userText.isEmpty ? 0 : _tokenEstimator.estimateTokens(userText));
    final outputTokens =
        usage?.outputTokens ??
        (assistantText.isEmpty
            ? 0
            : _tokenEstimator.estimateTokens(assistantText));
    final cachedTokens = usage?.cachedTokens ?? 0;

    final pendingUsage = TokenUsage(
      input: inputTokens,
      output: outputTokens,
      cached: cachedTokens,
      inputCostUsd: _calculateInputCost(inputTokens),
      outputCostUsd: _calculateOutputCost(outputTokens),
      cachedCostUsd: _calculateCachedCost(cachedTokens),
    );

    return (
      ConversationTurn(
        userText: userText,
        assistantText: assistantText,
        userModality: _pendingUserModality,
        assistantModality: _pendingAssistantModality,
        timestamp: (_pendingUserTimestamp ?? DateTime.now()).toUtc(),
      ),
      pendingUsage,
    );
  }

  String _extractTextFromItem(Map item) {
    final content = item['content'];
    if (content is List) {
      for (final element in content) {
        if (element is Map) {
          final text = element['text']?.toString();
          if (text != null && text.trim().isNotEmpty) {
            return text;
          }
          final transcript = element['transcript']?.toString();
          if (transcript != null && transcript.trim().isNotEmpty) {
            return transcript;
          }
        }
      }
    }

    final directText = item['text']?.toString();
    if (directText != null && directText.trim().isNotEmpty) {
      return directText;
    }

    return '';
  }

  void _printSafely(String message) {
    const maxChunk = 800;
    final lines = message.split('\n');

    for (final rawLine in lines) {
      final line = rawLine;
      if (line.isEmpty) {
        debugPrint('');
        continue;
      }

      var start = 0;
      while (start < line.length) {
        final end = math.min(start + maxChunk, line.length);
        debugPrint(line.substring(start, end));
        start = end;
      }
    }
  }

  String _displayText(String text) {
    final normalized = _normalizeText(text);
    return normalized.isEmpty ? '(empty)' : normalized;
  }

  String _formatSessionSummaryLog(VoiceSessionSummary summary) {
    const divider = '==================================================';

    final buffer = StringBuffer()
      ..writeln(divider)
      ..writeln('[VOICE SESSION SUMMARY]')
      ..writeln(divider)
      ..writeln('')
      ..writeln('[METADATA]')
      ..writeln('  Session ID  : ${summary.sessionId}')
      ..writeln('  Model       : ${summary.model}')
      ..writeln('  Total Turns : ${summary.totalTurns}')
      ..writeln('')
      ..writeln('[CONVERSATION LOG]');

    if (summary.conversationTurns.isEmpty) {
      buffer.writeln('  (empty)');
    } else {
      for (var i = 0; i < summary.conversationTurns.length; i++) {
        final turn = summary.conversationTurns[i];
        buffer
          ..writeln('  Turn ${i + 1}:')
          ..writeln(
            '    User [${modalityLabel(turn.userModality)}]  : ${_displayText(turn.userText)}',
          )
          ..writeln(
            '    Asst [${modalityLabel(turn.assistantModality)}]  : ${_displayText(turn.assistantText)}',
          );
      }
    }

    buffer
      ..writeln('')
      ..writeln('[AGGREGATED USAGE & COST]')
      ..writeln(
        '  Tokens: Input=${summary.inputTokens} | Output=${summary.outputTokens} | Cached=${summary.cachedTokens} | Total=${summary.totalTokens}',
      )
      ..writeln(
        '  Cost  : Input=\$${formatCurrency(summary.inputCostUsd)} | Output=\$${formatCurrency(summary.outputCostUsd)} | Total=\$${formatCurrency(summary.totalCostUsd)}',
      )
      ..writeln('')
      ..writeln('[PER TURN USAGE]');

    if (summary.turnUsages.isEmpty) {
      buffer.writeln('  (empty)');
    } else {
      for (final turn in summary.turnUsages) {
        buffer.writeln(
          '  T${turn.turnNumber} : In=${turn.usage.input}, Out=${turn.usage.output}, Cache=${turn.usage.cached} | Cost=\$${formatCurrency(turn.usage.totalCostUsd)} | Modality: ${modalityLabel(turn.inputModality)} -> ${modalityLabel(turn.outputModality)}',
        );
      }
    }

    buffer
      ..writeln('')
      ..writeln(divider);

    return buffer.toString();
  }
}
