import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/voice_assistant/data/datasources/conversation_local_datasource.dart';
import '../../features/voice_assistant/data/datasources/openai_realtime_datasource.dart';
import '../../features/voice_assistant/data/datasources/webrtc_service.dart';
import '../../features/voice_assistant/data/repositories/conversation_repository_impl.dart';
import '../../features/voice_assistant/data/repositories/voice_assistant_repository_impl.dart';
import '../../features/voice_assistant/domain/usecases/agentic_ai_usecase.dart';
import '../../features/voice_assistant/domain/usecases/calculate_session_cost.dart';
import '../../features/voice_assistant/domain/usecases/log_conversation.dart';
import '../../features/voice_assistant/domain/usecases/voice_conversation_logger.dart';
import '../../features/voice_assistant/domain/usecases/voice_session_usecase.dart';
import '../../features/voice_assistant/presentation/bloc/conversation_bloc.dart';
import '../../features/voice_assistant/presentation/bloc/voice_assistant_bloc.dart';
import '../services/navigation_service.dart';

class VoiceAssistantInjection {
  static VoiceAssistantBloc? _voiceAssistantBloc;
  static ConversationBloc? _conversationBloc;
  static NavigationService? _navigationService;
  static VoiceConversationLogger? _conversationLogger;
  static VoiceSessionUseCase? _voiceSessionUseCase;
  static ConversationLocalDataSource? _conversationLocalDataSource;
  static ConversationRepositoryImpl? _conversationRepository;
  static LogConversation? _logConversationUseCase;
  static CalculateSessionCost? _calculateSessionCostUseCase;
  static http.Client? _httpClient;

  /// Initialize voice assistant dependencies
  static VoiceAssistantBloc provideVoiceAssistantBloc({
    required String openAiApiKey,
    required NavigationService navigationService,
    String? model,
    bool enableFileLogging = kDebugMode,
  }) {
    _navigationService = navigationService;

    // Keep parameter for backward compatibility with existing call sites.
    if (enableFileLogging && kDebugMode) {
      // No-op: logging is persisted to local database by design.
    }

    _conversationLocalDataSource ??= ConversationLocalDataSource();
    _conversationRepository ??= ConversationRepositoryImpl(
      localDataSource: _conversationLocalDataSource!,
    );
    _logConversationUseCase ??= LogConversation(_conversationRepository!);
    _calculateSessionCostUseCase ??= CalculateSessionCost(
      _conversationRepository!,
    );

    _conversationBloc ??= ConversationBloc(
      logConversation: _logConversationUseCase!,
      calculateSessionCost: _calculateSessionCostUseCase!,
      repository: _conversationRepository!,
    );

    _conversationLogger ??= VoiceConversationLogger(
      logConversationUseCase: _logConversationUseCase!,
      calculateSessionCostUseCase: _calculateSessionCostUseCase!,
      conversationRepository: _conversationRepository!,
      modelName: model,
    );

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
    );

    // BLoC
    _voiceAssistantBloc = VoiceAssistantBloc(
      voiceSessionUseCase: _voiceSessionUseCase!,
      agenticAiUseCase: agenticAiUseCase,
      conversationBloc: _conversationBloc!,
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

  static ConversationBloc getConversationBloc() {
    if (_conversationBloc == null) {
      throw StateError('ConversationBloc not initialized');
    }
    return _conversationBloc!;
  }

  /// Get navigation service
  static NavigationService getNavigationService() {
    return _navigationService ??= NavigationService();
  }

  /// Dispose resources
  static void dispose() {
    _voiceAssistantBloc?.close();
    _conversationBloc?.close();
    _voiceAssistantBloc = null;
    _conversationBloc = null;
    _navigationService = null;
    _conversationLogger = null;
    _voiceSessionUseCase = null;
    _logConversationUseCase = null;
    _calculateSessionCostUseCase = null;
    _conversationRepository = null;
    final closeFuture = _conversationLocalDataSource?.close();
    if (closeFuture != null) {
      unawaited(closeFuture);
    }
    _conversationLocalDataSource = null;
    _httpClient?.close();
    _httpClient = null;
  }
}
