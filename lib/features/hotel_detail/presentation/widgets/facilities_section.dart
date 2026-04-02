import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/hotel_detail_entity.dart';

class FacilitiesSection extends StatelessWidget {
  final List<FacilityEntity> facilities;

  const FacilitiesSection({super.key, required this.facilities});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fasilitas Hotel',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: facilities
              .map(
                (facility) => _FacilityChip(
                  icon: _getIconData(facility.icon),
                  label: _translateFacilityName(facility.name),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  String _translateFacilityName(String name) {
    final normalized = name.toLowerCase();
    const dictionary = {
      'free wifi': 'WiFi Gratis',
      'wifi gratis': 'WiFi Gratis',
      'swimming pool': 'Kolam Renang',
      'infinity pool': 'Kolam Renang',
      'pool': 'Kolam Renang',
      'fitness center': 'Pusat Kebugaran',
      'gym': 'Pusat Kebugaran',
      'restaurant': 'Restoran',
      'beachfront restaurant': 'Restoran Pantai',
      'spa & wellness': 'Spa dan Wellness',
      '24/7 room service': 'Layanan Kamar 24 Jam',
      'room service': 'Layanan Kamar',
      'free parking': 'Parkir Gratis',
      'parking': 'Parkir',
      'airport shuttle': 'Antar Jemput Bandara',
      'private beach': 'Pantai Pribadi',
      'sunset bar': 'Bar Sunset',
      'business center': 'Pusat Bisnis',
      'meeting rooms': 'Ruang Rapat',
    };
    return dictionary[normalized] ?? name;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'wifi':
        return Icons.wifi;
      case 'pool':
        return Icons.pool;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'restaurant':
        return Icons.restaurant;
      case 'spa':
        return Icons.spa;
      case 'room_service':
        return Icons.room_service;
      case 'local_parking':
        return Icons.local_parking;
      case 'airport_shuttle':
        return Icons.airport_shuttle;
      case 'beach_access':
        return Icons.beach_access;
      case 'local_bar':
        return Icons.local_bar;
      case 'business_center':
        return Icons.business_center;
      case 'meeting_room':
        return Icons.meeting_room;
      default:
        return Icons.check_circle;
    }
  }
}

class _FacilityChip extends StatelessWidget {
  const _FacilityChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
