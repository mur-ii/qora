import '../entities/voice_session_entity.dart';
import '../repositories/voice_assistant_repository.dart';

class CreateSessionUseCase {
  final VoiceAssistantRepository repository;

  CreateSessionUseCase(this.repository);

  Future<VoiceSessionEntity> call({
    String model = 'gpt-realtime-mini-2025-12-15',
    String voice = 'verse',
    List<Map<String, dynamic>>? tools,
    String? instructions,
  }) async {
    return await repository.createSession(
      model: model,
      voice: voice,
      tools: tools,
      instructions: instructions,
    );
  }
}
