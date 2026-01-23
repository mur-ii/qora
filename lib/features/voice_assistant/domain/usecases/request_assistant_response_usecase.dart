import '../repositories/voice_assistant_repository.dart';

class RequestAssistantResponseUseCase {
  final VoiceAssistantRepository repository;

  RequestAssistantResponseUseCase(this.repository);

  Future<void> call(String instructions) {
    return repository.requestAssistantResponse(instructions);
  }
}
