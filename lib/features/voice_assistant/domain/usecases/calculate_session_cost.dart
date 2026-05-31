import '../repositories/conversation_repository.dart';

class CalculateSessionCost {
  CalculateSessionCost(this.repository);

  final ConversationRepository repository;

  Future<double> call(String sessionId) {
    return repository.calculateSessionCost(sessionId);
  }
}
