import '../entities/connection_state_entity.dart';
import '../entities/function_call_entity.dart';
import '../repositories/voice_assistant_repository.dart';

class InitializeWebRTCUseCase {
  final VoiceAssistantRepository repository;

  InitializeWebRTCUseCase(this.repository);

  Future<void> call({
    required String clientSecret,
    required Function(ConnectionStateEntity) onConnectionStateChange,
    required Function(String) onTranscript,
    required Function(FunctionCallEntity) onFunctionCall,
    required Function(Map<String, dynamic>) onAgentEvent,
  }) async {
    await repository.initializeWebRTC(
      clientSecret: clientSecret,
      onConnectionStateChange: onConnectionStateChange,
      onTranscript: onTranscript,
      onFunctionCall: onFunctionCall,
      onAgentEvent: onAgentEvent,
    );
  }
}
