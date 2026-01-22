import 'package:equatable/equatable.dart';

import '../../domain/entities/agent_state_entity.dart';

enum VoiceConnectionStatus { disconnected, connecting, connected, failed }

class VoiceAssistantState extends Equatable {
  final VoiceConnectionStatus connectionStatus;
  final List<ConversationMessage> messages;
  final AgentStateEntity agentState;
  final String? error;
  final bool isProcessing;

  const VoiceAssistantState({
    this.connectionStatus = VoiceConnectionStatus.disconnected,
    this.messages = const [],
    this.agentState = const AgentStateEntity(),
    this.error,
    this.isProcessing = false,
  });

  VoiceAssistantState copyWith({
    VoiceConnectionStatus? connectionStatus,
    List<ConversationMessage>? messages,
    AgentStateEntity? agentState,
    String? error,
    bool? isProcessing,
  }) {
    return VoiceAssistantState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      messages: messages ?? this.messages,
      agentState: agentState ?? this.agentState,
      error: error,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }

  @override
  List<Object?> get props => [
    connectionStatus,
    messages,
    agentState,
    error,
    isProcessing,
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
