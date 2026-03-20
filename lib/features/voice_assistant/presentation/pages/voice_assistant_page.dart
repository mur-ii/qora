import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/agent_state_entity.dart';
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Microphone permission is required'),
              backgroundColor: AppColors.error,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Assistant'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surfaceWhite,
        elevation: 0,
        actions: [
          BlocSelector<
            VoiceAssistantBloc,
            VoiceAssistantState,
            VoiceAssistantStatus
          >(
            selector: (state) => state.status,
            builder: (context, status) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: _ConnectionIndicator(status: status)),
              );
            },
          ),
        ],
      ),
      body: BlocListener<VoiceAssistantBloc, VoiceAssistantState>(
        listenWhen: (previous, current) =>
            previous.error != current.error && current.error != null,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: AppColors.error,
                ),
              );
          }
        },
        child: Column(
          children: [
            BlocSelector<VoiceAssistantBloc, VoiceAssistantState, bool>(
              selector: (state) => state.isActive,
              builder: (context, isActive) {
                if (!isActive) {
                  return const SizedBox.shrink();
                }

                return BlocSelector<
                  VoiceAssistantBloc,
                  VoiceAssistantState,
                  ({AgentStateEntity agentState, bool isProcessing})
                >(
                  selector: (state) => (
                    agentState: state.agentState,
                    isProcessing: state.isProcessing,
                  ),
                  builder: (context, data) {
                    return AgentStatusBar(
                      agentState: data.agentState,
                      isProcessing: data.isProcessing,
                    );
                  },
                );
              },
            ),
            Expanded(
              child:
                  BlocSelector<
                    VoiceAssistantBloc,
                    VoiceAssistantState,
                    List<ConversationMessage>
                  >(
                    selector: (state) => state.messages,
                    builder: (context, messages) {
                      return ConversationView(messages: messages);
                    },
                  ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.deepBlack.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child:
                    BlocSelector<
                      VoiceAssistantBloc,
                      VoiceAssistantState,
                      ({VoiceAssistantStatus status, bool isActive})
                    >(
                      selector: (state) =>
                          (status: state.status, isActive: state.isActive),
                      builder: (context, data) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (data.isActive)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Listening...',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ContentChangingButton(
                              state: _mapConnectionStatus(data.status),
                              onPressed: () => _handleButtonPress(
                                context,
                                status: data.status,
                                isActive: data.isActive,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
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

  void _handleButtonPress(
    BuildContext context, {
    required VoiceAssistantStatus status,
    required bool isActive,
  }) {
    if (isActive) {
      // Stop
      context.read<VoiceAssistantBloc>().add(const StopVoiceAssistant());
    } else if (status == VoiceAssistantStatus.idle) {
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
        color = AppColors.brandGreen;
        text = 'Connected';
        break;
      case VoiceAssistantStatus.listening:
        color = AppColors.brandGreen;
        text = 'Listening';
        break;
      case VoiceAssistantStatus.speaking:
        color = AppColors.brandGreen;
        text = 'Speaking';
        break;
      case VoiceAssistantStatus.connecting:
        color = AppColors.primaryOrange;
        text = 'Connecting';
        break;
      case VoiceAssistantStatus.disconnecting:
        color = AppColors.primaryOrange;
        text = 'Disconnecting';
        break;
      case VoiceAssistantStatus.idle:
        color = AppColors.textSecondary;
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
