import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/hotel_detail_entity.dart';

class RoomTypesSection extends StatefulWidget {
  final List<RoomTypeEntity> roomTypes;
  final Function(String roomId) onRoomSelected;
  final Function(RoomTypeEntity room) onBookNow;
  final String? selectedRoomId;

  const RoomTypesSection({
    super.key,
    required this.roomTypes,
    required this.onRoomSelected,
    required this.onBookNow,
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

  String? _expandedRoomId;

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
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.roomTypes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final room = widget.roomTypes[index];
            final isSelected = widget.selectedRoomId == room.id;
            final isExpanded = _expandedRoomId == room.id;

            return _RoomCard(
              room: room,
              isSelected: isSelected,
              isExpanded: isExpanded,
              onTapCard: () {
                setState(() {
                  _expandedRoomId = isExpanded ? null : room.id;
                });
              },
              onSelect: () => widget.onRoomSelected(room.id),
              onBookNow: () => widget.onBookNow(room),
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
  final bool isExpanded;
  final VoidCallback onTapCard;
  final VoidCallback onSelect;
  final VoidCallback onBookNow;
  final String priceText;

  const _RoomCard({
    required this.room,
    required this.isSelected,
    required this.isExpanded,
    required this.onTapCard,
    required this.onSelect,
    required this.onBookNow,
    required this.priceText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCard,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isExpanded
                ? AppColors.brandGreen
                : AppColors.border,
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.deepBlack.withValues(
                alpha: isExpanded ? 0.06 : 0.03,
              ),
              blurRadius: isExpanded ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bed_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${room.maxGuests} tamu - ${room.size} m2',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        priceText,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
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
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _RoomInfoChip(
                            icon: Icons.bed_outlined,
                            label: _translateBedType(room.bedType),
                          ),
                          ...room.amenities
                              .take(3)
                              .map(
                                (amenity) => _RoomInfoChip(
                                  icon: Icons.check_circle_outline,
                                  label: _translateAmenity(amenity),
                                ),
                              ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            height: 38,
                            child: OutlinedButton(
                              onPressed: onSelect,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.brandGreen
                                      : AppColors.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  isSelected ? 'Dipilih' : 'Select Room',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected
                                        ? AppColors.brandGreen
                                        : AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 38,
                                child: ElevatedButton(
                                  onPressed: onBookNow,
                                  style: ElevatedButton.styleFrom(
                                    elevation: 0,
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.surfaceWhite,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Pesan Sekarang',
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          ),
        ),
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

class _RoomInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RoomInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
