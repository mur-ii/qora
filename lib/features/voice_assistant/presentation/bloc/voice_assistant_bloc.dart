import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/alpha_test_logger.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/services/agentic_ai_service.dart';
import '../../domain/entities/function_call_entity.dart';
import '../../domain/usecases/create_session_usecase.dart';
import '../../domain/usecases/disconnect_usecase.dart';
import '../../domain/usecases/initialize_webrtc_usecase.dart';
import '../../domain/usecases/request_assistant_response_usecase.dart';
import '../../domain/usecases/send_function_result_usecase.dart';
import '../../domain/usecases/set_microphone_muted_usecase.dart';
import 'voice_assistant_event.dart';
import 'voice_assistant_state.dart';

class VoiceAssistantBloc
    extends Bloc<VoiceAssistantEvent, VoiceAssistantState> {
  final CreateSessionUseCase createSessionUseCase;
  final InitializeWebRTCUseCase initializeWebRTCUseCase;
  final RequestAssistantResponseUseCase requestAssistantResponseUseCase;
  final SendFunctionResultUseCase sendFunctionResultUseCase;
  final DisconnectUseCase disconnectUseCase;
  final SetMicrophoneMutedUseCase setMicrophoneMutedUseCase;
  final AgenticAIService agenticAIService;
  final Map<String, StringBuffer> _functionArgBuffers = {};
  final Map<String, String> _functionArgNames = {};
  final AlphaTestLogger _logger = AlphaTestLogger.instance;
  final Map<String, DateTime> _functionStartTimes = {};
  Stopwatch? _sessionCreateStopwatch;
  Stopwatch? _webrtcInitStopwatch;
  DateTime? _lastUserTranscriptAt;

  String _mapIntent(String functionName) {
    switch (functionName) {
      case 'search_hotels':
        return 'search_hotel';
      case 'get_hotel_details':
        return 'view_hotel_detail';
      case 'select_room':
        return 'select_room';
      case 'check_availability':
        return 'check_availability';
      case 'get_pricing':
        return 'get_pricing';
      case 'create_booking':
        return 'create_booking';
      case 'confirm_booking':
        return 'confirm_booking';
      case 'navigate_to_screen':
        return 'navigate';
      case 'update_booking_step':
        return 'update_booking_step';
      default:
        return functionName;
    }
  }

  VoiceAssistantBloc({
    required this.createSessionUseCase,
    required this.initializeWebRTCUseCase,
    required this.requestAssistantResponseUseCase,
    required this.sendFunctionResultUseCase,
    required this.disconnectUseCase,
    required this.setMicrophoneMutedUseCase,
    required this.agenticAIService,
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
      emit(
        state.copyWith(
          connectionStatus: VoiceConnectionStatus.connecting,
          error: null,
        ),
      );

      // Step 1: Create session
      AppLogger.info('VoiceAssistant', 'Starting voice assistant session');
      _sessionCreateStopwatch = Stopwatch()..start();
      final session = await createSessionUseCase.call(
        model: event.model ?? 'gpt-realtime-mini-2025-12-15',
        voice: event.voice ?? 'verse',
        tools: agenticAIService.getFunctionDefinitions(),
        instructions: agenticAIService.getSystemInstructions(),
      );
      _sessionCreateStopwatch?.stop();
      if (_sessionCreateStopwatch != null) {
        _logger.logRealtimeMetric(
          'realtime_session_create_ms',
          _sessionCreateStopwatch!.elapsedMilliseconds,
        );
      }

      // Step 2: Initialize WebRTC
      _webrtcInitStopwatch = Stopwatch()..start();
      await initializeWebRTCUseCase.call(
        clientSecret: session.clientSecret,
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
          connectionStatus: VoiceConnectionStatus.failed,
          error: 'Failed to start: $e',
        ),
      );
    }
  }

  Future<void> _onStopVoiceAssistant(
    StopVoiceAssistant event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      await disconnectUseCase.call();

      emit(
        const VoiceAssistantState(
          connectionStatus: VoiceConnectionStatus.disconnected,
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
      emit(state.copyWith(error: 'Failed to stop: $e'));
    }
  }

  Future<void> _onMuteVoiceAssistant(
    MuteVoiceAssistant event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      await setMicrophoneMutedUseCase.call(isMuted: true);
      emit(state.copyWith(isMuted: true));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to mute: $e'));
    }
  }

  Future<void> _onUnmuteVoiceAssistant(
    UnmuteVoiceAssistant event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      await setMicrophoneMutedUseCase.call(isMuted: false);
      emit(state.copyWith(isMuted: false));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to unmute: $e'));
    }
  }

  Future<void> _onToggleVoiceAssistantMute(
    ToggleVoiceAssistantMute event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      final nextMuted = !state.isMuted;
      await setMicrophoneMutedUseCase.call(isMuted: nextMuted);
      emit(state.copyWith(isMuted: nextMuted));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to toggle mute: $e'));
    }
  }

  Future<void> _onTranscriptReceived(
    TranscriptReceived event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    if (event.isUser) {
      _lastUserTranscriptAt = DateTime.now();
    } else if (_lastUserTranscriptAt != null) {
      final deltaMs = DateTime.now()
          .difference(_lastUserTranscriptAt!)
          .inMilliseconds;
      _logger.logRealtimeMetric('audio_response_latency_ms', deltaMs);
    }

    _logger.logConversationTurn(
      isUser: event.isUser,
      text: event.transcript,
      intent: event.isUser ? null : null,
    );

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

      _functionStartTimes[event.callId] = DateTime.now();
      _logger.logIntent(intent: _mapIntent(event.name), source: 'function');

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

      final startedAt = _functionStartTimes.remove(event.callId);
      if (startedAt != null) {
        _logger.logFunctionCall(
          name: event.name,
          arguments: event.arguments,
          durationMs: DateTime.now().difference(startedAt).inMilliseconds,
          success: true,
        );
      }

      // Send result back to OpenAI
      await sendFunctionResultUseCase.call(result);

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
      final startedAt = _functionStartTimes.remove(event.callId);
      if (startedAt != null) {
        _logger.logFunctionCall(
          name: event.name,
          arguments: event.arguments,
          durationMs: DateTime.now().difference(startedAt).inMilliseconds,
          success: false,
          error: e.toString(),
        );
      }
      _logger.logError(type: 'function_call', message: e.toString());
      emit(state.copyWith(isProcessing: false, error: 'Function error: $e'));
    }
  }

  Future<void> _onAgentEventReceived(
    AgentEventReceived event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    // Handle specific events
    final eventType = event.event['type'] as String?;

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

      try {
        final parsed = jsonDecode(buffer.toString());
        if (parsed is Map<String, dynamic>) {
          agenticAIService.previewUserConstraints(parsed);
          emit(state.copyWith(agentState: agenticAIService.agentState));
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
      return;
    }

    if (eventType == 'response.done') {
      final response = event.event['response'] as Map<String, dynamic>?;
      final usage = response?['usage'] as Map<String, dynamic>?;
      final responseId = response?['id']?.toString();
      if (usage != null) {
        final inputTokens = usage['input_tokens'] as int? ?? 0;
        final outputTokens = usage['output_tokens'] as int? ?? 0;
        _logger.recordTokenUsage(
          inputTokens: inputTokens,
          outputTokens: outputTokens,
          responseId: responseId,
        );
      }
      return;
    }

    if (eventType == 'error') {
      final error = event.event['error'];
      _logger.logError(type: 'openai_realtime', message: error?.toString());
      return;
    }
  }

  Future<void> _onConnectionStateChanged(
    ConnectionStateChanged event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    VoiceConnectionStatus status;

    switch (event.state) {
      case 'connected':
        status = VoiceConnectionStatus.connected;
        break;
      case 'connecting':
        status = VoiceConnectionStatus.connecting;
        break;
      case 'failed':
        status = VoiceConnectionStatus.failed;
        break;
      default:
        status = VoiceConnectionStatus.disconnected;
    }

    emit(
      state.copyWith(
        connectionStatus: status,
        isMuted: status == VoiceConnectionStatus.disconnected
            ? false
            : state.isMuted,
      ),
    );
    if (status == VoiceConnectionStatus.connected) {
      if (_webrtcInitStopwatch != null && _webrtcInitStopwatch!.isRunning) {
        _webrtcInitStopwatch!.stop();
        _logger.logRealtimeMetric(
          'webrtc_connect_ms',
          _webrtcInitStopwatch!.elapsedMilliseconds,
        );
      }
      AppLogger.info('VoiceAssistant', 'Connection state: connected');
    } else if (status == VoiceConnectionStatus.failed) {
      AppLogger.warn('VoiceAssistant', 'Connection state: failed');
    } else if (status == VoiceConnectionStatus.disconnected) {
      AppLogger.warn('VoiceAssistant', 'Connection state: disconnected');
    }
  }

  Future<void> _onRequestAssistantResponse(
    RequestAssistantResponse event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    try {
      await requestAssistantResponseUseCase.call(event.instructions);
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
