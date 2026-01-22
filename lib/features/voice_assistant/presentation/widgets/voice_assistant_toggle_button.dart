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
  final String? activeLabel;
  final String? inactiveLabel;

  const VoiceAssistantToggleButton({
    super.key,
    this.size = 56,
    this.activeColor,
    this.inactiveColor,
    this.showLabel = false,
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceAssistantBloc, VoiceAssistantState>(
      builder: (context, state) {
        final isActive =
            state.connectionStatus == VoiceConnectionStatus.connected;
        final isConnecting =
            state.connectionStatus == VoiceConnectionStatus.connecting;
        final isFailed = state.connectionStatus == VoiceConnectionStatus.failed;

        final activeColor =
            widget.activeColor ?? Theme.of(context).primaryColor;
        final inactiveColor = widget.inactiveColor ?? Colors.grey[300]!;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              elevation: isActive ? 8 : 4,
              shape: const CircleBorder(),
              color: isActive ? activeColor : inactiveColor,
              child: InkWell(
                onTap: isConnecting ? null : () => _handleToggle(state),
                customBorder: const CircleBorder(),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  padding: const EdgeInsets.all(12),
                  child: isConnecting
                      ? CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        )
                      : Icon(
                          isActive ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: widget.size * 0.5,
                        ),
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  isActive
                      ? widget.activeLabel!
                      : (isFailed ? 'Failed' : widget.inactiveLabel!),
                  key: ValueKey(isActive),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive
                        ? activeColor
                        : (isFailed ? Colors.red : Colors.grey[600]),
                  ),
                ),
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 4),
              Text(
                'Error',
                style: TextStyle(fontSize: 10, color: Colors.red[700]),
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

  const VoiceAssistantIconButton({
    super.key,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VoiceAssistantBloc, VoiceAssistantState>(
      builder: (context, state) {
        final isActive =
            state.connectionStatus == VoiceConnectionStatus.connected;
        final isConnecting =
            state.connectionStatus == VoiceConnectionStatus.connecting;

        return IconButton(
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
                  isActive ? Icons.mic : Icons.mic_none,
                  color: isActive
                      ? (activeColor ?? Theme.of(context).primaryColor)
                      : (inactiveColor ?? Colors.grey),
                  size: size,
                ),
        );
      },
    );
  }
}
