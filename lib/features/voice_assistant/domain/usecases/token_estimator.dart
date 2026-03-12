class TokenEstimator {
  static const double _tokenMultiplier = 1.3;

  int estimateTokens(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return 0;
    final words = normalized.split(RegExp(r'\\s+')).where((w) => w.isNotEmpty);
    return (words.length * _tokenMultiplier).ceil();
  }
}
