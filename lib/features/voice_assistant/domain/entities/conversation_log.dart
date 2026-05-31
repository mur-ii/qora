import 'package:equatable/equatable.dart';

class ConversationLog extends Equatable {
  final int? id;
  final String sessionId;
  final DateTime timestamp;
  final String userMessage;
  final String assistantMessage;
  final int inputTokens;
  final int outputTokens;
  final int cachedTokens;
  final int totalTokens;
  final double estimatedCostUsd;

  const ConversationLog({
    this.id,
    required this.sessionId,
    required this.timestamp,
    required this.userMessage,
    required this.assistantMessage,
    required this.inputTokens,
    required this.outputTokens,
    required this.cachedTokens,
    required this.totalTokens,
    required this.estimatedCostUsd,
  });

  ConversationLog copyWith({
    int? id,
    String? sessionId,
    DateTime? timestamp,
    String? userMessage,
    String? assistantMessage,
    int? inputTokens,
    int? outputTokens,
    int? cachedTokens,
    int? totalTokens,
    double? estimatedCostUsd,
  }) {
    return ConversationLog(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      userMessage: userMessage ?? this.userMessage,
      assistantMessage: assistantMessage ?? this.assistantMessage,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      cachedTokens: cachedTokens ?? this.cachedTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      estimatedCostUsd: estimatedCostUsd ?? this.estimatedCostUsd,
    );
  }

  @override
  List<Object?> get props => [
    id,
    sessionId,
    timestamp,
    userMessage,
    assistantMessage,
    inputTokens,
    outputTokens,
    cachedTokens,
    totalTokens,
    estimatedCostUsd,
  ];
}
