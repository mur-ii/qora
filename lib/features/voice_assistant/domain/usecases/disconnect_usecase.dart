import '../repositories/voice_assistant_repository.dart';

class DisconnectUseCase {
  final VoiceAssistantRepository repository;

  DisconnectUseCase(this.repository);

  Future<void> call() async {
    await repository.disconnect();
  }
}
