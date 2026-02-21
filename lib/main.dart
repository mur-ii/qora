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
import 'features/performance/presentation/bloc/performance_event.dart';
import 'features/research_log/data/models/login_session.dart';
import 'features/research_log/data/models/sus_entry.dart';
import 'features/voice_assistant/di/voice_assistant_injection.dart';
import 'features/voice_assistant/presentation/bloc/voice_assistant_bloc.dart';
import 'features/voice_assistant/presentation/bloc/voice_assistant_state.dart';

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
  if (!Hive.isAdapterRegistered(loginSessionTypeId)) {
    Hive.registerAdapter(LoginSessionAdapter());
  }
  if (!Hive.isAdapterRegistered(susEntryTypeId)) {
    Hive.registerAdapter(SusEntryAdapter());
  }
  await Hive.openBox<PerformanceSummary>('performance_box');
  await Hive.openBox<BookingRecord>('booking_box');
  await Hive.openBox<LoginSession>('login_session_box');
  await Hive.openBox<SusEntry>('sus_box');
  await Hive.openBox<String>('app_meta');

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
      child: _VoiceAssistantPerformanceBridge(
        child: MaterialApp.router(
          routerConfig: appRouter,
          title: 'Qora - Hotel Booking',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
        ),
      ),
    );
  }
}

class _VoiceAssistantPerformanceBridge extends StatefulWidget {
  final Widget child;

  const _VoiceAssistantPerformanceBridge({required this.child});

  @override
  State<_VoiceAssistantPerformanceBridge> createState() =>
      _VoiceAssistantPerformanceBridgeState();
}

class _VoiceAssistantPerformanceBridgeState
    extends State<_VoiceAssistantPerformanceBridge> {
  VoiceConnectionStatus _lastStatus = VoiceConnectionStatus.disconnected;
  int _lastMessageCount = 0;
  bool _searchStepActive = false;

  bool _isLikelyCorrection(String text) {
    final normalized = text.toLowerCase();
    return normalized.contains('maksud saya') ||
        normalized.contains('eh') ||
        normalized.contains('bukan') ||
        normalized.contains('maaf');
  }

  void _handleVoiceState(BuildContext context, VoiceAssistantState state) {
    final performanceBloc = context.read<PerformanceBloc>();

    if (state.connectionStatus != _lastStatus) {
      if (state.connectionStatus == VoiceConnectionStatus.connected) {
        performanceBloc.add(const StartSession(method: InteractionMethod.vui));
        performanceBloc.add(const StartStep(PerformanceStep.search));
        _searchStepActive = true;
      } else if (_lastStatus == VoiceConnectionStatus.connected) {
        if (_searchStepActive) {
          performanceBloc.add(const EndStep(PerformanceStep.search));
          _searchStepActive = false;
        }
      }

      _lastStatus = state.connectionStatus;
    }

    if (state.messages.length != _lastMessageCount) {
      final latest = state.messages.isNotEmpty ? state.messages.last : null;
      if (latest != null && latest.isUser) {
        performanceBloc.add(const AddVoiceCommand());
        if (_searchStepActive) {
          performanceBloc.add(const EndStep(PerformanceStep.search));
          _searchStepActive = false;
        }
        if (_isLikelyCorrection(latest.text)) {
          performanceBloc.add(const AddCorrection());
        }
      }
      _lastMessageCount = state.messages.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VoiceAssistantBloc, VoiceAssistantState>(
      listenWhen: (previous, current) =>
          previous.connectionStatus != current.connectionStatus ||
          previous.messages.length != current.messages.length,
      listener: _handleVoiceState,
      child: widget.child,
    );
  }
}
