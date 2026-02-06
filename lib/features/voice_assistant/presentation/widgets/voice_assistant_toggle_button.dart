import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_colors.dart';
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
      if (state.connectionStatus == VoiceConnectionStatus.disconnected ||
          state.connectionStatus == VoiceConnectionStatus.failed) {
        context.read<VoiceAssistantBloc>().add(const StartVoiceAssistant());
      }
    } else {
      if (state.connectionStatus == VoiceConnectionStatus.connected) {
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
          isActive: isActive,
          isConnecting: isConnecting,
          isFailed: isFailed,
          isMuted: isMuted,
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
                    activeColor: activeColor,
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

class DraggableVoiceAssistantOverlay extends StatefulWidget {
  final Widget child;
  final Widget button;
  final EdgeInsets padding;
  final Size estimatedButtonSize;

  const DraggableVoiceAssistantOverlay({
    super.key,
    required this.child,
    required this.button,
    this.padding = const EdgeInsets.all(16),
    this.estimatedButtonSize = const Size(72, 96),
  });

  @override
  State<DraggableVoiceAssistantOverlay> createState() =>
      _DraggableVoiceAssistantOverlayState();
}

class _DraggableVoiceAssistantOverlayState
    extends State<DraggableVoiceAssistantOverlay> {
  final ValueNotifier<Offset> _position = ValueNotifier(Offset.zero);
  final GlobalKey _buttonKey = GlobalKey();
  Size _buttonSize = Size.zero;
  bool _positionInitialized = false;

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _syncButtonSize(Size areaSize, EdgeInsets safePadding) {
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final newSize = renderBox.size;
    if (newSize == _buttonSize) return;

    _buttonSize = newSize;
    _position.value = _clampPosition(_position.value, areaSize, safePadding);
  }

  void _initializePosition(Size areaSize, EdgeInsets safePadding) {
    if (_positionInitialized) return;

    final fallbackSize = _buttonSize == Size.zero
        ? widget.estimatedButtonSize
        : _buttonSize;
    final initial = Offset(
      areaSize.width - fallbackSize.width - safePadding.right,
      areaSize.height - fallbackSize.height - safePadding.bottom,
    );
    _position.value = _clampPosition(initial, areaSize, safePadding);
    _positionInitialized = true;
  }

  Offset _clampPosition(
    Offset position,
    Size areaSize,
    EdgeInsets safePadding,
  ) {
    final size = _buttonSize == Size.zero
        ? widget.estimatedButtonSize
        : _buttonSize;
    final maxX = math.max(
      safePadding.left,
      areaSize.width - size.width - safePadding.right,
    );
    final maxY = math.max(
      safePadding.top,
      areaSize.height - size.height - safePadding.bottom,
    );
    final minX = safePadding.left;
    final minY = safePadding.top;

    return Offset(position.dx.clamp(minX, maxX), position.dy.clamp(minY, maxY));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final safePadding = widget.padding.copyWith(
      left: widget.padding.left + media.padding.left,
      top: widget.padding.top + media.padding.top,
      right: widget.padding.right + media.padding.right,
      bottom:
          widget.padding.bottom +
          media.padding.bottom +
          media.viewInsets.bottom,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final areaSize = Size(constraints.maxWidth, constraints.maxHeight);
        _initializePosition(areaSize, safePadding);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncButtonSize(areaSize, safePadding);
        });

        return Stack(
          children: [
            widget.child,
            ValueListenableBuilder<Offset>(
              valueListenable: _position,
              builder: (context, offset, child) {
                final clamped = _clampPosition(offset, areaSize, safePadding);

                return Positioned(
                  left: clamped.dx,
                  top: clamped.dy,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      final next = offset + details.delta;
                      _position.value = _clampPosition(
                        next,
                        areaSize,
                        safePadding,
                      );
                    },
                    child: RepaintBoundary(key: _buttonKey, child: child),
                  ),
                );
              },
              child: widget.button,
            ),
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
