import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/profile_injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_bloc.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_state.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileInjection.createBloc(),
      child: const _ProfilePageContent(),
    );
  }
}

class _ProfilePageContent extends StatelessWidget {
  const _ProfilePageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundVariant,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.backgroundVariant,
        title: Text(
          'Profil',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat profil',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompactProfileCard(profile: state.profile),
                  const SizedBox(height: 12),
                  const _VoiceSessionMetricsPanel(),
                  const SizedBox(height: 12),
                  _CompactMenuSection(
                    onTapProfile: () => _onMenuTap(context, 'Profil Saya'),
                    onTapChangePassword: () =>
                        _onMenuTap(context, 'Ganti Password'),
                    onTapReward: () => _onMenuTap(context, 'Reward'),
                    onTapContact: () => _onMenuTap(context, 'Hubungi Kami'),
                  ),
                  const SizedBox(height: 16),
                  _LogoutButton(onPressed: () => _handleLogout(context)),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _onMenuTap(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label segera tersedia')));
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.go(AppRoutes.loginPath);
    }
  }
}

class _CompactProfileCard extends StatelessWidget {
  const _CompactProfileCard({required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final memberSince = DateFormat('dd MMM yyyy').format(profile.joinedDate);
    final coin = NumberFormat('#,###').format(profile.currentXP);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  profile.fullName.isNotEmpty
                      ? profile.fullName[0].toUpperCase()
                      : '?',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.brandGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  profile.fullName,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'Member since', value: memberSince),
          _InfoRow(label: 'Nomor telepon', value: profile.phoneNumber),
          _InfoRow(label: 'Coin', value: coin),
          const _InfoRow(label: 'Membership', value: 'Guest Membership'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceSessionMetricsPanel extends StatelessWidget {
  const _VoiceSessionMetricsPanel();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      VoiceAssistantBloc,
      VoiceAssistantState,
      ({String? sessionId, int totalTokens, double totalCostUsd})
    >(
      selector: (state) => (
        sessionId: state.currentSessionId,
        totalTokens: state.totalLoggedTokens,
        totalCostUsd: state.sessionEstimatedCostUsd,
      ),
      builder: (context, metrics) {
        final sessionLabel =
            (metrics.sessionId == null || metrics.sessionId!.isEmpty)
            ? '-'
            : metrics.sessionId!;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Voice Session (Realtime)',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _InfoRow(label: 'Session ID', value: sessionLabel),
              _InfoRow(
                label: 'Total Token',
                value: NumberFormat('#,###').format(metrics.totalTokens),
              ),
              _InfoRow(
                label: 'Estimated Cost',
                value: '\$${metrics.totalCostUsd.toStringAsFixed(6)}',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactMenuSection extends StatelessWidget {
  const _CompactMenuSection({
    required this.onTapProfile,
    required this.onTapChangePassword,
    required this.onTapReward,
    required this.onTapContact,
  });

  final VoidCallback onTapProfile;
  final VoidCallback onTapChangePassword;
  final VoidCallback onTapReward;
  final VoidCallback onTapContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.person_outline,
            title: 'Profile Saya',
            onTap: onTapProfile,
          ),
          _MenuTile(
            icon: Icons.lock_outline,
            title: 'Ganti Password',
            onTap: onTapChangePassword,
          ),
          _MenuTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Reward',
            onTap: onTapReward,
          ),
          _MenuTile(
            icon: Icons.support_agent,
            title: 'Hubungi Kami',
            onTap: onTapContact,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isLast ? Radius.zero : const Radius.circular(16),
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brandGreen, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.surfaceWhite,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
