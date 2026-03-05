import 'package:flutter/material.dart';

/// Qora Color System — Clean, Professional, Minimal
class AppColors {
  AppColors._();

  // ==================== PRIMARY COLOR ====================
  /// Brand Color — Professional Blue
  static const Color primary = Color(0xFF1D4ED8);
  static const Color primaryVariant = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A8A);
  static const Color primaryContainer = Color(0xFFDBEAFE);

  // ==================== SURFACE & BACKGROUND ====================
  static const Color background = Color(0xFFF9FAFB);
  static const Color backgroundVariant = Color(0xFFF3F4F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // ==================== NEUTRAL COLORS ====================
  static const Color neutral900 = Color(0xFF111827);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral600 = Color(0xFF4B5563);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral50 = Color(0xFFF9FAFB);

  // Text colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ==================== SEMANTIC COLORS ====================
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);

  // ==================== UI ELEMENT COLORS ====================
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFF1D4ED8);
  static const Color divider = Color(0xFFF3F4F6);

  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);

  // ==================== RATING ====================
  static const Color rating = Color(0xFFF59E0B);

  // ==================== STATUS COLORS ====================
  static const Color statusConfirmed = success;
  static const Color statusPending = warning;
  static const Color statusCancelled = neutral400;
  static const Color statusBooked = primary;

  // ==================== LEGACY ALIASES ====================
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color secondaryVariant = Color(0xFF0284C7);
  static const Color secondaryLight = Color(0xFFE0F2FE);
  static const Color secondaryDark = Color(0xFF075985);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFDE68A);
  static const Color accentDark = Color(0xFFD97706);
  static const Color neutral = Color(0xFF1F2937);
  static const Color neutralVariant = Color(0xFF111827);
  static const Color neutralLight = Color(0xFF374151);
  static const Color neutralDark = Color(0xFF000000);
  static const Color borderDark = Color(0xFFD1D5DB);
  static const Color shadowDark = Color(0x29000000);
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  static const Color scrim = Color(0xB3000000);
  static const Color discount = accent;
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  static const Color cardLight = surface;
  static const Color cardDark = neutral;
  static const Color cardActive = neutralLight;
  static const Color cardHover = Color(0xFFFAFAFA);

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
}
