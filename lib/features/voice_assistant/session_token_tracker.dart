import '../../core/utils/app_logger.dart';

class SessionTokenTracker {
  static const double _inputCostPerM = 0.60;
  static const double _cachedInputCostPerM = 0.06;
  static const double _outputCostPerM = 2.40;
  static const int _oneMillion = 1000000;

  int _totalInputTokens = 0;
  int _totalCachedTokens = 0;
  int _totalOutputTokens = 0;
  String _modelName = 'gpt-realtime-mini-2025-12-15';

  int get totalInputTokens => _totalInputTokens;
  int get totalCachedTokens => _totalCachedTokens;
  int get totalOutputTokens => _totalOutputTokens;
  String get modelName => _modelName;

  double get inputCost => _totalInputTokens * (_inputCostPerM / _oneMillion);
  double get cachedInputCost =>
      _totalCachedTokens * (_cachedInputCostPerM / _oneMillion);
  double get outputCost => _totalOutputTokens * (_outputCostPerM / _oneMillion);
  double get totalCost => inputCost + cachedInputCost + outputCost;

  void setModelName(String? value) {
    if (value == null || value.trim().isEmpty) return;
    _modelName = value.trim();
  }

  void recordUsage({
    required int inputTokens,
    required int cachedInputTokens,
    required int outputTokens,
    String? modelName,
  }) {
    setModelName(modelName);
    _totalInputTokens += inputTokens;
    _totalCachedTokens += cachedInputTokens;
    _totalOutputTokens += outputTokens;
  }

  void reset() {
    _totalInputTokens = 0;
    _totalCachedTokens = 0;
    _totalOutputTokens = 0;
  }

  String buildSummary() {
    final buffer = StringBuffer()
      ..writeln('[Session Summary]')
      ..writeln('Model: $_modelName')
      ..writeln('Input Tokens: $_totalInputTokens')
      ..writeln('Cached Tokens: $_totalCachedTokens')
      ..writeln('Output Tokens: $_totalOutputTokens')
      ..writeln('Input Cost: ${inputCost.toStringAsFixed(6)}')
      ..writeln('Cached Input Cost: ${cachedInputCost.toStringAsFixed(6)}')
      ..writeln('Output Cost: ${outputCost.toStringAsFixed(6)}')
      ..writeln('Total Cost: ${totalCost.toStringAsFixed(6)}');

    return buffer.toString();
  }

  void logSummary() {
    AppLogger.info('VoiceSession', buildSummary());
  }
}
