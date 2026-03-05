import 'dart:async';

import 'package:flutter/foundation.dart';

import 'data/services/agentic_ai_service.dart';
import 'domain/entities/connection_state_entity.dart';
import 'domain/entities/function_call_entity.dart';
import 'domain/entities/voice_session_entity.dart';
import 'presentation/bloc/voice_assistant_state.dart';
import 'session_token_tracker.dart';
import 'voice_assistant_service.dart';
import 'voice_logger.dart';

class VoiceAssistantController {
  final VoiceAssistantService service;
  final AgenticAIService agenticAIService;
  final VoiceConversationLogger logger;
  final SessionTokenTracker tokenTracker;

  final ValueNotifier<VoiceAssistantStatus> statusNotifier = ValueNotifier(
    VoiceAssistantStatus.idle,
  );

  bool _isStopping = false;
  bool _isClosingSession = false;
  Completer<void>? _responseDoneCompleter;

  VoiceAssistantController({
    required this.service,
    required this.agenticAIService,
    required this.logger,
    required this.tokenTracker,
  });

  bool get isBusy => service.isConnecting || _isStopping;
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

    return service.connect(
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
      await service.disconnect();
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
    await service.sendFunctionResult(result);
  }

  Future<void> requestAssistantResponse(String instructions) async {
    await service.requestAssistantResponse(instructions);
  }

  Future<void> setMicrophoneMuted({required bool isMuted}) async {
    await service.setMicrophoneMuted(isMuted: isMuted);
  }

  void resetMemory() {
    agenticAIService.reset();
    logger.reset();
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
