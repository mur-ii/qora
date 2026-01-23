import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

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
    setState(() {
      _permissionGranted = status.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    setState(() {
      _permissionGranted = status.isGranted;
    });

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required for voice assistant',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleToggle(VoiceAssistantState state) async {
    if (!_permissionGranted) {
      await _requestPermissions();
      if (!_permissionGranted || !mounted) return;
    }

    if (!mounted) return;

    if (state.connectionStatus == VoiceConnectionStatus.connected) {
      // Stop voice assistant
      context.read<VoiceAssistantBloc>().add(const StopVoiceAssistant());
    } else if (state.connectionStatus == VoiceConnectionStatus.disconnected ||
        state.connectionStatus == VoiceConnectionStatus.failed) {
      // Start voice assistant
      context.read<VoiceAssistantBloc>().add(const StartVoiceAssistant());
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
    if (isActive && isMuted) return Colors.orange.shade600;
    if (isActive) return theme.colorScheme.primary;
    return theme.colorScheme.outline;
  }

  String _statusText({
    required bool isActive,
    required bool isConnecting,
    required bool isFailed,
    required bool isMuted,
  }) {
    if (isFailed) return 'Failed';
    if (isConnecting) return 'Connecting';
    if (isActive && isMuted) return 'Muted';
    if (isActive) return widget.activeLabel ?? 'Listening';
    return widget.inactiveLabel ?? 'Idle';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceAssistantBloc, VoiceAssistantState>(
      builder: (context, state) {
        final isActive =
            state.connectionStatus == VoiceConnectionStatus.connected;
        final isConnecting =
            state.connectionStatus == VoiceConnectionStatus.connecting;
        final isFailed = state.connectionStatus == VoiceConnectionStatus.failed;
        final isMuted = state.isMuted;

        final theme = Theme.of(context);
        final activeColor = widget.activeColor ?? theme.colorScheme.primary;
        final inactiveColor =
            widget.inactiveColor ?? theme.colorScheme.surfaceContainerHighest;
        final statusColor = _statusColor(
          context,
          isActive: isActive,
          isConnecting: isConnecting,
          isFailed: isFailed,
          isMuted: isMuted,
        );
        final statusText = _statusText(
          isActive: isActive,
          isConnecting: isConnecting,
          isFailed: isFailed,
          isMuted: isMuted,
        );
        final canToggleMute = isActive && !isConnecting;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isActive ? activeColor : inactiveColor).withOpacity(0.95),
                    (isActive ? activeColor : inactiveColor).withOpacity(0.75),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(isActive ? 0.45 : 0.2),
                    blurRadius: isActive ? 18 : 10,
                    spreadRadius: isActive ? 2 : 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: isConnecting ? null : () => _handleToggle(state),
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: widget.size,
                    height: widget.size,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: isConnecting
                            ? SizedBox(
                                width: widget.size * 0.45,
                                height: widget.size * 0.45,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Icon(
                                isActive
                                    ? (isMuted ? Icons.mic_off : Icons.mic)
                                    : Icons.mic_none,
                                key: ValueKey(
                                  '${isActive}_${isMuted}_$isConnecting',
                                ),
                                color: Colors.white,
                                size: widget.size * 0.5,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.showStatus) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      statusText,
                      key: ValueKey(statusText),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
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
                              ? theme.colorScheme.surface
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.4),
                          ),
                        ),
                        child: Icon(
                          isMuted ? Icons.volume_off : Icons.volume_up,
                          size: 14,
                          color: canToggleMute
                              ? statusColor
                              : theme.disabledColor,
                        ),
                      ),
                    ),
                  ],
                ],
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

/// Compact variant - just an icon button without elevation
class VoiceAssistantIconButton extends StatelessWidget {
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool showMuteToggle;

  const VoiceAssistantIconButton({
    super.key,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
    this.showMuteToggle = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceAssistantBloc, VoiceAssistantState>(
      builder: (context, state) {
        final isActive =
            state.connectionStatus == VoiceConnectionStatus.connected;
        final isConnecting =
            state.connectionStatus == VoiceConnectionStatus.connecting;
        final isMuted = state.isMuted;
        final canToggleMute = isActive && !isConnecting;
        final theme = Theme.of(context);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: isConnecting
                  ? null
                  : () {
                      if (isActive) {
                        context.read<VoiceAssistantBloc>().add(
                          const StopVoiceAssistant(),
                        );
                      } else {
                        context.read<VoiceAssistantBloc>().add(
                          const StartVoiceAssistant(),
                        );
                      }
                    },
              icon: isConnecting
                  ? SizedBox(
                      width: size,
                      height: size,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isActive
                          ? (isMuted ? Icons.mic_off : Icons.mic)
                          : Icons.mic_none,
                      color: isActive
                          ? (activeColor ?? theme.colorScheme.primary)
                          : (inactiveColor ?? theme.colorScheme.outline),
                      size: size,
                    ),
            ),
            if (showMuteToggle)
              Positioned(
                right: -2,
                bottom: -2,
                child: InkResponse(
                  onTap: canToggleMute
                      ? () {
                          context.read<VoiceAssistantBloc>().add(
                            const ToggleVoiceAssistantMute(),
                          );
                        }
                      : null,
                  radius: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      isMuted ? Icons.volume_off : Icons.volume_up,
                      size: 12,
                      color: canToggleMute
                          ? theme.colorScheme.primary
                          : theme.disabledColor,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
