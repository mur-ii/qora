import 'package:flutter/material.dart';

/// Qora Color System — Hotel Booking Brand Identity
class AppColors {
  AppColors._();

  // ==================== BRAND COLORS ====================
  /// Call To Action Orange — buttons, highlights, primary actions
  static const Color primaryOrange = Color(0xFFF37321);
  static const Color primary = primaryOrange;
  static const Color primaryVariant = Color(0xFFE05C10);
  static const Color primaryLight = Color(0xFFFF9549);
  static const Color primaryDark = Color(0xFFB85520);
  static const Color primaryContainer = Color(0xFFFFE8D6);

  /// Brand / Active State Dark Green — navigation, active states
  static const Color brandGreen = Color(0xFF155A32);

  // ==================== SURFACE & BACKGROUND ====================
  /// Pure white — cards, modals, surfaces
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surface = surfaceWhite;

  /// Light grey — page backgrounds
  static const Color backgroundGrey = Color(0xFFF4F5F5);
  static const Color background = backgroundGrey;
  static const Color backgroundVariant = Color(0xFFEEEEEE);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // ==================== NEUTRAL COLORS ====================
  static const Color neutral900 = Color(0xFF212121);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral50 = Color(0xFFFAFAFA);

  // ==================== TEXT COLORS ====================
  /// Primary text — headings, body text
  static const Color textPrimary = Color(0xFF333333);

  /// Secondary text, borders, and placeholders
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textTertiary = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFFE0E0E0);
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

  // ==================== PROMO / ACCENT COLORS ====================
  /// Gold accent — promo banners, special offers
  static const Color promoGold = Color(0xFFD4AF37);
  static const Color promoGoldLight = Color(0xFFFAF0C8);
  static const Color promoGoldDark = Color(0xFFB8960A);

  /// Deep Black — promo banner text, high-contrast elements
  static const Color deepBlack = Color(0xFF000000);

  // ==================== UI ELEMENT COLORS ====================
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocus = primaryOrange;
  static const Color divider = Color(0xFFF4F5F5);
  static const Color transparent = Color(0x00000000);
  static const Color primaryOverlay = Color(0x1FF37321);

  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);

  // ==================== RATING ====================
  static const Color rating = Color(0xFFF59E0B);

  // ==================== STATUS COLORS ====================
  static const Color statusConfirmed = success;
  static const Color statusPending = warning;
  static const Color statusCancelled = textTertiary;
  static const Color statusBooked = primary;

  // ==================== LEGACY ALIASES ====================
  static const Color secondary = brandGreen;
  static const Color secondaryVariant = Color(0xFF0D3D22);
  static const Color secondaryLight = Color(0xFFE8F5E9);
  static const Color secondaryDark = Color(0xFF0A2714);
  static const Color accent = promoGold;
  static const Color accentLight = promoGoldLight;
  static const Color accentDark = promoGoldDark;
  static const Color neutral = Color(0xFF424242);
  static const Color neutralVariant = Color(0xFF333333);
  static const Color neutralLight = Color(0xFF616161);
  static const Color neutralDark = deepBlack;
  static const Color borderDark = Color(0xFFBDBDBD);
  static const Color shadowDark = Color(0x29000000);
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  static const Color scrim = Color(0xB3000000);
  static const Color discount = primary;
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.6;
  static const double opacityHigh = 0.87;
  static const Color cardLight = surfaceWhite;
  static const Color cardDark = neutral;
  static const Color cardActive = neutralLight;
  static const Color cardHover = Color(0xFFFAFAFA);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryOrange, primaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [brandGreen, secondaryVariant],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [promoGold, promoGoldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
