import '../../domain/entities/connection_state_entity.dart';
import '../../domain/entities/function_call_entity.dart';
import '../../domain/entities/voice_session_entity.dart';
import '../../domain/repositories/voice_assistant_repository.dart';
import '../datasources/openai_realtime_datasource.dart';
import '../datasources/webrtc_service.dart';

class VoiceAssistantRepositoryImpl implements VoiceAssistantRepository {
  final OpenAIRealtimeDataSource dataSource;
  final WebRTCService webRTCService;

  VoiceAssistantRepositoryImpl({
    required this.dataSource,
    required this.webRTCService,
  });

  @override
  Future<VoiceSessionEntity> createSession({
    required String model,
    required String voice,
    List<Map<String, dynamic>>? tools,
    String? instructions,
  }) async {
    return await dataSource.createSession(
      model: model,
      voice: voice,
      tools: tools,
      instructions: instructions,
    );
  }

  @override
  Future<void> initializeWebRTC({
    required String clientSecret,
    String? modelName,
    required Function(ConnectionStateEntity) onConnectionStateChange,
    required Function(String) onTranscript,
    required Function(FunctionCallEntity) onFunctionCall,
    required Function(Map<String, dynamic>) onAgentEvent,
  }) async {
    // Initialize WebRTC service
    await webRTCService.initialize(
      onConnectionStateChange: onConnectionStateChange,
      onTranscript: onTranscript,
      onFunctionCall: onFunctionCall,
      onAgentEvent: onAgentEvent,
      modelName: modelName,
    );

    // Create SDP offer
    final sdpOffer = await webRTCService.createOffer();

    // Exchange SDP with OpenAI
    final sdpAnswer = await dataSource.exchangeSDP(
      sdpOffer: sdpOffer,
      clientSecret: clientSecret,
    );

    // Set remote answer
    await webRTCService.setRemoteAnswer(sdpAnswer);
  }

  @override
  Future<void> sendFunctionResult(FunctionResultEntity result) async {
    await webRTCService.sendFunctionResult(
      callId: result.callId,
      result: result.result,
    );
  }

  @override
  Future<void> requestAssistantResponse(String instructions) async {
    await webRTCService.sendEvent({
      'type': 'response.create',
      'response': {
        'modalities': ['text', 'audio'],
        'instructions': instructions,
      },
    });
  }

  @override
  Future<void> disconnect() async {
    await webRTCService.disconnect();
  }

  @override
  Future<void> setMicrophoneMuted({required bool isMuted}) async {
    await webRTCService.setMicrophoneMuted(isMuted: isMuted);
  }
}
