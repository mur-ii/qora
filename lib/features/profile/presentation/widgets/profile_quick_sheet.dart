import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/profile_entity.dart';

/// Modern modal bottom sheet with shortcuts and full profile CTA
class ProfileQuickSheet extends StatelessWidget {
  const ProfileQuickSheet({super.key, required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Profile header
          _buildProfileHeader(),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.textSecondary.withValues(alpha: 0),
                    AppColors.textSecondary.withValues(alpha: 0.3),
                    AppColors.textSecondary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // Quick shortcuts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _QuickShortcut(
                  icon: Icons.credit_card_outlined,
                  title: 'Payment Information',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.profilePath);
                  },
                ),
                const SizedBox(height: 12),
                _QuickShortcut(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Account Management',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.profilePath);
                  },
                ),
                const SizedBox(height: 12),
                _QuickShortcut(
                  icon: Icons.settings_outlined,
                  title: 'Preferences',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.profilePath);
                  },
                ),
                const SizedBox(height: 12),
                _QuickShortcut(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(AppRoutes.profilePath);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // View Full Profile CTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.profilePath);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'View Full Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Avatar with level ring
          Stack(
            alignment: Alignment.center,
            children: [
              // Level ring (static)
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _getLevelColor(), width: 4),
                ),
              ),
              // Avatar
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  profile.fullName.isNotEmpty
                      ? profile.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            profile.fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.deepBlack,
            ),
          ),

          const SizedBox(height: 8),

          // Level info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getLevelColor().withValues(alpha: 0.2),
                  _getLevelColor().withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 16, color: _getLevelColor()),
                const SizedBox(width: 6),
                Text(
                  'Level ${profile.currentLevel} • ${profile.levelTitle}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _getLevelColor(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // XP Progress
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${profile.currentXP} XP',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${profile.xpToNextLevel} XP',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _getLevelColor().withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getLevelColor().withValues(alpha: 0.25),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Progress level ditampilkan numerik',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getLevelColor(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor() {
    if (profile.currentLevel < 5) return AppColors.primaryOrange;
    if (profile.currentLevel < 10) return AppColors.brandGreen;
    if (profile.currentLevel < 20) return AppColors.promoGold;
    if (profile.currentLevel < 30) return AppColors.primaryOrange;
    return AppColors.primaryOrange;
  }
}

class _QuickShortcut extends StatelessWidget {
  const _QuickShortcut({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.deepBlack,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
