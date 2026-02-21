import 'package:hive/hive.dart';

import '../models/login_session.dart';

class LoginSessionLocalDataSource {
  final Box<LoginSession> box;

  LoginSessionLocalDataSource({required this.box});

  Future<void> saveSession(LoginSession session) {
    return box.put(session.sessionId, session);
  }

  LoginSession? getSession(String sessionId) {
    return box.get(sessionId);
  }

  List<LoginSession> getAllSessions() {
    return box.values.toList(growable: false);
  }
}
