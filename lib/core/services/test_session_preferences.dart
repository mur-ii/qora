import 'package:hive/hive.dart';

class TestSessionPreferences {
  TestSessionPreferences._();

  static const String scenarioKey = 'test_scenario';
  static const String methodKey = 'test_method';
  static const String pendingEndSessionKey = 'pending_end_session';
  static const String methodAuto = 'auto';
  static const String methodGui = 'gui';
  static const String methodVui = 'vui';

  static Box<String> get _box => Hive.box<String>('app_meta');

  static String getScenarioId() {
    return _box.get(scenarioKey) ?? 'scenario_1';
  }

  static String getMethodValue() {
    return _box.get(methodKey) ?? methodAuto;
  }

  static Future<void> setScenarioId(String scenarioId) async {
    await _box.put(scenarioKey, scenarioId);
  }

  static Future<void> setMethodValue(String methodValue) async {
    await _box.put(methodKey, methodValue);
  }

  static bool getPendingEndSession() {
    return _box.get(pendingEndSessionKey) == 'true';
  }

  static Future<void> setPendingEndSession(bool pending) async {
    await _box.put(pendingEndSessionKey, pending ? 'true' : 'false');
  }
}
