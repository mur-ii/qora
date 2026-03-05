import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
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
          'Tipe Kamar',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pilih tipe kamar yang Anda inginkan',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.roomTypes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final room = widget.roomTypes[index];
            final isSelected = widget.selectedRoomId == room.id;

            return InkWell(
              onTap: () => widget.onRoomSelected(room.id),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.04)
                      : AppColors.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: icon + name + price + check
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryContainer
                                : AppColors.neutral100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.bed_outlined,
                            size: 24,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                room.description,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Info chips
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _RoomInfoChip(
                          icon: Icons.people_outline,
                          label: '${room.maxGuests} Tamu',
                        ),
                        _RoomInfoChip(
                          icon: Icons.square_foot_outlined,
                          label: '${room.size} m²',
                        ),
                        _RoomInfoChip(
                          icon: Icons.bed_outlined,
                          label: room.bedType,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Amenities chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: room.amenities.take(4).map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neutral100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            amenity,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (room.amenities.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '+${room.amenities.length - 4} fasilitas lainnya',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    // Price row
                    Row(
                      children: [
                        Text(
                          formatter.format(room.pricePerNight),
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          ' / malam',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
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
        Icon(icon, size: 15, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
