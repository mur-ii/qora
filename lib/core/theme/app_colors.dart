import 'package:flutter/material.dart';

/// Qora Color System
/// A modern hotel booking application color palette designed for
/// clean, professional, and premium user experience.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ==================== PRIMARY COLOR ====================
  /// Brand Color - Vibrant Red
  /// Usage: Primary CTA buttons, price text, important status labels
  static const Color primary = Color(0xFFFF2D2D);
  static const Color primaryVariant = Color(0xFFF53B3B);
  static const Color primaryLight = Color(0xFFFF6666);
  static const Color primaryDark = Color(0xFFCC2424);

  // ==================== SECONDARY COLOR ====================
  /// Sky Blue
  /// Usage: Promotional banners, hotel highlights, featured deals
  static const Color secondary = Color(0xFF6BCBFF);
  static const Color secondaryVariant = Color(0xFF5AC8FA);
  static const Color secondaryLight = Color(0xFF9DDBFF);
  static const Color secondaryDark = Color(0xFF3AAFE0);

  // ==================== SURFACE & BACKGROUND ====================
  /// Light & Clean backgrounds
  /// Usage: Main app background, screen containers
  static const Color background = Color(0xFFF8F8F8);
  static const Color backgroundVariant = Color(0xFFF2F2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // ==================== NEUTRAL COLORS ====================
  /// Dark Grey / Near Black
  /// Usage: Navigation, cards, active states, important text
  static const Color neutral = Color(0xFF1C1C1E);
  static const Color neutralVariant = Color(0xFF121212);
  static const Color neutralLight = Color(0xFF2C2C2E);
  static const Color neutralDark = Color(0xFF000000);

  // Text colors
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ==================== ACCENT COLOR ====================
  /// Golden Yellow
  /// Usage: Discount badges, limited-time offers, special highlights
  static const Color accent = Color(0xFFFFCC00);
  static const Color accentLight = Color(0xFFFFDD66);
  static const Color accentDark = Color(0xFFCCA300);

  // ==================== SEMANTIC COLORS ====================
  /// Success, warning, error states
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // ==================== UI ELEMENT COLORS ====================
  /// Borders, dividers, shadows
  static const Color border = Color(0xFFE5E5E5);
  static const Color borderDark = Color(0xFFCCCCCC);
  static const Color divider = Color(0xFFEEEEEE);

  /// Shadow colors for elevation
  static const Color shadowLight = Color(0x0F000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowDark = Color(0x33000000);

  // ==================== OVERLAY COLORS ====================
  /// For modals, sheets, and overlays
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  static const Color scrim = Color(0xB3000000);

  // ==================== RATING & SPECIAL ====================
  /// Star ratings and special badges
  static const Color rating = Color(0xFFFFB800);
  static const Color discount = accent;

  // ==================== OPACITY HELPERS ====================
  /// Common opacity values for consistent UI
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;

  // ==================== GRADIENT DEFINITIONS ====================
  /// Premium gradients for special UI elements
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==================== STATUS COLORS ====================
  /// For booking status indicators
  static const Color statusBooked = primary;
  static const Color statusPreparing = Color(0xFFFF9500);
  static const Color statusConfirmed = Color(0xFF34C759);
  static const Color statusCancelled = Color(0xFF8E8E93);
  static const Color statusPending = secondaryVariant;

  // ==================== CARD COLORS ====================
  /// Specific card background colors
  static const Color cardLight = surface;
  static const Color cardDark = neutral;
  static const Color cardActive = neutralLight;
  static const Color cardHover = Color(0xFFFAFAFA);
}
