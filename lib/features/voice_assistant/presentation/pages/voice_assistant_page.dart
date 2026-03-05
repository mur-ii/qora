import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/voice_assistant_bloc.dart';
import '../bloc/voice_assistant_event.dart';
import '../bloc/voice_assistant_state.dart';
import '../widgets/agent_status_bar.dart';
import '../widgets/content_changing_button.dart';
import '../widgets/conversation_view.dart';

class VoiceAssistantPage extends StatefulWidget {
  const VoiceAssistantPage({super.key});

  @override
  State<VoiceAssistantPage> createState() => _VoiceAssistantPageState();
}

class _VoiceAssistantPageState extends State<VoiceAssistantPage> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) {
        AppToast.showError(context, 'Microphone permission is required');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          BlocBuilder<VoiceAssistantBloc, VoiceAssistantState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: _ConnectionIndicator(status: state.status),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<VoiceAssistantBloc, VoiceAssistantState>(
        listenWhen: (previous, current) =>
            previous.error != current.error && current.error != null,
        listener: (context, state) {
          if (state.error != null) {
            AppToast.showError(context, state.error!);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Agent status bar
              if (state.isActive)
                AgentStatusBar(
                  agentState: state.agentState,
                  isProcessing: state.isProcessing,
                ),

              // Conversation view
              Expanded(child: ConversationView(messages: state.messages)),

              // Bottom controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Info text
                      if (state.isActive)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Listening...',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Main button
                      ContentChangingButton(
                        state: _mapConnectionStatus(state.status),
                        onPressed: () => _handleButtonPress(context, state),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ContentChangingButtonState _mapConnectionStatus(VoiceAssistantStatus status) {
    switch (status) {
      case VoiceAssistantStatus.connecting:
      case VoiceAssistantStatus.disconnecting:
        return ContentChangingButtonState.connecting;
      case VoiceAssistantStatus.connected:
      case VoiceAssistantStatus.listening:
      case VoiceAssistantStatus.speaking:
        return ContentChangingButtonState.connected;
      case VoiceAssistantStatus.idle:
        return ContentChangingButtonState.notConnect;
    }
  }

  void _handleButtonPress(BuildContext context, VoiceAssistantState state) {
    if (state.isActive) {
      // Stop
      context.read<VoiceAssistantBloc>().add(const StopVoiceAssistant());
    } else if (state.status == VoiceAssistantStatus.idle) {
      // Start
      context.read<VoiceAssistantBloc>().add(const StartVoiceAssistant());
    }
  }
}

class _ConnectionIndicator extends StatelessWidget {
  final VoiceAssistantStatus status;

  const _ConnectionIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case VoiceAssistantStatus.connected:
        color = Colors.green;
        text = 'Connected';
        break;
      case VoiceAssistantStatus.listening:
        color = Colors.green;
        text = 'Listening';
        break;
      case VoiceAssistantStatus.speaking:
        color = Colors.green;
        text = 'Speaking';
        break;
      case VoiceAssistantStatus.connecting:
        color = Colors.orange;
        text = 'Connecting';
        break;
      case VoiceAssistantStatus.disconnecting:
        color = Colors.orange;
        text = 'Disconnecting';
        break;
      case VoiceAssistantStatus.idle:
        color = Colors.grey;
        text = 'Disconnected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
