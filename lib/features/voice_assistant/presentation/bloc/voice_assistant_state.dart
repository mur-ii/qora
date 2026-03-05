import 'package:equatable/equatable.dart';

import '../../domain/entities/agent_state_entity.dart';

enum VoiceAssistantStatus {
  idle,
  connecting,
  connected,
  listening,
  speaking,
  disconnecting,
}

class VoiceAssistantState extends Equatable {
  final VoiceAssistantStatus status;
  final List<ConversationMessage> messages;
  final AgentStateEntity agentState;
  final String? error;
  final bool isProcessing;
  final bool isMuted;

  const VoiceAssistantState({
    this.status = VoiceAssistantStatus.idle,
    this.messages = const [],
    this.agentState = const AgentStateEntity(),
    this.error,
    this.isProcessing = false,
    this.isMuted = false,
  });

  VoiceAssistantState copyWith({
    VoiceAssistantStatus? status,
    List<ConversationMessage>? messages,
    AgentStateEntity? agentState,
    String? error,
    bool? isProcessing,
    bool? isMuted,
  }) {
    return VoiceAssistantState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      agentState: agentState ?? this.agentState,
      error: error,
      isProcessing: isProcessing ?? this.isProcessing,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  bool get isActive =>
      status == VoiceAssistantStatus.connected ||
      status == VoiceAssistantStatus.listening ||
      status == VoiceAssistantStatus.speaking;

  @override
  List<Object?> get props => [
    status,
    messages,
    agentState,
    error,
    isProcessing,
    isMuted,
  ];
}

class ConversationMessage extends Equatable {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? functionName;

  const ConversationMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.functionName,
  });

  @override
  List<Object?> get props => [text, isUser, timestamp, functionName];
}
