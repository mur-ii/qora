import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class DestinationSection extends StatelessWidget {
  const DestinationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Destinasi Populer',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            primary: false,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
            ),
            itemCount: _destinations.length,
            itemBuilder: (context, index) {
              final d = _destinations[index];
              return _DestinationCard(name: d['name']!, icon: d['icon']!);
            },
          ),
        ),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({required this.name, required this.icon});

  final String name;
  final String icon;

  static const _iconMap = <String, IconData>{
    'beach': Icons.beach_access_outlined,
    'city': Icons.location_city_outlined,
    'mountain': Icons.landscape_outlined,
    'culture': Icons.temple_buddhist_outlined,
    'park': Icons.park_outlined,
    'island': Icons.water_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final iconData = _iconMap[icon] ?? Icons.place_outlined;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, size: 26, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            name,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

const List<Map<String, String>> _destinations = [
  {'name': 'Bali', 'icon': 'beach'},
  {'name': 'Jakarta', 'icon': 'city'},
  {'name': 'Bandung', 'icon': 'mountain'},
  {'name': 'Yogyakarta', 'icon': 'culture'},
  {'name': 'Surabaya', 'icon': 'city'},
  {'name': 'Lombok', 'icon': 'island'},
];
