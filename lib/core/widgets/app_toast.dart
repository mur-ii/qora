import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

class AppToast {
  AppToast._();

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      type: ToastificationType.info,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      type: ToastificationType.success,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      type: ToastificationType.error,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required ToastificationType type,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.minimal,
      alignment: Alignment.topLeft,
      autoCloseDuration: const Duration(seconds: 3),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      showProgressBar: false,
      title: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(
          color: foregroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
