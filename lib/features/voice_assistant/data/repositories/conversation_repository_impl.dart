import '../../domain/entities/conversation_log.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../datasources/conversation_local_datasource.dart';
import '../models/conversation_log_model.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  ConversationRepositoryImpl({required this.localDataSource});

  final ConversationLocalDataSource localDataSource;

  @override
  Future<int> saveConversationLog(ConversationLog conversationLog) {
    final model = ConversationLogModel.fromEntity(conversationLog);
    return localDataSource.insertConversationLog(model);
  }

  @override
  Future<List<ConversationLog>> getConversationLogsBySession(String sessionId) {
    return localDataSource.getLogsBySessionId(sessionId);
  }

  @override
  Future<double> calculateSessionCost(String sessionId) {
    return localDataSource.getSessionCost(sessionId);
  }

  @override
  Future<void> clearSessionLogs(String sessionId) {
    return localDataSource.clearSessionLogs(sessionId);
  }
}
