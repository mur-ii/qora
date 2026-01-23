import '../repositories/voice_assistant_repository.dart';

class SetMicrophoneMutedUseCase {
  final VoiceAssistantRepository repository;

  SetMicrophoneMutedUseCase(this.repository);

  Future<void> call({required bool isMuted}) async {
    await repository.setMicrophoneMuted(isMuted: isMuted);
  }
}
