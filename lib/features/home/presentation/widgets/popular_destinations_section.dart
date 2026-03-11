import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/home_entity.dart';

class PopularDestinationsSection extends StatelessWidget {
  const PopularDestinationsSection({super.key, required this.destinations});

  final List<DestinationEntity> destinations;

  static const _iconMap = <String, IconData>{
    'beach': Icons.beach_access_rounded,
    'city': Icons.location_city_rounded,
    'mountain': Icons.landscape_rounded,
    'culture': Icons.temple_buddhist_rounded,
    'park': Icons.park_rounded,
    'island': Icons.water_rounded,
  };

  static const _accentMap = <String, Color>{
    'beach': Color(0xFF0EA5E9),
    'city': Color(0xFF6366F1),
    'mountain': Color(0xFF22C55E),
    'culture': Color(0xFFEC4899),
    'park': Color(0xFF14B8A6),
    'island': Color(0xFF3B82F6),
  };

  @override
  Widget build(BuildContext context) {
    if (destinations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Destinasi Populer',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Lihat Semua',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
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
              childAspectRatio: 1.05,
            ),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final dest = destinations[index];
              return _DestinationCard(
                key: ValueKey(dest.name),
                name: dest.name,
                iconData: _iconMap[dest.iconKey] ?? Icons.place_rounded,
                accent: _accentMap[dest.iconKey] ?? AppColors.primary,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    super.key,
    required this.name,
    required this.iconData,
    required this.accent,
  });

  final String name;
  final IconData iconData;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, size: 22, color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
