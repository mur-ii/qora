import '../entities/conversation_log.dart';
import '../repositories/conversation_repository.dart';

class LogConversation {
  LogConversation(this.repository);

  final ConversationRepository repository;

  Future<int> call(ConversationLog conversationLog) {
    return repository.saveConversationLog(conversationLog);
  }
}
