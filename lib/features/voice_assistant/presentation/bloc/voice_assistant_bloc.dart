import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/agent_state_entity.dart';
import '../../domain/entities/function_call_entity.dart';
import '../../domain/usecases/agentic_ai_usecase.dart';
import '../../domain/usecases/voice_session_usecase.dart';
import 'conversation_bloc.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';
import 'voice_assistant_event.dart';
import 'voice_assistant_state.dart';

class VoiceAssistantBloc
    extends Bloc<VoiceAssistantEvent, VoiceAssistantState> {
  final VoiceSessionUseCase voiceSessionUseCase;
  final AgenticAiUseCase agenticAiUseCase;
  final ConversationBloc conversationBloc;
  final String? defaultModel;
  final Map<String, StringBuffer> _functionArgBuffers = {};
  final Map<String, String> _functionArgNames = {};
  static const Duration _speakingDeltaThrottle = Duration(milliseconds: 160);
  static const Duration _functionArgsDeltaThrottle = Duration(
    milliseconds: 250,
  );
  StreamSubscription<ConversationState>? _conversationSubscription;
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
    required this.voiceSessionUseCase,
    required this.agenticAiUseCase,
    required this.conversationBloc,
    this.defaultModel,
  }) : super(const VoiceAssistantState()) {
    _conversationSubscription = conversationBloc.stream.listen((convState) {
      if (isClosed) return;
      final totalTokens = convState.logs.fold<int>(
        0,
        (sum, log) => sum + log.totalTokens,
      );
      final totalTurns = convState.logs.fold<int>(
        0,
        (sum, log) =>
            sum +
            (log.userMessage.trim().isNotEmpty ? 1 : 0) +
            (log.assistantMessage.trim().isNotEmpty ? 1 : 0),
      );
      add(
        ConversationMetricsUpdated(
          sessionCostUsd: convState.sessionCostUsd,
          totalLoggedTurns: totalTurns,
          totalLoggedTokens: totalTokens,
        ),
      );
    });

    on<StartVoiceAssistant>(_onStartVoiceAssistant);
    on<StopVoiceAssistant>(_onStopVoiceAssistant);
    on<ToggleVoiceAssistantMute>(_onToggleVoiceAssistantMute);
    on<TranscriptReceived>(_onTranscriptReceived);
    on<FunctionCallReceived>(_onFunctionCallReceived);
    on<AgentEventReceived>(_onAgentEventReceived);
    on<ConnectionStateChanged>(_onConnectionStateChanged);
    on<RequestAssistantResponse>(_onRequestAssistantResponse);
    on<SyncVoiceSearchConstraints>(_onSyncVoiceSearchConstraints);
    on<CompleteVoiceSessionWithMessage>(_onCompleteVoiceSessionWithMessage);
    on<ConversationMetricsUpdated>(_onConversationMetricsUpdated);
  }

  Future<void> _onStartVoiceAssistant(
    StartVoiceAssistant event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      if (state.status != VoiceAssistantStatus.idle ||
          voiceSessionUseCase.isBusy) {
        return;
      }

      final sessionId = _buildSessionId();

      emit(
        state.copyWith(
          status: VoiceAssistantStatus.connecting,
          messages: const [],
          agentState: const AgentStateEntity(),
          currentSessionId: sessionId,
          sessionEstimatedCostUsd: 0,
          totalLoggedTurns: 0,
          totalLoggedTokens: 0,
          isProcessing: false,
          isMuted: false,
          error: null,
        ),
      );

      _refreshConversationMetrics(sessionId);

      voiceSessionUseCase.updateStatus(VoiceAssistantStatus.connecting);

      _functionArgBuffers.clear();
      _functionArgNames.clear();

      // Step 1: Create session
      AppLogger.info('VoiceAssistant', 'Starting voice assistant session');
      await voiceSessionUseCase.start(
        model: event.model ?? defaultModel ?? 'gpt-realtime-mini-2025-12-15',
        voice: event.voice ?? 'verse',
        sessionId: sessionId,
        tools: agenticAiUseCase.getFunctionDefinitions(),
        instructions: agenticAiUseCase.getSystemInstructions(),
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
      voiceSessionUseCase.updateStatus(VoiceAssistantStatus.idle);
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

      await voiceSessionUseCase.stop();

      _refreshConversationMetrics(state.currentSessionId);

      emit(
        state.copyWith(
          status: VoiceAssistantStatus.idle,
          messages: const [],
          agentState: const AgentStateEntity(),
          currentSessionId: null,
          sessionEstimatedCostUsd: 0,
          totalLoggedTurns: 0,
          totalLoggedTokens: 0,
          isProcessing: false,
          isMuted: false,
          error: null,
        ),
      );

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
          currentSessionId: null,
          error: 'Failed to stop: ${_formatError(e)}',
        ),
      );
      voiceSessionUseCase.updateStatus(VoiceAssistantStatus.idle);
    }
  }

  Future<void> _onCompleteVoiceSessionWithMessage(
    CompleteVoiceSessionWithMessage event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      if (state.status == VoiceAssistantStatus.idle ||
          state.status == VoiceAssistantStatus.disconnecting) {
        return;
      }

      emit(
        state.copyWith(status: VoiceAssistantStatus.disconnecting, error: null),
      );

      _functionArgBuffers.clear();
      _functionArgNames.clear();

      await voiceSessionUseCase.endSessionWithMessage(event.message);

      _refreshConversationMetrics(state.currentSessionId);

      emit(
        state.copyWith(
          status: VoiceAssistantStatus.idle,
          messages: const [],
          agentState: const AgentStateEntity(),
          currentSessionId: null,
          sessionEstimatedCostUsd: 0,
          totalLoggedTurns: 0,
          totalLoggedTokens: 0,
          isProcessing: false,
          isMuted: false,
          error: null,
        ),
      );

      AppLogger.info('VoiceAssistant', 'Voice assistant completed and stopped');
    } catch (e, stackTrace) {
      AppLogger.error(
        'VoiceAssistant',
        'Error completing voice assistant session',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          status: VoiceAssistantStatus.idle,
          currentSessionId: null,
          error: 'Failed to complete session: ${_formatError(e)}',
        ),
      );
      voiceSessionUseCase.updateStatus(VoiceAssistantStatus.idle);
    }
  }

  Future<void> _onToggleVoiceAssistantMute(
    ToggleVoiceAssistantMute event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      final nextMuted = !state.isMuted;
      await voiceSessionUseCase.setMicrophoneMuted(isMuted: nextMuted);
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
        agenticAiUseCase.previewUserConstraints(event.arguments);
        emit(
          state.copyWith(
            agentState: agenticAiUseCase.agentState,
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

      final result = await agenticAiUseCase.executeFunction(functionCall);

      // Send result back to OpenAI
      await voiceSessionUseCase.sendFunctionResult(result);

      // Update agent state
      emit(
        state.copyWith(
          agentState: agenticAiUseCase.agentState,
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

    voiceSessionUseCase.handleAgentEvent(event.event);

    if (eventType == 'input_audio_buffer.speech_started') {
      emit(state.copyWith(status: VoiceAssistantStatus.listening));
      voiceSessionUseCase.updateStatus(VoiceAssistantStatus.listening);
      return;
    }

    if (eventType == 'input_audio_buffer.speech_stopped') {
      emit(state.copyWith(status: VoiceAssistantStatus.connected));
      voiceSessionUseCase.updateStatus(VoiceAssistantStatus.connected);
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
        voiceSessionUseCase.updateStatus(VoiceAssistantStatus.speaking);
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
          agenticAiUseCase.previewUserConstraints(parsed);
          final nextAgentState = agenticAiUseCase.agentState;
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
      voiceSessionUseCase.updateStatus(VoiceAssistantStatus.connected);
      return;
    }

    if (eventType == 'response.done') {
      _refreshConversationMetrics(state.currentSessionId);
      emit(state.copyWith(status: VoiceAssistantStatus.connected));
      voiceSessionUseCase.updateStatus(VoiceAssistantStatus.connected);
      return;
    }

    if (eventType == 'error') {
      emit(
        state.copyWith(
          status: VoiceAssistantStatus.idle,
          error: 'Realtime error received. Please retry.',
        ),
      );
      voiceSessionUseCase.updateStatus(VoiceAssistantStatus.idle);
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
    voiceSessionUseCase.updateStatus(status);
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
      await voiceSessionUseCase.requestAssistantResponse(event.instructions);
    } catch (e, stackTrace) {
      AppLogger.error(
        'VoiceAssistant',
        'Error requesting assistant response',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _onSyncVoiceSearchConstraints(
    SyncVoiceSearchConstraints event,
    Emitter<VoiceAssistantState> emit,
  ) {
    final args = <String, dynamic>{
      'location': event.location,
      'check_in': event.checkIn,
      'check_out': event.checkOut,
      'guests': event.guests,
      'rooms': event.rooms,
    };

    agenticAiUseCase.previewUserConstraints(args);
    final nextAgentState = agenticAiUseCase.agentState;

    if (nextAgentState != state.agentState) {
      emit(state.copyWith(agentState: nextAgentState));
    }
  }

  Future<void> _onConversationMetricsUpdated(
    ConversationMetricsUpdated event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    emit(
      state.copyWith(
        sessionEstimatedCostUsd: event.sessionCostUsd,
        totalLoggedTurns: event.totalLoggedTurns,
        totalLoggedTokens: event.totalLoggedTokens,
      ),
    );
  }

  void _refreshConversationMetrics(String? sessionId) {
    if (sessionId == null || sessionId.isEmpty) return;
    conversationBloc.add(
      LoadSessionConversationRequested(sessionId: sessionId),
    );
    conversationBloc.add(CalculateSessionCostRequested(sessionId: sessionId));
  }

  String _buildSessionId() {
    final now = DateTime.now().toUtc();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    return 'booking_$year$month${day}_$hour$minute$second';
  }

  @override
  Future<void> close() async {
    await _conversationSubscription?.cancel();
    return super.close();
  }
}
