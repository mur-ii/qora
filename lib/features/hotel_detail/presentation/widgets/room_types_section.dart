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
  static final NumberFormat _formatter = NumberFormat.currency(
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
          'Pilihan Kamar',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pilih kamar yang paling sesuai dengan kebutuhan Anda.',
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

            return _RoomCard(
              room: room,
              isSelected: isSelected,
              onSelect: () => widget.onRoomSelected(room.id),
              priceText: _formatter.format(room.pricePerNight),
            );
          },
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomTypeEntity room;
  final bool isSelected;
  final VoidCallback onSelect;
  final String priceText;

  const _RoomCard({
    required this.room,
    required this.isSelected,
    required this.onSelect,
    required this.priceText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlack.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _RoomImagePlaceholder(),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceWhite.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.surfaceWhite.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'Kamar Pilihan',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.surfaceWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.deepBlack.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${room.maxGuests} tamu',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.surfaceWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  room.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _RoomInfoChip(
                      icon: Icons.people_outline,
                      label: '${room.maxGuests} Tamu',
                    ),
                    _RoomInfoChip(
                      icon: Icons.square_foot_outlined,
                      label: '${room.size} m2',
                    ),
                    _RoomInfoChip(
                      icon: Icons.bed_outlined,
                      label: _translateBedType(room.bedType),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: room.amenities.take(4).map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _translateAmenity(amenity),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            priceText,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'per malam',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 118),
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: onSelect,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            minimumSize: const Size(118, 46),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            backgroundColor: isSelected
                                ? AppColors.brandGreen
                                : AppColors.primary,
                            foregroundColor: AppColors.surfaceWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              isSelected ? 'Dipilih' : 'Pilih Kamar',
                              maxLines: 1,
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _translateAmenity(String amenity) {
    final normalized = amenity.toLowerCase();
    const dictionary = {
      'free wifi': 'WiFi Gratis',
      'air conditioning': 'AC',
      'tv': 'TV',
      'mini bar': 'Mini Bar',
      'coffee maker': 'Pembuat Kopi',
      'bathtub': 'Bathtub',
      'living room': 'Ruang Tamu',
      'city view': 'Pemandangan Kota',
      'ocean view': 'Pemandangan Laut',
      'balcony': 'Balkon',
      'private pool': 'Kolam Pribadi',
      'beach access': 'Akses Pantai',
      'kitchen': 'Dapur',
      'jacuzzi': 'Jacuzzi',
      'champagne': 'Champagne',
      'flowers': 'Dekorasi Bunga',
      'work desk': 'Meja Kerja',
      'kitchenette': 'Dapur Mini',
    };
    return dictionary[normalized] ?? amenity;
  }

  String _translateBedType(String bedType) {
    return bedType
        .replaceAll('King Bed', 'Kasur King')
        .replaceAll('Queen Bed', 'Kasur Queen')
        .replaceAll('Sofa Bed', 'Sofa Bed');
  }
}

class _RoomImagePlaceholder extends StatelessWidget {
  const _RoomImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandGreen, AppColors.primaryOrange],
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.bed_rounded,
            size: 44,
            color: AppColors.surfaceWhite,
          ),
        ),
      ),
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
