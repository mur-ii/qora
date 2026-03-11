import 'dart:async';

import 'package:flutter/foundation.dart';

import '../entities/connection_state_entity.dart';
import '../entities/function_call_entity.dart';
import '../entities/voice_assistant_status.dart';
import '../entities/voice_session_entity.dart';
import '../repositories/voice_assistant_repository.dart';
import 'agentic_ai_usecase.dart';
import 'session_token_tracker.dart';
import 'voice_conversation_logger.dart';

class VoiceSessionUseCase {
  VoiceSessionUseCase({
    required this.repository,
    required this.agenticAiUseCase,
    required this.logger,
    required this.tokenTracker,
  });

  final VoiceAssistantRepository repository;
  final AgenticAiUseCase agenticAiUseCase;
  final VoiceConversationLogger logger;
  final SessionTokenTracker tokenTracker;

  VoiceSessionEntity? _session;
  bool _isConnecting = false;
  bool _isStopping = false;
  bool _isClosingSession = false;
  Completer<void>? _responseDoneCompleter;

  final ValueNotifier<VoiceAssistantStatus> statusNotifier = ValueNotifier(
    VoiceAssistantStatus.idle,
  );

  bool get isBusy => _isConnecting || _isStopping;

  VoiceAssistantStatus get status => statusNotifier.value;

  bool get isConnected =>
      status == VoiceAssistantStatus.connected ||
      status == VoiceAssistantStatus.listening ||
      status == VoiceAssistantStatus.speaking;

  void updateStatus(VoiceAssistantStatus status) {
    if (statusNotifier.value == status) return;
    statusNotifier.value = status;
  }

  Future<VoiceSessionEntity> start({
    required String model,
    required String voice,
    List<Map<String, dynamic>>? tools,
    String? instructions,
    required Function(ConnectionStateEntity) onConnectionStateChange,
    required Function(String) onTranscript,
    required Function(FunctionCallEntity) onFunctionCall,
    required Function(Map<String, dynamic>) onAgentEvent,
  }) async {
    resetMemory();
    tokenTracker.reset();

    return _connect(
      model: model,
      voice: voice,
      tools: tools,
      instructions: instructions,
      onConnectionStateChange: onConnectionStateChange,
      onTranscript: onTranscript,
      onFunctionCall: onFunctionCall,
      onAgentEvent: onAgentEvent,
    );
  }

  Future<void> stop() async {
    if (_isStopping) return;
    _isStopping = true;

    try {
      await _disconnect();
      logger.logSessionSummary();
    } finally {
      tokenTracker.reset();
      resetMemory();
      _isStopping = false;
    }
  }

  Future<void> endSessionWithMessage(String message) async {
    if (_isClosingSession || !isConnected) return;
    _isClosingSession = true;

    try {
      _responseDoneCompleter = Completer<void>();
      await requestAssistantResponse(message);
      await _waitForResponseDone();
    } catch (_) {
      // Ignore and continue to disconnect.
    } finally {
      _responseDoneCompleter = null;
      await stop();
      _isClosingSession = false;
    }
  }

  void handleAgentEvent(Map<String, dynamic> event) {
    final type = event['type']?.toString();
    if (type == 'response.done' || type == 'error') {
      final completer = _responseDoneCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<void> sendFunctionResult(FunctionResultEntity result) async {
    if (_session == null) {
      throw Exception('Voice assistant session is not active');
    }
    await repository.sendFunctionResult(result);
  }

  Future<void> requestAssistantResponse(String instructions) async {
    if (_session == null) {
      throw Exception('Voice assistant session is not active');
    }
    await repository.requestAssistantResponse(instructions);
  }

  Future<void> setMicrophoneMuted({required bool isMuted}) async {
    await repository.setMicrophoneMuted(isMuted: isMuted);
  }

  void resetMemory() {
    agenticAiUseCase.reset();
    logger.reset();
  }

  Future<VoiceSessionEntity> _connect({
    required String model,
    required String voice,
    List<Map<String, dynamic>>? tools,
    String? instructions,
    required Function(ConnectionStateEntity) onConnectionStateChange,
    required Function(String) onTranscript,
    required Function(FunctionCallEntity) onFunctionCall,
    required Function(Map<String, dynamic>) onAgentEvent,
  }) async {
    if (_isConnecting) {
      throw Exception('Voice assistant is already connecting');
    }

    _isConnecting = true;

    try {
      if (_session != null) {
        await _disconnect();
      }

      final session = await repository.createSession(
        model: model,
        voice: voice,
        tools: tools,
        instructions: instructions,
      );

      _session = session;
      logger.setModelName(session.model);
      logger.logLifecycle('Session created');

      await repository.initializeWebRTC(
        clientSecret: session.clientSecret,
        modelName: session.model,
        onConnectionStateChange: onConnectionStateChange,
        onTranscript: onTranscript,
        onFunctionCall: onFunctionCall,
        onAgentEvent: onAgentEvent,
      );

      return session;
    } catch (e) {
      logger.logError('Failed to connect voice assistant', error: e);
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _disconnect() async {
    try {
      await repository.disconnect();
    } finally {
      _session = null;
      logger.logLifecycle('Session closed');
    }
  }

  Future<void> _waitForResponseDone() async {
    final completer = _responseDoneCompleter;
    if (completer == null) return;

    try {
      await completer.future.timeout(const Duration(seconds: 12));
    } on TimeoutException {
      // Proceed with disconnect on timeout.
    }
  }
}
