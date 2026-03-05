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
          child: Text(
            'Promo & Penawaran',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _promos.length,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              // RepaintBoundary isolates each promo card so horizontal-scroll
              // does not re-rasterize the ones that are off-screen.
              return RepaintBoundary(
                child: PromoCard(
                  key: ValueKey(promo['title']),
                  title: promo['title'] as String,
                  subtitle: promo['subtitle'] as String,
                  badge: promo['badge'] as String,
                  color: promo['color'] as Color,
                  icon: promo['icon'] as IconData,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

final List<Map<String, Object>> _promos = [
  {
    'title': 'Diskon 30%',
    'subtitle': 'Hotel berbintang pilihan',
    'badge': 'HOT DEAL',
    'color': AppColors.primary,
    'icon': Icons.local_fire_department_outlined,
  },
  {
    'title': 'Weekend Escape',
    'subtitle': 'Booking Sabtu–Minggu hemat',
    'badge': 'WEEKEND',
    'color': AppColors.success,
    'icon': Icons.weekend_outlined,
  },
  {
    'title': 'Early Bird',
    'subtitle': 'Pesan 2 minggu lebih awal',
    'badge': 'EARLY',
    'color': AppColors.warning,
    'icon': Icons.alarm_outlined,
  },
  {
    'title': 'Keluarga Hemat',
    'subtitle': 'Gratis 1 anak di bawah 12th',
    'badge': 'FAMILY',
    'color': const Color(0xFF7C3AED),
    'icon': Icons.family_restroom_outlined,
  },
];
