import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration for secure API key management
class EnvConfig {
  /// Load environment variables from .env file
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  /// Get OpenAI API key from environment
  static String get openAiApiKey {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'OPENAI_API_KEY not found in .env file. '
        'Please add OPENAI_API_KEY to your .env file in the project root.',
      );
    }
    return apiKey;
  }

  /// Get OpenAI model from environment (with default fallback)
  static String get openAiModel {
    return dotenv.env['OPENAI_MODEL'] ?? 'gpt-realtime-mini-2025-12-15';
  }

  /// Validate that all required environment variables are present
  static void validate() {
    try {
      openAiApiKey; // This will throw if not found
    } catch (e) {
      throw Exception(
        'Environment validation failed: $e\n'
        'Make sure you have created a .env file with the required variables.',
      );
    }
  }
}
