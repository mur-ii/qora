import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/voice_session_model.dart';

class OpenAIRealtimeDataSource {
  final String _apiKey;
  final http.Client httpClient;

  static const String baseUrl = 'https://api.openai.com/v1/realtime';

  OpenAIRealtimeDataSource({required String apiKey, http.Client? httpClient})
    : _apiKey = apiKey,
      httpClient = httpClient ?? http.Client();

  /// Create a new Realtime session
  Future<VoiceSessionModel> createSession({
    required String model,
    required String voice,
    List<Map<String, dynamic>>? tools,
    String? instructions,
  }) async {
    final sessionConfig = {
      'model': model,
      'voice': voice,
      'modalities': ['text', 'audio'],
      'input_audio_format': 'pcm16',
      'output_audio_format': 'pcm16',
      'input_audio_transcription': {'model': 'whisper-1'},
      'turn_detection': {
        'type': 'server_vad',
        'threshold': 0.5,
        'prefix_padding_ms': 300,
        'silence_duration_ms': 500,
      },
      if (tools != null && tools.isNotEmpty) 'tools': tools,
      if (instructions != null) 'instructions': instructions,
    };

    final response = await httpClient
        .post(
          Uri.parse('$baseUrl/sessions'),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(sessionConfig),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('Session creation timeout'),
        );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return VoiceSessionModel.fromJson(json);
    } else {
      throw Exception('Failed to create session: ${response.statusCode}');
    }
  }

  /// Send SDP offer and receive SDP answer
  Future<String> exchangeSDP({
    required String sdpOffer,
    required String clientSecret,
  }) async {
    final response = await httpClient
        .post(
          Uri.parse(baseUrl),
          headers: {
            'Authorization': 'Bearer $clientSecret',
            'Content-Type': 'application/sdp',
          },
          body: sdpOffer,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('SDP exchange timeout'),
        );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body; // SDP answer
    } else {
      throw Exception('Failed to exchange SDP: ${response.statusCode}');
    }
  }
}
