import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';

/// AppBar-compatible header for the home screen.
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
