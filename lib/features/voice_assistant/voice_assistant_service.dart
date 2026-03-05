import 'domain/entities/connection_state_entity.dart';
import 'domain/entities/function_call_entity.dart';
import 'domain/entities/voice_session_entity.dart';
import 'domain/repositories/voice_assistant_repository.dart';
import 'voice_logger.dart';

class VoiceAssistantService {
  final VoiceAssistantRepository repository;
  final VoiceConversationLogger logger;

  VoiceSessionEntity? _session;
  bool _isConnecting = false;

  VoiceAssistantService({required this.repository, required this.logger});

  bool get hasActiveSession => _session != null;
  bool get isConnecting => _isConnecting;

  Future<VoiceSessionEntity> connect({
    required String model,
    required String voice,
    List<Map<String, dynamic>>? tools,
    String? instructions,
    required Function(ConnectionStateEntity) onConnectionStateChange,
    required Function(String) onTranscript,
    required Function(FunctionCallEntity) onFunctionCall,
    required Function(Map<String, dynamic>) onAgentEvent,
  }) async {
    if (_isConnecting) {
      throw Exception('Voice assistant is already connecting');
    }

    _isConnecting = true;

    try {
      if (_session != null) {
        await disconnect();
      }

      final session = await repository.createSession(
        model: model,
        voice: voice,
        tools: tools,
        instructions: instructions,
      );

      _session = session;
      logger.setModelName(session.model);
      logger.logLifecycle('Session created');

      await repository.initializeWebRTC(
        clientSecret: session.clientSecret,
        modelName: session.model,
        onConnectionStateChange: onConnectionStateChange,
        onTranscript: onTranscript,
        onFunctionCall: onFunctionCall,
        onAgentEvent: onAgentEvent,
      );

      return session;
    } catch (e) {
      logger.logError('Failed to connect voice assistant', error: e);
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    try {
      await repository.disconnect();
    } finally {
      _session = null;
      logger.logLifecycle('Session closed');
    }
  }

  Future<void> sendFunctionResult(FunctionResultEntity result) async {
    if (_session == null) {
      throw Exception('Voice assistant session is not active');
    }
    await repository.sendFunctionResult(result);
  }

  Future<void> requestAssistantResponse(String instructions) async {
    if (_session == null) {
      throw Exception('Voice assistant session is not active');
    }
    await repository.requestAssistantResponse(instructions);
  }

  Future<void> setMicrophoneMuted({required bool isMuted}) async {
    await repository.setMicrophoneMuted(isMuted: isMuted);
  }
}
