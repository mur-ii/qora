import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        color: Colors.white,
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
              color: Colors.grey[300],
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
                    Colors.grey.withValues(alpha: 0),
                    Colors.grey.withValues(alpha: 0.3),
                    Colors.grey.withValues(alpha: 0),
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
                    context.push('/profile');
                  },
                ),
                const SizedBox(height: 12),
                _QuickShortcut(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Account Management',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),
                const SizedBox(height: 12),
                _QuickShortcut(
                  icon: Icons.settings_outlined,
                  title: 'Preferences',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),
                const SizedBox(height: 12),
                _QuickShortcut(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
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
                  context.push('/profile');
                },
                style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
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
              // Level progress ring
              SizedBox(
                width: 88,
                height: 88,
                child: CircularProgressIndicator(
                  value: profile.levelProgress,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor()),
                ),
              ),
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: profile.avatarUrl,
                    fit: BoxFit.cover,
                    memCacheHeight: 144,
                    memCacheWidth: 144,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 36),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 36),
                    ),
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
              color: Color(0xFF1A1A1A),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '${profile.xpToNextLevel} XP',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: profile.levelProgress,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getLevelColor() {
    if (profile.currentLevel < 5) return const Color(0xFF42A5F5);
    if (profile.currentLevel < 10) return const Color(0xFF43A047);
    if (profile.currentLevel < 20) return const Color(0xFF8E24AA);
    if (profile.currentLevel < 30) return const Color(0xFFF4511E);
    return const Color(0xFFF57C00);
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
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
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
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
