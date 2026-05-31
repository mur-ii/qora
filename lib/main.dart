import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/env_config.dart';
import 'core/di/voice_assistant_injection.dart';
import 'core/router/app_router.dart';
import 'core/services/frame_performance_monitor.dart';
import 'core/services/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'features/voice_assistant/presentation/bloc/voice_assistant_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await EnvConfig.load();

  // Validate required environment variables
  EnvConfig.validate();

  // Initialize navigation service with router
  final navigationService = VoiceAssistantInjection.getNavigationService();
  navigationService.setRouter(appRouter);

  FramePerformanceMonitor.instance.startMonitoring();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final NavigationService _navigationService;

  @override
  void initState() {
    super.initState();
    _navigationService = VoiceAssistantInjection.getNavigationService();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VoiceAssistantBloc>(
          create: (context) =>
              VoiceAssistantInjection.provideVoiceAssistantBloc(
                openAiApiKey: EnvConfig.openAiApiKey,
                navigationService: _navigationService,
                model: EnvConfig.openAiModel,
              ),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
        title: 'Qora - Hotel Booking',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
      ),
    );
  }
}
