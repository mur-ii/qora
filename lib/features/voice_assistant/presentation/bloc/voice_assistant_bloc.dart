import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_logger.dart';
import '../../data/services/agentic_ai_service.dart';
import '../../domain/entities/agent_state_entity.dart';
import '../../domain/entities/function_call_entity.dart';
import '../../voice_assistant_controller.dart';
import 'voice_assistant_event.dart';
import 'voice_assistant_state.dart';

class VoiceAssistantBloc
    extends Bloc<VoiceAssistantEvent, VoiceAssistantState> {
  final VoiceAssistantController voiceAssistantController;
  final AgenticAIService agenticAIService;
  final String? defaultModel;
  final Map<String, StringBuffer> _functionArgBuffers = {};
  final Map<String, String> _functionArgNames = {};
  static const Duration _speakingDeltaThrottle = Duration(milliseconds: 160);
  static const Duration _functionArgsDeltaThrottle = Duration(
    milliseconds: 250,
  );
  DateTime? _lastSpeakingDeltaEmit;
  DateTime? _lastFunctionArgsDeltaEmit;

  String _formatError(Object error) {
    final raw = error.toString().replaceAll('Exception: ', '').trim();
    final normalized = raw.toLowerCase();

    if (normalized.contains('permission')) {
      return 'Microphone permission denied';
    }
    if (normalized.contains('timeout')) {
      return 'Network timeout. Please try again.';
    }
    if (normalized.contains('failed to create session')) {
      return 'Failed to create session. Please try again.';
    }
    if (normalized.contains('failed to exchange sdp')) {
      return 'WebRTC negotiation failed. Please retry.';
    }
    return raw;
  }

  VoiceAssistantBloc({
    required this.voiceAssistantController,
    required this.agenticAIService,
    this.defaultModel,
  }) : super(const VoiceAssistantState()) {
    on<StartVoiceAssistant>(_onStartVoiceAssistant);
    on<StopVoiceAssistant>(_onStopVoiceAssistant);
    on<MuteVoiceAssistant>(_onMuteVoiceAssistant);
    on<UnmuteVoiceAssistant>(_onUnmuteVoiceAssistant);
    on<ToggleVoiceAssistantMute>(_onToggleVoiceAssistantMute);
    on<TranscriptReceived>(_onTranscriptReceived);
    on<FunctionCallReceived>(_onFunctionCallReceived);
    on<AgentEventReceived>(_onAgentEventReceived);
    on<ConnectionStateChanged>(_onConnectionStateChanged);
    on<RequestAssistantResponse>(_onRequestAssistantResponse);
  }

  Future<void> _onStartVoiceAssistant(
    StartVoiceAssistant event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      if (state.status != VoiceAssistantStatus.idle ||
          voiceAssistantController.isBusy) {
        return;
      }

      emit(
        state.copyWith(
          status: VoiceAssistantStatus.connecting,
          messages: const [],
          agentState: const AgentStateEntity(),
          isProcessing: false,
          isMuted: false,
          error: null,
        ),
      );

      voiceAssistantController.updateStatus(VoiceAssistantStatus.connecting);

      _functionArgBuffers.clear();
      _functionArgNames.clear();

      // Step 1: Create session
      AppLogger.info('VoiceAssistant', 'Starting voice assistant session');
      await voiceAssistantController.start(
        model: event.model ?? defaultModel ?? 'gpt-realtime-mini-2025-12-15',
        voice: event.voice ?? 'verse',
        tools: agenticAIService.getFunctionDefinitions(),
        instructions: agenticAIService.getSystemInstructions(),
        onConnectionStateChange: (connectionState) {
          add(ConnectionStateChanged(state: connectionState.name));
        },
        onTranscript: (transcript) {
          add(TranscriptReceived(transcript: transcript, isUser: true));
        },
        onFunctionCall: (functionCall) {
          add(
            FunctionCallReceived(
              callId: functionCall.callId,
              name: functionCall.name,
              arguments: functionCall.arguments,
            ),
          );
        },
        onAgentEvent: (event) {
          add(AgentEventReceived(event: event));
        },
      );

      AppLogger.info('VoiceAssistant', 'Voice assistant started');

      // Add welcome message
      emit(
        state.copyWith(
          messages: [
            ConversationMessage(
              text:
                  'Voice assistant connected. How can I help you book a hotel?',
              isUser: false,
              timestamp: DateTime.now(),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'VoiceAssistant',
        'Error starting voice assistant',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          status: VoiceAssistantStatus.idle,
          error: 'Failed to start: ${_formatError(e)}',
        ),
      );
      voiceAssistantController.updateStatus(VoiceAssistantStatus.idle);
    }
  }

  Future<void> _onStopVoiceAssistant(
    StopVoiceAssistant event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      if (state.status == VoiceAssistantStatus.idle ||
          state.status == VoiceAssistantStatus.disconnecting) {
        return;
      }

      emit(state.copyWith(status: VoiceAssistantStatus.disconnecting));

      _functionArgBuffers.clear();
      _functionArgNames.clear();

      await voiceAssistantController.stop();

      emit(const VoiceAssistantState(status: VoiceAssistantStatus.idle));

      voiceAssistantController.updateStatus(VoiceAssistantStatus.idle);

      AppLogger.info('VoiceAssistant', 'Voice assistant stopped');
    } catch (e, stackTrace) {
      AppLogger.error(
        'VoiceAssistant',
        'Error stopping voice assistant',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          status: VoiceAssistantStatus.idle,
          error: 'Failed to stop: ${_formatError(e)}',
        ),
      );
      voiceAssistantController.updateStatus(VoiceAssistantStatus.idle);
    }
  }

  Future<void> _onMuteVoiceAssistant(
    MuteVoiceAssistant event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      await voiceAssistantController.setMicrophoneMuted(isMuted: true);
      emit(state.copyWith(isMuted: true));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to mute: ${_formatError(e)}'));
    }
  }

  Future<void> _onUnmuteVoiceAssistant(
    UnmuteVoiceAssistant event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      await voiceAssistantController.setMicrophoneMuted(isMuted: false);
      emit(state.copyWith(isMuted: false));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to unmute: ${_formatError(e)}'));
    }
  }

  Future<void> _onToggleVoiceAssistantMute(
    ToggleVoiceAssistantMute event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      final nextMuted = !state.isMuted;
      await voiceAssistantController.setMicrophoneMuted(isMuted: nextMuted);
      emit(state.copyWith(isMuted: nextMuted));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to toggle mute: ${_formatError(e)}'));
    }
  }

  Future<void> _onTranscriptReceived(
    TranscriptReceived event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    final updatedMessages = List<ConversationMessage>.from(state.messages)
      ..add(
        ConversationMessage(
          text: event.transcript,
          isUser: event.isUser,
          timestamp: DateTime.now(),
        ),
      );

    emit(state.copyWith(messages: updatedMessages));
  }

  Future<void> _onFunctionCallReceived(
    FunctionCallReceived event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      emit(state.copyWith(isProcessing: true));

      _functionArgBuffers.remove(event.callId);
      _functionArgNames.remove(event.callId);

      if (event.name == 'search_hotels') {
        agenticAIService.previewUserConstraints(event.arguments);
        emit(
          state.copyWith(
            agentState: agenticAIService.agentState,
            isProcessing: true,
          ),
        );
      }

      // Add function call message
      final updatedMessages = List<ConversationMessage>.from(state.messages)
        ..add(
          ConversationMessage(
            text: 'Executing: ${event.name}...',
            isUser: false,
            timestamp: DateTime.now(),
            functionName: event.name,
          ),
        );

      emit(state.copyWith(messages: updatedMessages));

      // Execute function
      AppLogger.info('VoiceAssistant', 'Function call: ${event.name}');
      final functionCall = FunctionCallEntity(
        callId: event.callId,
        name: event.name,
        arguments: event.arguments,
      );

      final result = await agenticAIService.executeFunction(functionCall);

      // Send result back to OpenAI
      await voiceAssistantController.sendFunctionResult(result);

      // Check if automatic disconnect is required (after booking confirmation)
      final resultData = result.result;
      if (resultData is Map<String, dynamic> &&
          resultData['requires_disconnect'] == true) {
        AppLogger.info(
          'VoiceAssistant',
          'Auto-disconnect scheduled after booking confirmation',
        );
        // Schedule disconnect after a short delay to allow AI to speak final message
        Future.delayed(const Duration(seconds: 5), () {
          if (!isClosed) {
            add(const StopVoiceAssistant());
          }
        });
      }

      // Update agent state
      emit(
        state.copyWith(
          agentState: agenticAIService.agentState,
          isProcessing: false,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'VoiceAssistant',
        'Error executing function',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          isProcessing: false,
          error: 'Function error: ${_formatError(e)}',
        ),
      );
    }
  }

  Future<void> _onAgentEventReceived(
    AgentEventReceived event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    // Handle specific events
    final eventType = event.event['type'] as String?;

    voiceAssistantController.handleAgentEvent(event.event);

    if (eventType == 'input_audio_buffer.speech_started') {
      emit(state.copyWith(status: VoiceAssistantStatus.listening));
      voiceAssistantController.updateStatus(VoiceAssistantStatus.listening);
      return;
    }

    if (eventType == 'input_audio_buffer.speech_stopped') {
      emit(state.copyWith(status: VoiceAssistantStatus.connected));
      voiceAssistantController.updateStatus(VoiceAssistantStatus.connected);
      return;
    }

    if (eventType == 'response.audio_transcript.delta') {
      final now = DateTime.now();
      final canEmitSpeaking =
          state.status != VoiceAssistantStatus.speaking ||
          _lastSpeakingDeltaEmit == null ||
          now.difference(_lastSpeakingDeltaEmit!) >= _speakingDeltaThrottle;

      if (canEmitSpeaking) {
        _lastSpeakingDeltaEmit = now;
        emit(state.copyWith(status: VoiceAssistantStatus.speaking));
        voiceAssistantController.updateStatus(VoiceAssistantStatus.speaking);
      }
      return;
    }

    if (eventType == 'response.function_call_arguments.delta') {
      final callId = event.event['call_id'] as String?;
      final delta = event.event['delta'] as String?;
      final name = event.event['name'] as String?;

      if (callId == null || delta == null) return;

      final buffer = _functionArgBuffers.putIfAbsent(
        callId,
        () => StringBuffer(),
      );
      buffer.write(delta);

      if (name != null && name.isNotEmpty) {
        _functionArgNames[callId] = name;
      }

      final currentName = _functionArgNames[callId];
      if (currentName != 'search_hotels') return;

      final now = DateTime.now();
      if (_lastFunctionArgsDeltaEmit != null &&
          now.difference(_lastFunctionArgsDeltaEmit!) <
              _functionArgsDeltaThrottle) {
        return;
      }

      try {
        final parsed = jsonDecode(buffer.toString());
        if (parsed is Map<String, dynamic>) {
          _lastFunctionArgsDeltaEmit = now;
          agenticAIService.previewUserConstraints(parsed);
          final nextAgentState = agenticAIService.agentState;
          if (nextAgentState != state.agentState) {
            emit(state.copyWith(agentState: nextAgentState));
          }
        }
      } catch (_) {
        // Ignore until JSON is complete.
      }
      return;
    }

    if (eventType == 'response.audio_transcript.done') {
      final transcript = event.event['transcript'] as String?;
      if (transcript != null && transcript.isNotEmpty) {
        add(TranscriptReceived(transcript: transcript, isUser: false));
      }
      emit(state.copyWith(status: VoiceAssistantStatus.connected));
      voiceAssistantController.updateStatus(VoiceAssistantStatus.connected);
      return;
    }

    if (eventType == 'response.done') {
      emit(state.copyWith(status: VoiceAssistantStatus.connected));
      voiceAssistantController.updateStatus(VoiceAssistantStatus.connected);
      return;
    }

    if (eventType == 'error') {
      emit(
        state.copyWith(
          status: VoiceAssistantStatus.idle,
          error: 'Realtime error received. Please retry.',
        ),
      );
      voiceAssistantController.updateStatus(VoiceAssistantStatus.idle);
      return;
    }
  }

  Future<void> _onConnectionStateChanged(
    ConnectionStateChanged event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    VoiceAssistantStatus status;

    switch (event.state) {
      case 'connected':
        status = VoiceAssistantStatus.connected;
        break;
      case 'connecting':
        status = VoiceAssistantStatus.connecting;
        break;
      case 'failed':
        status = VoiceAssistantStatus.idle;
        break;
      default:
        status = VoiceAssistantStatus.idle;
    }

    final isUnexpectedDisconnect =
        event.state == 'disconnected' &&
        state.status != VoiceAssistantStatus.disconnecting;

    emit(
      state.copyWith(
        status: status,
        isMuted: status == VoiceAssistantStatus.idle ? false : state.isMuted,
        error: isUnexpectedDisconnect
            ? 'Unexpected disconnection. Please try again.'
            : state.error,
      ),
    );
    voiceAssistantController.updateStatus(status);
    if (status == VoiceAssistantStatus.connected) {
      AppLogger.info('VoiceAssistant', 'Connection state: connected');
    } else if (event.state == 'failed') {
      AppLogger.warn('VoiceAssistant', 'Connection state: failed');
    } else if (status == VoiceAssistantStatus.idle) {
      AppLogger.warn('VoiceAssistant', 'Connection state: disconnected');
    }
  }

  Future<void> _onRequestAssistantResponse(
    RequestAssistantResponse event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      await voiceAssistantController.requestAssistantResponse(
        event.instructions,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'VoiceAssistant',
        'Error requesting assistant response',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
