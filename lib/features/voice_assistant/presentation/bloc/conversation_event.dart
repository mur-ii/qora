import 'package:equatable/equatable.dart';

import '../../domain/entities/conversation_log.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

class LogConversationRequested extends ConversationEvent {
  const LogConversationRequested({required this.conversationLog});

  final ConversationLog conversationLog;

  @override
  List<Object?> get props => [conversationLog];
}

class LoadSessionConversationRequested extends ConversationEvent {
  const LoadSessionConversationRequested({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

class CalculateSessionCostRequested extends ConversationEvent {
  const CalculateSessionCostRequested({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

class ClearSessionConversationRequested extends ConversationEvent {
  const ClearSessionConversationRequested({required this.sessionId});

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}
