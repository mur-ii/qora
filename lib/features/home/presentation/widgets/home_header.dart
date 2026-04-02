import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/voice_assistant_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_bloc.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_event.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_state.dart';

/// AppBar-compatible header for the home screen.
///
/// Extracted from [HomeView] so the voice toggle can observe and rebuild
/// independently without involving the rest of the scaffold.
class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const HomeHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.surfaceWhite,
      foregroundColor: AppColors.primary,
      centerTitle: false,
      title: Text(
        'Qora Smart',
        style: AppTypography.logo.copyWith(color: AppColors.primary),
      ),
      actions: [
        const _VoiceModeToggle(),
        const SizedBox(width: AppTheme.spacingSmall),
        _NotificationButton(
          onPressed: () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text(
                    'Fitur notifikasi masih dalam tahap pengembangan',
                  ),
                ),
              );
          },
        ),
        const SizedBox(width: AppTheme.spacingMedium),
      ],
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(
          Icons.notifications_outlined,
          color: AppColors.textPrimary,
          size: 20,
        ),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        splashRadius: 18,
        tooltip: 'Notifications',
      ),
    );
  }
}

/// Scoped widget so the voice-toggle only — not the entire header — rebuilds
/// when [VoiceAssistantStatus] changes.
class _VoiceModeToggle extends StatelessWidget {
  const _VoiceModeToggle();

  void _toggle(BuildContext context, bool enable) {
    if (enable) {
      context.read<VoiceAssistantBloc>().add(const StartVoiceAssistant());
    } else {
      final voiceState = context.read<VoiceAssistantBloc>().state;
      if (voiceState.status != VoiceAssistantStatus.idle) {
        context.read<VoiceAssistantBloc>().add(const StopVoiceAssistant());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = VoiceAssistantInjection.tryGetVoiceAssistantController();

    if (controller == null) {
      return BlocBuilder<VoiceAssistantBloc, VoiceAssistantState>(
        builder: (context, state) =>
            _buildToggle(context, status: state.status),
      );
    }

    return ValueListenableBuilder<VoiceAssistantStatus>(
      valueListenable: controller.statusNotifier,
      builder: (context, status, _) => _buildToggle(context, status: status),
    );
  }

  Widget _buildToggle(
    BuildContext context, {
    required VoiceAssistantStatus status,
  }) {
    final enabled = status != VoiceAssistantStatus.idle;
    final isTransitioning =
        status == VoiceAssistantStatus.connecting ||
        status == VoiceAssistantStatus.disconnecting;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeLabel(text: 'Manual', isActive: !enabled),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Voice mode',
            toggled: enabled,
            child: GestureDetector(
              onTap: isTransitioning ? null : () => _toggle(context, !enabled),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 42,
                height: 22,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: enabled
                      ? AppColors.primary.withValues(alpha: 0.9)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: enabled ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: enabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: enabled
                          ? AppColors.surface
                          : AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _ModeLabel(text: 'Voice AI', isActive: enabled),
        ],
      ),
    );
  }
}

class _ModeLabel extends StatelessWidget {
  const _ModeLabel({required this.text, required this.isActive});

  final String text;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelSmall.copyWith(
        color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}
