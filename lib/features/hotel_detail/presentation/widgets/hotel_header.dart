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
    final topPadding = MediaQuery.paddingOf(context).top + 10;
    final visibleStars = starRating.clamp(0, 5);
    const heroBorderRadius = BorderRadius.vertical(bottom: Radius.circular(26));

    return SizedBox(
      height: 320,
      child: ClipRRect(
        borderRadius: heroBorderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F2D24),
                    Color(0xFF1B5E48),
                    Color(0xFFAA7446),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -40,
                    right: -32,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -55,
                    left: -30,
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 24,
                    bottom: 40,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.surfaceWhite.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: AppColors.surfaceWhite,
                        size: 42,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x11000000), Color(0x9A000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              top: topPadding,
              left: 16,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.deepBlack.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: 'Kembali',
                  onPressed: onBackPressed,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
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
                  const SizedBox(height: 8),
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
                          color: AppColors.surfaceWhite.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
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
      ),
    );
  }
}
