import 'package:equatable/equatable.dart';

/// Represents an OpenAI Realtime session
class VoiceSessionEntity extends Equatable {
  final String id;
  final String clientSecret;
  final String model;
  final String voice;
  final DateTime expiresAt;

  const VoiceSessionEntity({
    required this.id,
    required this.clientSecret,
    required this.model,
    required this.voice,
    required this.expiresAt,
  });

  @override
  List<Object?> get props => [id, clientSecret, model, voice, expiresAt];
}
