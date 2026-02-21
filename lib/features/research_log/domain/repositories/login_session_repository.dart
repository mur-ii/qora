import '../../data/models/login_session.dart';

abstract class LoginSessionRepository {
  Future<LoginSession> startSession(String fullName);
  Future<void> endSession(String sessionId);
  Future<List<LoginSession>> getAllSessions();
  String? getActiveSessionId();
}
