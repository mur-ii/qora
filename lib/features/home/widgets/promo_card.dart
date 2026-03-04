import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class PromoCard extends StatelessWidget {
  const PromoCard({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 170,
      margin: const EdgeInsets.only(right: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: AppTheme.elevationLarge,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.low,
          cacheWidth: 560,
          cacheHeight: 340,
        ),
      ),
    );
  }
}
