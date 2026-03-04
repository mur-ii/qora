import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/optimized_network_image.dart';
import '../../domain/entities/hotel_detail_entity.dart';

class RoomTypesSection extends StatefulWidget {
  final List<RoomTypeEntity> roomTypes;
  final Function(String roomId) onRoomSelected;
  final String? selectedRoomId;

  const RoomTypesSection({
    super.key,
    required this.roomTypes,
    required this.onRoomSelected,
    this.selectedRoomId,
  });

  @override
  State<RoomTypesSection> createState() => _RoomTypesSectionState();
}

class _RoomTypesSectionState extends State<RoomTypesSection> {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Room Types',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select your preferred room type',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.roomTypes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final room = widget.roomTypes[index];
            final isSelected = widget.selectedRoomId == room.id;

            return InkWell(
              onTap: () => widget.onRoomSelected(room.id),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.05)
                      : Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room Image
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: OptimizedNetworkImage(
                            imageUrl: room.imageUrl,
                            height: 180,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 180,
                              color: Colors.grey[200],
                              child: const Icon(Icons.hotel, size: 48),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Room Details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Room Name and Price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  room.name,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatter.format(room.pricePerNight),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                  Text(
                                    'per malam',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Description
                          Text(
                            room.description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[700]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),

                          // Room Info
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _RoomInfoChip(
                                icon: Icons.people,
                                label: '${room.maxGuests} Tamu',
                              ),
                              _RoomInfoChip(
                                icon: Icons.square_foot,
                                label: '${room.size} m²',
                              ),
                              _RoomInfoChip(
                                icon: Icons.bed,
                                label: room.bedType,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Amenities
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: room.amenities.take(4).map((amenity) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  amenity,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                ),
                              );
                            }).toList(),
                          ),
                          if (room.amenities.length > 4)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '+${room.amenities.length - 4} more amenities',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RoomInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RoomInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
