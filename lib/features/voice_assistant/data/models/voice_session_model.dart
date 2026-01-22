import '../../domain/entities/voice_session_entity.dart';

class VoiceSessionModel extends VoiceSessionEntity {
  const VoiceSessionModel({
    required super.id,
    required super.clientSecret,
    required super.model,
    required super.voice,
    required super.expiresAt,
  });

  factory VoiceSessionModel.fromJson(Map<String, dynamic> json) {
    return VoiceSessionModel(
      id: json['id'] as String,
      clientSecret: json['client_secret']['value'] as String,
      model: json['model'] as String,
      voice: json['voice'] as String,
      expiresAt: _parseExpiresAt(json['expires_at']),
    );
  }

  /// Parse expires_at which can be either Unix timestamp (int) or ISO string
  static DateTime _parseExpiresAt(dynamic expiresAt) {
    if (expiresAt is int) {
      return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    } else if (expiresAt is String) {
      return DateTime.parse(expiresAt);
    } else {
      throw Exception('Invalid expires_at format: $expiresAt');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_secret': {'value': clientSecret},
      'model': model,
      'voice': voice,
      'expires_at': expiresAt.toIso8601String(),
    };
  }
}
