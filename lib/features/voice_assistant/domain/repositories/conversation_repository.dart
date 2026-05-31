import '../entities/conversation_log.dart';

abstract class ConversationRepository {
  Future<int> saveConversationLog(ConversationLog conversationLog);

  Future<List<ConversationLog>> getConversationLogsBySession(String sessionId);

  Future<double> calculateSessionCost(String sessionId);

  Future<void> clearSessionLogs(String sessionId);
}
