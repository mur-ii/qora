import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class HotelHeader extends StatelessWidget {
  final String hotelName;
  final int starRating;
  final VoidCallback onBackPressed;

  const HotelHeader({
    super.key,
    required this.hotelName,
    required this.starRating,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top + 8;
    final visibleStars = starRating.clamp(0, 5);

    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brandGreen, AppColors.primaryOrange],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -32,
                    right: -28,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -46,
                    left: -22,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: AppColors.surfaceWhite,
                        size: 44,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x22000000), Color(0x8A000000)],
              ),
            ),
          ),
          Positioned(
            top: topPadding,
            left: 16,
            child: Material(
              color: AppColors.surfaceWhite.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: 'Kembali',
                onPressed: onBackPressed,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotelName,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.surfaceWhite,
                    fontWeight: FontWeight.w700,
                    shadows: const [
                      Shadow(color: Color(0x66000000), blurRadius: 10),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(
                      visibleStars,
                      (_) => const Padding(
                        padding: EdgeInsets.only(right: 2),
                        child: Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: AppColors.promoGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$visibleStars bintang',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.surfaceWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
