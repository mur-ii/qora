import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/agentic_ai_service.dart';
import '../../domain/entities/function_call_entity.dart';
import '../../domain/usecases/create_session_usecase.dart';
import '../../domain/usecases/disconnect_usecase.dart';
import '../../domain/usecases/initialize_webrtc_usecase.dart';
import '../../domain/usecases/send_function_result_usecase.dart';
import 'voice_assistant_event.dart';
import 'voice_assistant_state.dart';

class VoiceAssistantBloc
    extends Bloc<VoiceAssistantEvent, VoiceAssistantState> {
  final CreateSessionUseCase createSessionUseCase;
  final InitializeWebRTCUseCase initializeWebRTCUseCase;
  final SendFunctionResultUseCase sendFunctionResultUseCase;
  final DisconnectUseCase disconnectUseCase;
  final AgenticAIService agenticAIService;

  VoiceAssistantBloc({
    required this.createSessionUseCase,
    required this.initializeWebRTCUseCase,
    required this.sendFunctionResultUseCase,
    required this.disconnectUseCase,
    required this.agenticAIService,
  }) : super(const VoiceAssistantState()) {
    on<StartVoiceAssistant>(_onStartVoiceAssistant);
    on<StopVoiceAssistant>(_onStopVoiceAssistant);
    on<TranscriptReceived>(_onTranscriptReceived);
    on<FunctionCallReceived>(_onFunctionCallReceived);
    on<AgentEventReceived>(_onAgentEventReceived);
    on<ConnectionStateChanged>(_onConnectionStateChanged);
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
      print('Creating OpenAI Realtime session...');
      final session = await createSessionUseCase.call(
        model: event.model ?? 'gpt-realtime-mini-2025-12-15',
        voice: event.voice ?? 'verse',
        tools: agenticAIService.getFunctionDefinitions(),
        instructions: agenticAIService.getSystemInstructions(),
      );

      print('Session created: ${session.id}');

      // Step 2: Initialize WebRTC
      print('Initializing WebRTC...');
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

      print('Voice assistant started successfully');

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
    } catch (e) {
      print('Error starting voice assistant: $e');
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

      print('Voice assistant stopped');
    } catch (e) {
      print('Error stopping voice assistant: $e');
      emit(state.copyWith(error: 'Failed to stop: $e'));
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
      print('Executing function: ${event.name}');
      final functionCall = FunctionCallEntity(
        callId: event.callId,
        name: event.name,
        arguments: event.arguments,
      );

      final result = await agenticAIService.executeFunction(functionCall);

      // Send result back to OpenAI
      await sendFunctionResultUseCase.call(result);

      // Update agent state
      emit(
        state.copyWith(
          agentState: agenticAIService.agentState,
          isProcessing: false,
        ),
      );

      print('Function executed successfully: ${event.name}');
    } catch (e) {
      print('Error executing function: $e');
      emit(state.copyWith(isProcessing: false, error: 'Function error: $e'));
    }
  }

  Future<void> _onAgentEventReceived(
    AgentEventReceived event,
    Emitter<VoiceAssistantState> emit,
  ) async {
    // Handle agent events (logging, state updates, etc.)
    print('Agent event: ${event.event['type']}');

    // Handle specific events
    final eventType = event.event['type'] as String?;

    if (eventType == 'response.audio_transcript.done') {
      final transcript = event.event['transcript'] as String?;
      if (transcript != null && transcript.isNotEmpty) {
        add(TranscriptReceived(transcript: transcript, isUser: false));
      }
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

    emit(state.copyWith(connectionStatus: status));
    print('Connection state changed: ${event.state}');
  }
}
