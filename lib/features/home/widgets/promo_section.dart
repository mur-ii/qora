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
                onPressed: () {
                  // TODO: Navigate to all promos
                },
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
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _promos.length,
            itemExtent: 292, // Card width (280) + margin (12)
            cacheExtent: 600, // Preload cards for smooth scrolling
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return PromoCard(
                key: ValueKey(promo['title']),
                title: promo['title']!,
                subtitle: promo['subtitle']!,
                color: promo['color'] as Color,
              );
            },
          ),
        ),
      ],
    );
  }
}

final List<Map<String, dynamic>> _promos = [
  {
    'title': 'Diskon 50%',
    'subtitle': 'Untuk pengguna baru! Nikmati diskon hingga 50%',
    'color': AppColors.primary,
  },
  {
    'title': 'Gratis Sarapan',
    'subtitle': 'Booking hotel pilihan dan dapatkan sarapan gratis',
    'color': const Color(0xFFFF6B6B),
  },
  {
    'title': 'Cashback 100rb',
    'subtitle': 'Minimal transaksi 500rb dapat cashback',
    'color': const Color(0xFF4ECDC4),
  },
  {
    'title': 'Weekend Sale',
    'subtitle': 'Promo khusus weekend, diskon up to 40%',
    'color': const Color(0xFFFFBE0B),
  },
];
