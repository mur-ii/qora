import 'package:hive/hive.dart';

import '../../domain/repositories/login_session_repository.dart';
import '../datasources/login_session_local_datasource.dart';
import '../models/login_session.dart';

class LoginSessionRepositoryImpl implements LoginSessionRepository {
  static const String _activeSessionKey = 'active_login_session_id';

  final LoginSessionLocalDataSource localDataSource;
  final Box<String> metaBox;

  LoginSessionRepositoryImpl({
    required this.localDataSource,
    required this.metaBox,
  });

  @override
  Future<LoginSession> startSession(String fullName) async {
    final now = DateTime.now();
    final session = LoginSession(
      sessionId: 'login_${now.microsecondsSinceEpoch}',
      fullName: fullName,
      loginAt: now,
      logoutAt: null,
    );

    await localDataSource.saveSession(session);
    await metaBox.put(_activeSessionKey, session.sessionId);
    return session;
  }

  @override
  Future<void> endSession(String sessionId) async {
    final existing = localDataSource.getSession(sessionId);
    if (existing == null) return;

    final updated = existing.copyWith(logoutAt: DateTime.now());
    await localDataSource.saveSession(updated);
    await metaBox.delete(_activeSessionKey);
  }

  @override
  Future<List<LoginSession>> getAllSessions() async {
    return localDataSource.getAllSessions();
  }

  @override
  String? getActiveSessionId() {
    return metaBox.get(_activeSessionKey);
  }
}
