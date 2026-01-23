import '../entities/agent_state_entity.dart';
import '../entities/connection_state_entity.dart';
import '../entities/function_call_entity.dart';
import '../entities/voice_session_entity.dart';

abstract class VoiceAssistantRepository {
  /// Create a new OpenAI Realtime session
  Future<VoiceSessionEntity> createSession({
    required String model,
    required String voice,
    List<Map<String, dynamic>>? tools,
    String? instructions,
  });

  /// Initialize WebRTC connection with SDP signaling
  Future<void> initializeWebRTC({
    required String clientSecret,
    required Function(ConnectionStateEntity) onConnectionStateChange,
    required Function(String) onTranscript,
    required Function(FunctionCallEntity) onFunctionCall,
    required Function(Map<String, dynamic>) onAgentEvent,
  });

  /// Send audio data to OpenAI
  Future<void> sendAudio(List<int> audioData);

  /// Send function result back to OpenAI
  Future<void> sendFunctionResult(FunctionResultEntity result);

  /// Ask assistant to respond with a custom prompt
  Future<void> requestAssistantResponse(String instructions);

  /// Update agent state
  Future<void> updateAgentState(AgentStateEntity state);

  /// Disconnect and cleanup
  Future<void> disconnect();

  /// Mute/unmute microphone input
  Future<void> setMicrophoneMuted({required bool isMuted});

  /// Get current connection state
  ConnectionStateEntity getConnectionState();
}
