import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/voice_assistant_bloc.dart';
import '../bloc/voice_assistant_event.dart';
import '../bloc/voice_assistant_state.dart';

/// Voice Assistant Toggle Button - Can be placed anywhere in the app
class VoiceAssistantToggleButton extends StatefulWidget {
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showLabel;
  final bool showStatus;
  final bool showMuteToggle;
  final String? activeLabel;
  final String? inactiveLabel;

  const VoiceAssistantToggleButton({
    super.key,
    this.size = 56,
    this.activeColor,
    this.inactiveColor,
    this.showLabel = false,
    this.showStatus = true,
    this.showMuteToggle = true,
    this.activeLabel = 'AI Active',
    this.inactiveLabel = 'Start AI',
  });

  @override
  State<VoiceAssistantToggleButton> createState() =>
      _VoiceAssistantToggleButtonState();
}

class _VoiceAssistantToggleButtonState
    extends State<VoiceAssistantToggleButton> {
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.status;
    if (!mounted) return;
    setState(() {
      _permissionGranted = status.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    setState(() {
      _permissionGranted = status.isGranted;
    });

    if (!status.isGranted) {
      AppToast.showError(
        context,
        'Microphone permission is required for voice assistant',
      );
    }
  }

  Future<void> _handleModeChange(
    bool enableVoice,
    VoiceAssistantState state,
  ) async {
    if (enableVoice) {
      if (!_permissionGranted) {
        await _requestPermissions();
        if (!_permissionGranted || !mounted) return;
      }
    }

    if (!mounted) return;

    if (enableVoice) {
      if (state.status == VoiceAssistantStatus.idle) {
        context.read<VoiceAssistantBloc>().add(const StartVoiceAssistant());
      }
    } else {
      if (state.isActive) {
        context.read<VoiceAssistantBloc>().add(const StopVoiceAssistant());
      }
    }
  }

  Color _statusColor(
    BuildContext context, {
    required bool isActive,
    required bool isConnecting,
    required bool isFailed,
    required bool isMuted,
  }) {
    final theme = Theme.of(context);

    if (isFailed) return theme.colorScheme.error;
    if (isConnecting) return theme.colorScheme.tertiary;
    if (isActive && isMuted) return AppColors.primaryOrange;
    if (isActive) return theme.colorScheme.primary;
    return theme.colorScheme.outline;
  }

  String _statusText({
    required VoiceAssistantStatus status,
    required bool isMuted,
    required bool hasError,
  }) {
    if (hasError && status == VoiceAssistantStatus.idle) {
      return 'Failed';
    }
    if (status == VoiceAssistantStatus.connecting ||
        status == VoiceAssistantStatus.disconnecting) {
      return 'Connecting';
    }
    if (isMuted && status != VoiceAssistantStatus.idle) return 'Muted';
    if (status == VoiceAssistantStatus.speaking) return 'Speaking';
    if (status == VoiceAssistantStatus.listening) return 'Listening';
    if (status == VoiceAssistantStatus.connected) {
      return widget.activeLabel ?? 'Listening';
    }
    return widget.inactiveLabel ?? 'Idle';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceAssistantBloc, VoiceAssistantState>(
      builder: (context, state) {
        final isActive = state.isActive;
        final isConnecting =
            state.status == VoiceAssistantStatus.connecting ||
            state.status == VoiceAssistantStatus.disconnecting;
        final isFailed =
            state.error != null && state.status == VoiceAssistantStatus.idle;
        final isMuted = state.isMuted;

        final theme = Theme.of(context);
        final activeColor = widget.activeColor ?? AppColors.primary;
        final inactiveColor = widget.inactiveColor ?? AppColors.border;
        final statusColor = _statusColor(
          context,
          isActive: isActive,
          isConnecting: isConnecting,
          isFailed: isFailed,
          isMuted: isMuted,
        );
        final statusText = _statusText(
          status: state.status,
          isMuted: isMuted,
          hasError: state.error != null,
        );
        final canToggleMute = isActive && !isConnecting;

        final manualLabel = widget.inactiveLabel ?? 'Manual';
        final voiceLabel = widget.activeLabel ?? 'Voice AI';

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    manualLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isActive
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch.adaptive(
                    value: isActive,
                    onChanged: isConnecting
                        ? null
                        : (value) => _handleModeChange(value, state),
                    activeThumbColor: activeColor,
                    activeTrackColor: AppColors.primaryLight,
                    inactiveThumbColor: AppColors.surface,
                    inactiveTrackColor: inactiveColor,
                  ),
                  const SizedBox(width: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        voiceLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (widget.showMuteToggle) ...[
                        const SizedBox(width: 8),
                        InkResponse(
                          onTap: canToggleMute
                              ? () {
                                  context.read<VoiceAssistantBloc>().add(
                                    const ToggleVoiceAssistantMute(),
                                  );
                                }
                              : null,
                          radius: 16,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: canToggleMute
                                  ? AppColors.surface
                                  : AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(
                              isMuted ? Icons.volume_off : Icons.volume_up,
                              size: 14,
                              color: canToggleMute
                                  ? activeColor
                                  : AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (widget.showStatus) ...[
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  statusText,
                  key: ValueKey(statusText),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ] else if (widget.showLabel) ...[
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  statusText,
                  key: ValueKey(statusText),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 6),
              Text(
                'Error',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
