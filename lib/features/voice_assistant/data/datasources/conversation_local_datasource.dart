import '../models/conversation_log_model.dart';

class ConversationLocalDataSource {
  final List<ConversationLogModel> _logs = <ConversationLogModel>[];
  int _nextId = 1;

  Future<int> insertConversationLog(ConversationLogModel log) async {
    final insertedId = _nextId++;
    final logMap = log.toMap()..['id'] = insertedId;
    _logs.add(ConversationLogModel.fromMap(logMap));
    return insertedId;
  }

  Future<List<ConversationLogModel>> getLogsBySessionId(
    String sessionId,
  ) async {
    final filtered =
        _logs.where((log) => log.sessionId == sessionId).toList(growable: false)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return filtered;
  }

  Future<double> getSessionCost(String sessionId) async {
    var total = 0.0;
    for (final log in _logs) {
      if (log.sessionId == sessionId) {
        total += log.estimatedCostUsd;
      }
    }
    return total;
  }

  Future<void> clearSessionLogs(String sessionId) async {
    _logs.removeWhere((log) => log.sessionId == sessionId);
  }

  Future<void> close() async {
    _logs.clear();
    _nextId = 1;
  }
}
