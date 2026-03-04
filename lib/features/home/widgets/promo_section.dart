import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'promo_card.dart';

class PromoSection extends StatelessWidget {
  const PromoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Promo & Penawaran',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: null,
                child: Text(
                  'Lihat Semua',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _promos.length,
            itemExtent: 292, // Card width (280) + margin (12)
            cacheExtent: 900,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return RepaintBoundary(
                child: PromoCard(key: ValueKey(promo), imagePath: promo),
              );
            },
          ),
        ),
      ],
    );
  }
}

const List<String> _promos = [
  'assets/images/banner-promo-1.webp',
  'assets/images/banner-promo-2.webp',
  'assets/images/banner-promo-3.webp',
  'assets/images/banner-promo-4.webp',
];
