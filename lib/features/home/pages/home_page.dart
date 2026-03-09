import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../voice_assistant/di/voice_assistant_injection.dart';
import '../../voice_assistant/presentation/bloc/voice_assistant_bloc.dart';
import '../../voice_assistant/presentation/bloc/voice_assistant_event.dart';
import '../../voice_assistant/presentation/bloc/voice_assistant_state.dart';
import '../bloc/home_bloc.dart';
import '../widgets/destination_section.dart';
import '../widgets/promo_section.dart';
import '../widgets/search_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(),
      child: const HomeView(),
    );
  }
}

// Extracted to its own StatefulWidget so that toggling voice mode only
// rebuilds this compact row — NOT the entire HomeView/Scaffold/AppBar.
class _VoiceModeRow extends StatelessWidget {
  const _VoiceModeRow();

  void _toggle(BuildContext context, bool enabled) {
    if (enabled) {
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
        builder: (context, state) {
          return _buildToggle(context, status: state.status);
        },
      );
    }

    return ValueListenableBuilder<VoiceAssistantStatus>(
      valueListenable: controller.statusNotifier,
      builder: (context, status, _) {
        return _buildToggle(context, status: status);
      },
    );
  }

  Widget _buildToggle(
    BuildContext context, {
    required VoiceAssistantStatus status,
  }) {
    final enabled = status != VoiceAssistantStatus.idle;

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
              onTap:
                  status == VoiceAssistantStatus.connecting ||
                      status == VoiceAssistantStatus.disconnecting
                  ? null
                  : () => _toggle(context, !enabled),
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

// HomeView is now a StatelessWidget — no more setState here.
// The only stateful child is _VoiceModeRow, scoping rebuilds to just that widget.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.primary,
        centerTitle: false,
        title: Text(
          'Qora',
          style: AppTypography.logo.copyWith(color: AppColors.primary),
        ),
        actions: [
          const _VoiceModeRow(),
          const SizedBox(width: AppTheme.spacingSmall),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: IconButton(
              onPressed: () => context.push(AppRoutes.notificationsPath),
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
          ),
          const SizedBox(width: AppTheme.spacingMedium),
        ],
      ),
      body: BlocListener<HomeBloc, HomeState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == HomeStatus.failure) {
            AppToast.showError(
              context,
              state.errorMessage ?? 'Terjadi kesalahan',
            );
            context.read<HomeBloc>().add(const HomeStatusReset());
          } else if (state.status == HomeStatus.success) {
            AppToast.showInfo(context, 'Mencari hotel...');
            final checkIn = state.checkInDate!.toIso8601String();
            final checkOut = state.checkOutDate!.toIso8601String();

            context.go(
              Uri(
                path: AppRoutes.hotelListPath,
                queryParameters: {
                  'location': state.location,
                  'checkIn': checkIn,
                  'checkOut': checkOut,
                  'rooms': state.roomCount.toString(),
                  'guests': state.guestCount.toString(),
                },
              ).toString(),
            );
            context.read<HomeBloc>().add(const HomeStatusReset());
          }
        },
        child: const _HomeContentList(),
      ),
    );
  }
}

class _HomeContentList extends StatelessWidget {
  const _HomeContentList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: const [
        SearchSection(),
        SizedBox(height: 24),
        PromoSection(),
        SizedBox(height: 24),
        DestinationSection(),
        SizedBox(height: 24),
      ],
    );
  }
}
