import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'destination_card.dart';

class DestinationSection extends StatelessWidget {
  const DestinationSection({super.key});

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
                'Destinasi',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all destinations
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: _destinations.length,
            itemBuilder: (context, index) {
              final destination = _destinations[index];
              return GestureDetector(
                onTap: () {
                  // TODO: Navigate to province hotels
                },
                child: DestinationCard(
                  key: ValueKey(destination['name']),
                  name: destination['name']!,
                  imageUrl: destination['imageUrl']!,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

final List<Map<String, String>> _destinations = [
  {
    'name': 'Bali',
    'imageUrl':
        'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800',
  },
  {
    'name': 'DKI Jakarta',
    'imageUrl':
        'https://images.unsplash.com/photo-1591825729269-caeb344f6df2?w=800',
  },
  {
    'name': 'Jawa Barat',
    'imageUrl':
        'https://images.unsplash.com/photo-1601933973783-43cf8a7d4c5f?w=800',
  },
  {
    'name': 'Jawa Tengah',
    'imageUrl':
        'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=800',
  },
  {
    'name': 'Jawa Timur',
    'imageUrl':
        'https://images.unsplash.com/photo-1548048026-5a1a941d93d3?w=800',
  },
  {
    'name': 'Sumatera Utara',
    'imageUrl':
        'https://images.unsplash.com/photo-1587474260584-136574528ed5?w=800',
  },
];
