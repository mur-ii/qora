import '../entities/function_call_entity.dart';
import '../repositories/voice_assistant_repository.dart';

class SendFunctionResultUseCase {
  final VoiceAssistantRepository repository;

  SendFunctionResultUseCase(this.repository);

  Future<void> call(FunctionResultEntity result) async {
    await repository.sendFunctionResult(result);
  }
}
