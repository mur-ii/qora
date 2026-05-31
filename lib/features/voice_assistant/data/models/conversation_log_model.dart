import '../../domain/entities/conversation_log.dart';

class ConversationLogModel extends ConversationLog {
  const ConversationLogModel({
    super.id,
    required super.sessionId,
    required super.timestamp,
    required super.userMessage,
    required super.assistantMessage,
    required super.inputTokens,
    required super.outputTokens,
    required super.cachedTokens,
    required super.totalTokens,
    required super.estimatedCostUsd,
  });

  factory ConversationLogModel.fromEntity(ConversationLog entity) {
    return ConversationLogModel(
      id: entity.id,
      sessionId: entity.sessionId,
      timestamp: entity.timestamp,
      userMessage: entity.userMessage,
      assistantMessage: entity.assistantMessage,
      inputTokens: entity.inputTokens,
      outputTokens: entity.outputTokens,
      cachedTokens: entity.cachedTokens,
      totalTokens: entity.totalTokens,
      estimatedCostUsd: entity.estimatedCostUsd,
    );
  }

  factory ConversationLogModel.fromMap(Map<String, dynamic> map) {
    return ConversationLogModel(
      id: map['id'] as int?,
      sessionId: map['session_id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      userMessage: map['user_message'] as String,
      assistantMessage: map['assistant_message'] as String,
      inputTokens: map['input_tokens'] as int,
      outputTokens: map['output_tokens'] as int,
      cachedTokens: map['cached_tokens'] as int,
      totalTokens: map['total_tokens'] as int,
      estimatedCostUsd: (map['estimated_cost_usd'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'user_message': userMessage,
      'assistant_message': assistantMessage,
      'input_tokens': inputTokens,
      'output_tokens': outputTokens,
      'cached_tokens': cachedTokens,
      'total_tokens': totalTokens,
      'estimated_cost_usd': estimatedCostUsd,
    };
  }
}
