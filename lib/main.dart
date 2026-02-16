import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/env_config.dart';
import 'core/di/auth_injection.dart';
import 'core/di/performance_injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/booking/data/models/booking_record.dart';
import 'features/performance/data/models/performance_summary.dart';
import 'features/performance/presentation/bloc/performance_bloc.dart';
import 'features/research/data/models/research_entry.dart';
import 'features/research/data/models/participant_record.dart';
import 'features/voice_assistant/di/voice_assistant_injection.dart';
import 'features/voice_assistant/presentation/bloc/voice_assistant_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await EnvConfig.load();

  // Validate required environment variables
  EnvConfig.validate();

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(interactionMethodTypeId)) {
    Hive.registerAdapter(InteractionMethodAdapter());
  }
  if (!Hive.isAdapterRegistered(performanceSummaryTypeId)) {
    Hive.registerAdapter(PerformanceSummaryAdapter());
  }
  if (!Hive.isAdapterRegistered(bookingRecordTypeId)) {
    Hive.registerAdapter(BookingRecordAdapter());
  }
  if (!Hive.isAdapterRegistered(researchPreferenceTypeId)) {
    Hive.registerAdapter(ResearchPreferenceAdapter());
  }
  if (!Hive.isAdapterRegistered(researchEntryTypeId)) {
    Hive.registerAdapter(ResearchEntryAdapter());
  }
  if (!Hive.isAdapterRegistered(participantRecordTypeId)) {
    Hive.registerAdapter(ParticipantRecordAdapter());
  }
  await Hive.openBox<PerformanceSummary>('performance_box');
  await Hive.openBox<BookingRecord>('booking_box');
  await Hive.openBox<ResearchEntry>('research_box');
  await Hive.openBox<ParticipantRecord>('participant_box');

  // Initialize navigation service with router
  final navigationService = VoiceAssistantInjection.getNavigationService();
  navigationService.setRouter(appRouter);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationService = VoiceAssistantInjection.getNavigationService();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthInjection.getAuthBloc(),
        ),
        BlocProvider<VoiceAssistantBloc>(
          create: (context) =>
              VoiceAssistantInjection.provideVoiceAssistantBloc(
                openAiApiKey: EnvConfig.openAiApiKey,
                navigationService: navigationService,
              ),
        ),
        BlocProvider<PerformanceBloc>(
          create: (context) => PerformanceInjection.getPerformanceBloc(),
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
