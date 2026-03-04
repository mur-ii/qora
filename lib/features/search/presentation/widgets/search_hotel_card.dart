import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/search_hotel_entity.dart';

class SearchHotelCard extends StatelessWidget {
  final SearchHotelEntity hotel;

  const SearchHotelCard({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return GestureDetector(
      onTap: () {
        context.push(AppRoutes.hotelDetailPathFor(hotel.id));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusMedium),
                    topRight: Radius.circular(AppTheme.radiusMedium),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: hotel.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 160,
                      color: AppColors.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 160,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.hotel, size: 40, color: AppColors.border),
                    ),
                  ),
                ),
                if (hotel.isPromo)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.discount,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PROMO',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Hotel Info
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.location,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRatingColor(hotel.rating),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: AppColors.textOnPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              hotel.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${hotel.reviewCount} reviews)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatter.format(hotel.pricePerNight),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '/ night',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
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

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) {
      return AppColors.success;
    } else if (rating >= 4.0) {
      return AppColors.info;
    } else if (rating >= 3.5) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }
}
