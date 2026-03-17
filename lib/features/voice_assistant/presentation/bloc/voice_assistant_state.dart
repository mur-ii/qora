import 'package:equatable/equatable.dart';

import '../../domain/entities/agent_state_entity.dart';
import '../../domain/entities/voice_assistant_status.dart';

export '../../domain/entities/voice_assistant_status.dart';

class VoiceAssistantState extends Equatable {
  static const Object _unset = Object();

  final VoiceAssistantStatus status;
  final List<ConversationMessage> messages;
  final AgentStateEntity agentState;
  final String? currentSessionId;
  final double sessionEstimatedCostUsd;
  final int totalLoggedTurns;
  final int totalLoggedTokens;
  final String? error;
  final bool isProcessing;
  final bool isMuted;

  const VoiceAssistantState({
    this.status = VoiceAssistantStatus.idle,
    this.messages = const [],
    this.agentState = const AgentStateEntity(),
    this.currentSessionId,
    this.sessionEstimatedCostUsd = 0,
    this.totalLoggedTurns = 0,
    this.totalLoggedTokens = 0,
    this.error,
    this.isProcessing = false,
    this.isMuted = false,
  });

  VoiceAssistantState copyWith({
    VoiceAssistantStatus? status,
    List<ConversationMessage>? messages,
    AgentStateEntity? agentState,
    Object? currentSessionId = _unset,
    double? sessionEstimatedCostUsd,
    int? totalLoggedTurns,
    int? totalLoggedTokens,
    Object? error = _unset,
    bool? isProcessing,
    bool? isMuted,
  }) {
    return VoiceAssistantState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      agentState: agentState ?? this.agentState,
      currentSessionId: identical(currentSessionId, _unset)
          ? this.currentSessionId
          : currentSessionId as String?,
      sessionEstimatedCostUsd:
          sessionEstimatedCostUsd ?? this.sessionEstimatedCostUsd,
      totalLoggedTurns: totalLoggedTurns ?? this.totalLoggedTurns,
      totalLoggedTokens: totalLoggedTokens ?? this.totalLoggedTokens,
      error: identical(error, _unset) ? this.error : error as String?,
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
    currentSessionId,
    sessionEstimatedCostUsd,
    totalLoggedTurns,
    totalLoggedTokens,
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
