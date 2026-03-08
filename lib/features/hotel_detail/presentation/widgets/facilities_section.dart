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
        const SizedBox(height: 4),
        Text(
          'Nikmati fasilitas unggulan untuk pengalaman menginap yang nyaman.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 360 ? 3 : 2;
            return GridView.builder(
              itemCount: facilities.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final facility = facilities[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.deepBlack.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconData(facility.icon),
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _translateFacilityName(facility.name),
                        style: AppTypography.bodySmall.copyWith(
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
              },
            );
          },
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
