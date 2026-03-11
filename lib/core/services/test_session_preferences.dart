class TestSessionPreferences {
  TestSessionPreferences._();

  static const String scenarioKey = 'test_scenario';
  static const String methodKey = 'test_method';
  static const String pendingEndSessionKey = 'pending_end_session';
  static const String methodAuto = 'auto';
  static const String methodGui = 'gui';
  static const String methodVui = 'vui';

  static final Map<String, String> _store = <String, String>{};

  static String getScenarioId() {
    return _store[scenarioKey] ?? 'scenario_1';
  }

  static String getMethodValue() {
    return _store[methodKey] ?? methodAuto;
  }

  static Future<void> setScenarioId(String scenarioId) async {
    _store[scenarioKey] = scenarioId;
  }

  static Future<void> setMethodValue(String methodValue) async {
    _store[methodKey] = methodValue;
  }

  static bool getPendingEndSession() {
    return _store[pendingEndSessionKey] == 'true';
  }

  static Future<void> setPendingEndSession(bool pending) async {
    _store[pendingEndSessionKey] = pending ? 'true' : 'false';
  }
}
