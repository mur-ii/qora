import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/utils/app_logger.dart';
import 'session_token_tracker.dart';

class VoiceTokenUsage {
  final int inputTokens;
  final int cachedInputTokens;
  final int outputTokens;
  final int totalTokens;

  const VoiceTokenUsage({
    required this.inputTokens,
    required this.cachedInputTokens,
    required this.outputTokens,
    required this.totalTokens,
  });

  const VoiceTokenUsage.empty()
    : inputTokens = 0,
      cachedInputTokens = 0,
      outputTokens = 0,
      totalTokens = 0;

  Map<String, dynamic> toJson() {
    return {
      'input_tokens': inputTokens,
      'cached_input_tokens': cachedInputTokens,
      'output_tokens': outputTokens,
      'total_tokens': totalTokens,
    };
  }
}

class VoiceConversationTurnLog {
  final DateTime timestamp;
  final String modelName;
  final String userTranscript;
  final String assistantResponse;
  final VoiceTokenUsage tokenUsage;
  final int? audioDurationMs;

  const VoiceConversationTurnLog({
    required this.timestamp,
    required this.modelName,
    required this.userTranscript,
    required this.assistantResponse,
    required this.tokenUsage,
    this.audioDurationMs,
  });
}

/// Reusable logger for Realtime voice conversations.
class VoiceConversationLogger {
  VoiceConversationLogger({
    String? modelName,
    SessionTokenTracker? tokenTracker,
  }) : _modelName = _normalizeModel(modelName ?? 'unknown'),
       _tokenTracker = tokenTracker;

  String _modelName;
  final SessionTokenTracker? _tokenTracker;

  String? _pendingUserTranscript;
  DateTime? _pendingUserTimestamp;
  StringBuffer? _assistantBuffer;
  String? _pendingAssistantTranscript;
  VoiceTokenUsage? _pendingUsage;
  int? _pendingAudioDurationMs;
  bool _responseDoneSeen = false;

  DateTime? _pendingAudioStart;

  bool _fileLoggingEnabled = false;
  File? _logFile;
  String _logFileName = 'voice_conversation.log';

  String get modelName => _modelName;

  void enableFileLogging({String fileName = 'voice_conversation.log'}) {
    _logFileName = fileName;
    _fileLoggingEnabled = true;
    unawaited(_ensureLogFile());
  }

  void disableFileLogging() {
    _fileLoggingEnabled = false;
    _logFile = null;
  }

  void setModelName(String? value) {
    if (value == null) return;
    final normalized = _normalizeModel(value);
    _modelName = normalized;
  }

  void logLifecycle(String message) {
    scheduleMicrotask(() {
      AppLogger.info('VoiceLifecycle', message);
      _appendToFile('[LIFECYCLE] $message');
    });
  }

  void logError(String message, {Object? error}) {
    scheduleMicrotask(() {
      AppLogger.error('VoiceLifecycle', message, error: error);
      _appendToFile('[ERROR] $message');
    });
  }

  void logSessionSummary() {
    if (_tokenTracker == null) return;
    final summary = _tokenTracker.buildSummary();
    AppLogger.info('VoiceSession', summary);
    _appendToFile(summary);
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

        case 'input_audio_buffer.speech_started':
          _pendingAudioStart = DateTime.now().toUtc();
          _pendingAudioDurationMs = null;
          logLifecycle('Audio chunk sent');
          break;

        case 'input_audio_buffer.speech_stopped':
          final start = _pendingAudioStart;
          if (start != null) {
            final duration = DateTime.now().toUtc().difference(start);
            _pendingAudioDurationMs = duration.inMilliseconds;
          }
          _pendingAudioStart = null;
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
          _tryFinalizeTurn();
          break;

        case 'response.done':
          final usage = _parseUsage(event) ?? const VoiceTokenUsage.empty();
          _pendingUsage = usage;
          _responseDoneSeen = true;
          _logTokenUsageSummary(usage: usage);
          _tryFinalizeTurn();
          break;

        default:
          break;
      }
    });
  }

  void _tryFinalizeTurn() {
    if (_pendingUserTranscript == null || _pendingAssistantTranscript == null) {
      return;
    }

    if (!_responseDoneSeen && _pendingUsage == null) {
      return;
    }

    final entry = VoiceConversationTurnLog(
      timestamp: _pendingUserTimestamp ?? DateTime.now().toUtc(),
      modelName: _modelName,
      userTranscript: _pendingUserTranscript!,
      assistantResponse: _pendingAssistantTranscript!,
      tokenUsage: _pendingUsage ?? const VoiceTokenUsage.empty(),
      audioDurationMs: _pendingAudioDurationMs,
    );

    _printEntry(entry);
    _resetPending();
  }

  void _resetPending() {
    _pendingUserTranscript = null;
    _pendingUserTimestamp = null;
    _assistantBuffer = null;
    _pendingAssistantTranscript = null;
    _pendingUsage = null;
    _pendingAudioDurationMs = null;
    _responseDoneSeen = false;
    _pendingAudioStart = null;
  }

  void _updateModelFromEvent(Map<String, dynamic> event) {
    final session = event['session'];
    if (session is Map) {
      setModelName(session['model']?.toString());
      _tokenTracker?.setModelName(session['model']?.toString());
      return;
    }

    setModelName(event['model']?.toString());
    _tokenTracker?.setModelName(event['model']?.toString());
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
        cachedInputTokens: cachedTokens,
        outputTokens: outputTokens,
        totalTokens: totalTokens,
      );
    }

    return null;
  }

  int _parseCachedTokens(Map usage) {
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

  void _printEntry(VoiceConversationTurnLog entry) {
    final timestamp = _formatTimestamp(entry.timestamp.toUtc());
    final userBlock = _formatConversationBlock(
      timestamp: timestamp,
      role: 'USER',
      transcript: entry.userTranscript,
      audioDurationMs: entry.audioDurationMs,
    );
    final assistantBlock = _formatConversationBlock(
      timestamp: timestamp,
      role: 'ASSISTANT',
      transcript: entry.assistantResponse,
      audioDurationMs: null,
    );

    AppLogger.info('VoiceConversation', userBlock);
    AppLogger.info('VoiceConversation', assistantBlock);
    _appendToFile(userBlock);
    _appendToFile(assistantBlock);
  }

  void _logTokenUsageSummary({required VoiceTokenUsage usage}) {
    _tokenTracker?.recordUsage(
      inputTokens: usage.inputTokens,
      cachedInputTokens: usage.cachedInputTokens,
      outputTokens: usage.outputTokens,
      modelName: _modelName,
    );

    final perResponseCost = _calculateCost(usage);

    final buffer = StringBuffer()
      ..writeln('[Realtime Usage]')
      ..writeln('Model: $_modelName')
      ..writeln('Input Tokens: ${usage.inputTokens}')
      ..writeln('Cached Tokens: ${usage.cachedInputTokens}')
      ..writeln('Output Tokens: ${usage.outputTokens}')
      ..writeln('Estimated Cost: ${perResponseCost.toStringAsFixed(6)}');

    AppLogger.info('VoiceUsage', buffer.toString());
    _appendToFile(buffer.toString());
    logLifecycle('Token usage logged');
  }

  double _calculateCost(VoiceTokenUsage usage) {
    final inputCost = usage.inputTokens * (0.60 / 1000000);
    final cachedCost = usage.cachedInputTokens * (0.06 / 1000000);
    final outputCost = usage.outputTokens * (2.40 / 1000000);
    return inputCost + cachedCost + outputCost;
  }

  String _formatConversationBlock({
    required String timestamp,
    required String role,
    required String transcript,
    int? audioDurationMs,
  }) {
    final buffer = StringBuffer()
      ..writeln('[$timestamp]')
      ..writeln('$role:')
      ..writeln('"$transcript"');

    if (audioDurationMs != null) {
      buffer.writeln('Audio Duration: ${audioDurationMs}ms');
    }

    return buffer.toString();
  }

  String _formatTimestamp(DateTime timestamp) {
    final year = timestamp.year.toString().padLeft(4, '0');
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  Future<void> _ensureLogFile() async {
    if (!_fileLoggingEnabled || _logFile != null) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}${Platform.pathSeparator}$_logFileName';
      _logFile = File(filePath);
    } catch (e) {
      AppLogger.warn('VoiceLog', 'Failed to initialize log file: $e');
    }
  }

  void _appendToFile(String message) {
    if (!_fileLoggingEnabled) return;
    unawaited(_appendToFileInternal(message));
  }

  Future<void> _appendToFileInternal(String message) async {
    await _ensureLogFile();
    final file = _logFile;
    if (file == null) return;
    try {
      await file.writeAsString('$message\n', mode: FileMode.append);
    } catch (_) {
      // Ignore file write errors to avoid impacting runtime.
    }
  }

  void reset() {
    _resetPending();
    logLifecycle('Memory reset');
  }

  static String _normalizeModel(String value) {
    return value.trim().isEmpty ? 'unknown' : value.trim();
  }
}
