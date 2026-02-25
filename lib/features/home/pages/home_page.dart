import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/performance_tracked_page.dart';
import '../../voice_assistant/presentation/bloc/voice_assistant_bloc.dart';
import '../../voice_assistant/presentation/bloc/voice_assistant_event.dart';
import '../../voice_assistant/presentation/bloc/voice_assistant_state.dart';
import '../../voice_assistant/presentation/widgets/voice_assistant_toggle_button.dart';
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

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _voiceModeEnabled = true;

  void _toggleVoiceMode(bool enabled) {
    if (!enabled) {
      final voiceState = context.read<VoiceAssistantBloc>().state;
      if (voiceState.connectionStatus == VoiceConnectionStatus.connected ||
          voiceState.connectionStatus == VoiceConnectionStatus.connecting) {
        context.read<VoiceAssistantBloc>().add(const StopVoiceAssistant());
      }
    }

    setState(() {
      _voiceModeEnabled = enabled;
    });
  }

  Widget _buildModeLabel(String text, bool isActive) {
    return Text(
      text,
      style: AppTypography.labelSmall.copyWith(
        color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildVoiceModeSwitch() {
    return Semantics(
      button: true,
      label: 'Voice mode',
      toggled: _voiceModeEnabled,
      child: GestureDetector(
        onTap: () => _toggleVoiceMode(!_voiceModeEnabled),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 42,
          height: 22,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: _voiceModeEnabled
                ? AppColors.primary.withOpacity(0.9)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _voiceModeEnabled ? AppColors.primary : AppColors.border,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: _voiceModeEnabled
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _voiceModeEnabled
                    ? AppColors.surface
                    : AppColors.textTertiary,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PerformanceTrackedPage(
      pageName: 'Home Page',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          centerTitle: false,
          title: Text(
            'Qora',
            style: AppTypography.logo.copyWith(color: AppColors.primary),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
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
                        _buildModeLabel('Manual', !_voiceModeEnabled),
                        const SizedBox(width: 8),
                        _buildVoiceModeSwitch(),
                        const SizedBox(width: 8),
                        _buildModeLabel('Voice AI', _voiceModeEnabled),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      onPressed: () {
                        context.push('/notifications');
                      },
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      splashRadius: 18,
                      tooltip: 'Notifications',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: BlocListener<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state.status == HomeStatus.failure) {
              AppToast.showError(
                context,
                state.errorMessage ?? 'Terjadi kesalahan',
              );
            } else if (state.status == HomeStatus.success) {
              // TODO: Navigate to search results
              AppToast.showInfo(context, 'Mencari hotel...');
            }
          },
          child: _voiceModeEnabled
              ? DraggableVoiceAssistantOverlay(
                  estimatedButtonSize: const Size(64, 64),
                  button: Material(
                    color: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: const Center(
                        child: VoiceAssistantIconButton(
                          size: 26,
                          showMuteToggle: false,
                        ),
                      ),
                    ),
                  ),
                  child: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SearchSection(),
                        SizedBox(height: 24),
                        PromoSection(),
                        SizedBox(height: 24),
                        DestinationSection(),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                )
              : const SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SearchSection(),
                      SizedBox(height: 24),
                      PromoSection(),
                      SizedBox(height: 24),
                      DestinationSection(),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
