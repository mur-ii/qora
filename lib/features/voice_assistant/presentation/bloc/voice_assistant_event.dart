import 'package:equatable/equatable.dart';

abstract class VoiceAssistantEvent extends Equatable {
  const VoiceAssistantEvent();

  @override
  List<Object?> get props => [];
}

/// Start voice assistant connection
class StartVoiceAssistant extends VoiceAssistantEvent {
  final String? model;
  final String? voice;

  const StartVoiceAssistant({this.model, this.voice});

  @override
  List<Object?> get props => [model, voice];
}

/// Stop voice assistant connection
class StopVoiceAssistant extends VoiceAssistantEvent {
  const StopVoiceAssistant();
}

/// Toggle voice assistant mute state
class ToggleVoiceAssistantMute extends VoiceAssistantEvent {
  const ToggleVoiceAssistantMute();
}

/// Handle transcript received from AI
class TranscriptReceived extends VoiceAssistantEvent {
  final String transcript;
  final bool isUser;

  const TranscriptReceived({required this.transcript, this.isUser = true});

  @override
  List<Object?> get props => [transcript, isUser];
}

/// Handle function call from AI
class FunctionCallReceived extends VoiceAssistantEvent {
  final String callId;
  final String name;
  final Map<String, dynamic> arguments;

  const FunctionCallReceived({
    required this.callId,
    required this.name,
    required this.arguments,
  });

  @override
  List<Object?> get props => [callId, name, arguments];
}

/// Handle agent event
class AgentEventReceived extends VoiceAssistantEvent {
  final Map<String, dynamic> event;

  const AgentEventReceived({required this.event});

  @override
  List<Object?> get props => [event];
}

/// Connection state changed
class ConnectionStateChanged extends VoiceAssistantEvent {
  final String state;

  const ConnectionStateChanged({required this.state});

  @override
  List<Object?> get props => [state];
}

/// Request assistant to speak a prompt
class RequestAssistantResponse extends VoiceAssistantEvent {
  final String instructions;

  const RequestAssistantResponse({required this.instructions});

  @override
  List<Object?> get props => [instructions];
}

/// Ask assistant to deliver final message then close the session.
class CompleteVoiceSessionWithMessage extends VoiceAssistantEvent {
  final String message;
  final String reason;

  const CompleteVoiceSessionWithMessage({
    required this.message,
    this.reason = 'voice_session_completed',
  });

  @override
  List<Object?> get props => [message, reason];
}

/// Internal event to sync persisted conversation metrics to UI state
class ConversationMetricsUpdated extends VoiceAssistantEvent {
  final double sessionCostUsd;
  final int totalLoggedTurns;
  final int totalLoggedTokens;

  const ConversationMetricsUpdated({
    required this.sessionCostUsd,
    required this.totalLoggedTurns,
    required this.totalLoggedTokens,
  });

  @override
  List<Object?> get props => [
    sessionCostUsd,
    totalLoggedTurns,
    totalLoggedTokens,
  ];
}
