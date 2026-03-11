import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/voice_assistant/data/datasources/openai_realtime_datasource.dart';
import '../../features/voice_assistant/data/datasources/webrtc_service.dart';
import '../../features/voice_assistant/data/repositories/voice_assistant_repository_impl.dart';
import '../../features/voice_assistant/domain/usecases/agentic_ai_usecase.dart';
import '../../features/voice_assistant/domain/usecases/session_token_tracker.dart';
import '../../features/voice_assistant/domain/usecases/voice_conversation_logger.dart';
import '../../features/voice_assistant/domain/usecases/voice_session_usecase.dart';
import '../../features/voice_assistant/presentation/bloc/voice_assistant_bloc.dart';
import '../services/navigation_service.dart';

class VoiceAssistantInjection {
  static VoiceAssistantBloc? _voiceAssistantBloc;
  static NavigationService? _navigationService;
  static VoiceConversationLogger? _conversationLogger;
  static VoiceSessionUseCase? _voiceSessionUseCase;
  static SessionTokenTracker? _sessionTokenTracker;
  static http.Client? _httpClient;

  /// Initialize voice assistant dependencies
  static VoiceAssistantBloc provideVoiceAssistantBloc({
    required String openAiApiKey,
    required NavigationService navigationService,
    String? model,
    bool enableFileLogging = kDebugMode,
  }) {
    _navigationService = navigationService;

    _sessionTokenTracker ??= SessionTokenTracker();
    _conversationLogger ??= VoiceConversationLogger(
      modelName: model,
      tokenTracker: _sessionTokenTracker,
    );
    if (enableFileLogging && kDebugMode) {
      _conversationLogger!.enableFileLogging();
    } else {
      _conversationLogger!.disableFileLogging();
    }

    // Data sources
    _httpClient ??= http.Client();
    final openAIDataSource = OpenAIRealtimeDataSource(
      apiKey: openAiApiKey,
      httpClient: _httpClient,
    );
    final webRTCService = WebRTCService(
      conversationLogger: _conversationLogger,
    );

    // Repository
    final repository = VoiceAssistantRepositoryImpl(
      dataSource: openAIDataSource,
      webRTCService: webRTCService,
    );

    // Use cases
    final agenticAiUseCase = AgenticAiUseCase(
      navigationService: navigationService,
    );

    _voiceSessionUseCase = VoiceSessionUseCase(
      repository: repository,
      agenticAiUseCase: agenticAiUseCase,
      logger: _conversationLogger!,
      tokenTracker: _sessionTokenTracker!,
    );

    // BLoC
    _voiceAssistantBloc = VoiceAssistantBloc(
      voiceSessionUseCase: _voiceSessionUseCase!,
      agenticAiUseCase: agenticAiUseCase,
      defaultModel: model,
    );

    return _voiceAssistantBloc!;
  }

  static VoiceSessionUseCase getVoiceAssistantController() {
    if (_voiceSessionUseCase == null) {
      throw StateError('VoiceSessionUseCase not initialized');
    }
    return _voiceSessionUseCase!;
  }

  static VoiceSessionUseCase? tryGetVoiceAssistantController() {
    return _voiceSessionUseCase;
  }

  /// Get navigation service
  static NavigationService getNavigationService() {
    return _navigationService ??= NavigationService();
  }

  /// Dispose resources
  static void dispose() {
    _voiceAssistantBloc?.close();
    _voiceAssistantBloc = null;
    _navigationService = null;
    _conversationLogger = null;
    _voiceSessionUseCase = null;
    _sessionTokenTracker = null;
    _httpClient?.close();
    _httpClient = null;
  }
}
