import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/navigation_service.dart';
import '../data/datasources/openai_realtime_datasource.dart';
import '../data/datasources/webrtc_service.dart';
import '../data/repositories/voice_assistant_repository_impl.dart';
import '../data/services/agentic_ai_service.dart';
import '../presentation/bloc/voice_assistant_bloc.dart';
import '../session_token_tracker.dart';
import '../voice_assistant_controller.dart';
import '../voice_assistant_service.dart';
import '../voice_logger.dart';

class VoiceAssistantInjection {
  static VoiceAssistantBloc? _voiceAssistantBloc;
  static NavigationService? _navigationService;
  static VoiceConversationLogger? _conversationLogger;
  static VoiceAssistantController? _voiceAssistantController;
  static SessionTokenTracker? _sessionTokenTracker;

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
    final httpClient = http.Client();
    final openAIDataSource = OpenAIRealtimeDataSource(
      apiKey: openAiApiKey,
      httpClient: httpClient,
    );
    final webRTCService = WebRTCService(
      conversationLogger: _conversationLogger,
    );

    // Repository
    final repository = VoiceAssistantRepositoryImpl(
      dataSource: openAIDataSource,
      webRTCService: webRTCService,
    );

    // Service + Controller
    final voiceAssistantService = VoiceAssistantService(
      repository: repository,
      logger: _conversationLogger!,
    );

    // Agentic AI Service
    final agenticAIService = AgenticAIService(
      navigationService: navigationService,
    );

    _voiceAssistantController = VoiceAssistantController(
      service: voiceAssistantService,
      agenticAIService: agenticAIService,
      logger: _conversationLogger!,
      tokenTracker: _sessionTokenTracker!,
    );

    // BLoC
    _voiceAssistantBloc = VoiceAssistantBloc(
      voiceAssistantController: _voiceAssistantController!,
      agenticAIService: agenticAIService,
      defaultModel: model,
    );

    return _voiceAssistantBloc!;
  }

  /// Access the in-memory conversation logs for storage/export.
  static VoiceConversationLogger getConversationLogger() {
    _sessionTokenTracker ??= SessionTokenTracker();
    return _conversationLogger ??= VoiceConversationLogger(
      tokenTracker: _sessionTokenTracker,
    );
  }

  static VoiceAssistantController getVoiceAssistantController() {
    if (_voiceAssistantController == null) {
      throw StateError('VoiceAssistantController not initialized');
    }
    return _voiceAssistantController!;
  }

  static VoiceAssistantController? tryGetVoiceAssistantController() {
    return _voiceAssistantController;
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
    _voiceAssistantController = null;
    _sessionTokenTracker = null;
  }
}
