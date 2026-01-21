import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/hotel_entity.dart';

class HotelCard extends StatefulWidget {
  const HotelCard({super.key, required this.hotel});

  final HotelEntity hotel;

  @override
  State<HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<HotelCard> {
  bool isFavorite = false;

  String _getRatingCategory(double rating) {
    if (rating >= 9.0) return 'Luar Biasa';
    if (rating >= 8.0) return 'Sangat Baik';
    if (rating >= 7.0) return 'Baik';
    if (rating >= 6.0) return 'Menyenangkan';
    if (rating >= 5.0) return 'Cukup';
    return 'Buruk';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return const Color(0xFF0071C2);
    if (rating >= 7.0) return const Color(0xFF008009);
    if (rating >= 6.0) return const Color(0xFFFF8C00);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final reviewCount = (widget.hotel.rating * 10).toInt();
    final distance = (widget.hotel.rating * 15).toStringAsFixed(1);
    final roomsLeft = widget.hotel.isPromo
        ? (widget.hotel.rating * 0.5).toInt()
        : null;
    final originalPrice = widget.hotel.isPromo
        ? widget.hotel.pricePerNight * 1.75
        : null;

    return GestureDetector(
      onTap: () => context.push('/hotel-detail/${widget.hotel.id}'),
      child: Container(
        height: 155,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hotel Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.hotel.imageUrl,
                    height: 155,
                    width: 120,
                    fit: BoxFit.cover,
                    memCacheHeight: 310,
                    memCacheWidth: 240,
                    maxHeightDiskCache: 310,
                    maxWidthDiskCache: 240,
                    placeholder: (context, url) => Container(
                      height: 155,
                      width: 120,
                      color: Colors.grey[200],
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 155,
                      width: 120,
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.hotel,
                        size: 30,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        isFavorite = !isFavorite;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[700],
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Hotel Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hotel name
                    Text(
                      widget.hotel.name,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Rating score and category
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _getRatingColor(widget.hotel.rating),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(3),
                              topRight: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                          ),
                          child: Text(
                            widget.hotel.rating.toStringAsFixed(1),
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${_getRatingCategory(widget.hotel.rating)} • $reviewCount ulasan',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            '${widget.hotel.location} • $distance km dari pusat',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Rooms left warning
                    if (roomsLeft != null && roomsLeft <= 2)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 11,
                              color: Colors.red[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              roomsLeft == 1
                                  ? '1 tempat tidur'
                                  : '$roomsLeft tempat tidur',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (originalPrice != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              'Rp ${(originalPrice / 1000).toStringAsFixed(0)}.000',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        Text(
                          'Rp ${widget.hotel.pricePerNight.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
