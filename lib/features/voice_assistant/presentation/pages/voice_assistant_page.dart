import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/performance_tracked_page.dart';
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
    return PerformanceTrackedPage(
      pageName: 'Voice Interaction Page',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Voice Assistant'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            BlocBuilder<VoiceAssistantBloc, VoiceAssistantState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: _ConnectionIndicator(status: state.connectionStatus),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<VoiceAssistantBloc, VoiceAssistantState>(
          listener: (context, state) {
            if (state.error != null) {
              AppToast.showError(context, state.error!);
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                // Agent status bar
                if (state.connectionStatus == VoiceConnectionStatus.connected)
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
                        color: Colors.black.withOpacity(0.05),
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
                        if (state.connectionStatus ==
                            VoiceConnectionStatus.connected)
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
                          state: _mapConnectionStatus(state.connectionStatus),
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
      ),
    );
  }

  ContentChangingButtonState _mapConnectionStatus(
    VoiceConnectionStatus status,
  ) {
    switch (status) {
      case VoiceConnectionStatus.connecting:
        return ContentChangingButtonState.connecting;
      case VoiceConnectionStatus.connected:
        return ContentChangingButtonState.connected;
      case VoiceConnectionStatus.disconnected:
      case VoiceConnectionStatus.failed:
        return ContentChangingButtonState.notConnect;
    }
  }

  void _handleButtonPress(BuildContext context, VoiceAssistantState state) {
    if (state.connectionStatus == VoiceConnectionStatus.connected) {
      // Stop
      context.read<VoiceAssistantBloc>().add(const StopVoiceAssistant());
    } else if (state.connectionStatus == VoiceConnectionStatus.disconnected ||
        state.connectionStatus == VoiceConnectionStatus.failed) {
      // Start
      context.read<VoiceAssistantBloc>().add(const StartVoiceAssistant());
    }
  }
}

class _ConnectionIndicator extends StatelessWidget {
  final VoiceConnectionStatus status;

  const _ConnectionIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case VoiceConnectionStatus.connected:
        color = Colors.green;
        text = 'Connected';
        break;
      case VoiceConnectionStatus.connecting:
        color = Colors.orange;
        text = 'Connecting';
        break;
      case VoiceConnectionStatus.failed:
        color = Colors.red;
        text = 'Failed';
        break;
      case VoiceConnectionStatus.disconnected:
        color = Colors.grey;
        text = 'Disconnected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
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
