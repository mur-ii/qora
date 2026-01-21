import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme.dart';

/// Common widget styles and builders for Qora hotel booking app
/// Use these for consistent UI patterns across the application
class AppWidgets {
  AppWidgets._();

  // ==================== BADGES & LABELS ====================

  /// Discount badge (Golden yellow)
  /// Example: "50% OFF", "Limited Time"
  static Widget discountBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSmall,
        vertical: AppTheme.spacingXSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.discount,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Status badge (for booking status)
  /// Pass appropriate color from AppColors.status*
  static Widget statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSmall,
        vertical: AppTheme.spacingXSmall,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnPrimary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Promotional banner chip
  static Widget promotionalChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnDark,
        ),
      ),
    );
  }

  // ==================== BUTTONS ====================

  /// Primary CTA Button (Search Hotel, Book Now, Confirm, Pay)
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: AppTheme.spacingSmall),
                  ],
                  Text(text),
                ],
              ),
      ),
    );
  }

  /// Secondary action button
  static Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: AppTheme.spacingSmall),
            ],
            Text(text),
          ],
        ),
      ),
    );
  }

  // ==================== PRICE DISPLAY ====================

  /// Price text in primary red color
  /// Example: "$299/night"
  static Widget priceText({
    required String price,
    String? period,
    double fontSize = 20,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: price,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (period != null)
            TextSpan(
              text: period,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: fontSize * 0.6,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  // ==================== RATING DISPLAY ====================

  /// Star rating display
  static Widget starRating({
    required double rating,
    int maxStars = 5,
    double size = 16,
    bool showRatingText = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxStars, (index) {
          if (index < rating.floor()) {
            return Icon(Icons.star, size: size, color: AppColors.rating);
          } else if (index < rating) {
            return Icon(Icons.star_half, size: size, color: AppColors.rating);
          } else {
            return Icon(Icons.star_border, size: size, color: AppColors.rating);
          }
        }),
        if (showRatingText) ...[
          const SizedBox(width: AppTheme.spacingXSmall),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  // ==================== CARDS ====================

  /// Premium hotel card wrapper
  static Widget hotelCard({required Widget child, VoidCallback? onTap}) {
    return Card(
      elevation: AppTheme.elevationSmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: child,
      ),
    );
  }

  /// Dark booking status card
  static Widget bookingCard({required Widget child, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: child,
          ),
        ),
      ),
    );
  }

  // ==================== DIVIDERS ====================

  /// Standard divider
  static Widget divider() {
    return const Divider(
      color: AppColors.divider,
      thickness: 1,
      height: AppTheme.spacingMedium,
    );
  }

  /// Vertical divider
  static Widget verticalDivider() {
    return Container(width: 1, height: 24, color: AppColors.divider);
  }

  // ==================== INFO CHIPS ====================

  /// Icon with text info chip (e.g., location, amenities)
  static Widget infoChip({
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor ?? AppColors.textSecondary),
        const SizedBox(width: AppTheme.spacingXSmall),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: textColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ==================== LOADING & EMPTY STATES ====================

  /// Loading indicator
  static Widget loadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }

  /// Empty state message
  static Widget emptyState({
    required String message,
    IconData? icon,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spacingLarge),
              TextButton(onPressed: onAction, child: Text(actionText)),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== IMAGE PLACEHOLDERS ====================

  /// Image placeholder with shimmer effect hint
  static Widget imagePlaceholder({
    double? width,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Icon(Icons.image, size: 48, color: AppColors.border),
      ),
    );
  }

  // ==================== SEARCH BAR ====================

  /// Search input field
  static Widget searchField({
    required TextEditingController controller,
    required String hint,
    VoidCallback? onTap,
    bool readOnly = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingMedium,
        ),
      ),
    );
  }
}
