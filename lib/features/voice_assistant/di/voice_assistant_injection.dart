import 'package:http/http.dart' as http;

import '../../../core/services/navigation_service.dart';
import '../data/datasources/openai_realtime_datasource.dart';
import '../data/datasources/webrtc_service.dart';
import '../data/repositories/voice_assistant_repository_impl.dart';
import '../data/services/agentic_ai_service.dart';
import '../domain/usecases/create_session_usecase.dart';
import '../domain/usecases/disconnect_usecase.dart';
import '../domain/usecases/initialize_webrtc_usecase.dart';
import '../domain/usecases/request_assistant_response_usecase.dart';
import '../domain/usecases/send_function_result_usecase.dart';
import '../presentation/bloc/voice_assistant_bloc.dart';

class VoiceAssistantInjection {
  static VoiceAssistantBloc? _voiceAssistantBloc;
  static NavigationService? _navigationService;

  /// Initialize voice assistant dependencies
  static VoiceAssistantBloc provideVoiceAssistantBloc({
    required String openAiApiKey,
    required NavigationService navigationService,
  }) {
    _navigationService = navigationService;

    // Data sources
    final httpClient = http.Client();
    final openAIDataSource = OpenAIRealtimeDataSource(
      apiKey: openAiApiKey,
      httpClient: httpClient,
    );
    final webRTCService = WebRTCService();

    // Repository
    final repository = VoiceAssistantRepositoryImpl(
      dataSource: openAIDataSource,
      webRTCService: webRTCService,
    );

    // Agentic AI Service
    final agenticAIService = AgenticAIService(
      navigationService: navigationService,
    );

    // Use cases
    final createSessionUseCase = CreateSessionUseCase(repository);
    final initializeWebRTCUseCase = InitializeWebRTCUseCase(repository);
    final requestAssistantResponseUseCase = RequestAssistantResponseUseCase(
      repository,
    );
    final sendFunctionResultUseCase = SendFunctionResultUseCase(repository);
    final disconnectUseCase = DisconnectUseCase(repository);

    // BLoC
    _voiceAssistantBloc = VoiceAssistantBloc(
      createSessionUseCase: createSessionUseCase,
      initializeWebRTCUseCase: initializeWebRTCUseCase,
      requestAssistantResponseUseCase: requestAssistantResponseUseCase,
      sendFunctionResultUseCase: sendFunctionResultUseCase,
      disconnectUseCase: disconnectUseCase,
      agenticAIService: agenticAIService,
    );

    return _voiceAssistantBloc!;
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
  }
}
