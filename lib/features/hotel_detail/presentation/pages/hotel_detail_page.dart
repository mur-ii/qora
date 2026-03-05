import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/hotel_detail_injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_bloc.dart';
import '../../../voice_assistant/presentation/bloc/voice_assistant_state.dart';
import '../bloc/hotel_detail_bloc.dart';
import '../bloc/hotel_detail_event.dart';
import '../bloc/hotel_detail_state.dart';
import '../widgets/facilities_section.dart';
import '../widgets/reviews_section.dart';
import '../widgets/room_types_section.dart';

class HotelDetailPage extends StatefulWidget {
  final String hotelId;

  const HotelDetailPage({super.key, required this.hotelId});

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  String? _selectedRoomId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HotelDetailInjection.createBloc()
            ..add(LoadHotelDetailEvent(widget.hotelId)),
      child: BlocListener<VoiceAssistantBloc, VoiceAssistantState>(
        listenWhen: (previous, current) =>
            previous.agentState != current.agentState ||
            previous.status != current.status,
        listener: (context, voiceState) {
          if (!voiceState.isActive) {
            return;
          }

          final hotelState = context.read<HotelDetailBloc>().state;
          if (hotelState is! HotelDetailLoaded) return;

          final appState = voiceState.agentState.appState;
          final targetHotelId = appState['hotel_id']?.toString();
          if (targetHotelId != null && targetHotelId != widget.hotelId) {
            return;
          }

          String? targetRoomId = appState['room_id']?.toString();
          if (targetRoomId == null) {
            final roomType = appState['room_type']?.toString();
            if (roomType != null && roomType.isNotEmpty) {
              final matchedRoom = hotelState.hotel.roomTypes.firstWhere(
                (room) =>
                    room.name.toLowerCase().contains(roomType.toLowerCase()),
                orElse: () => hotelState.hotel.roomTypes.first,
              );
              targetRoomId = matchedRoom.id;
            }
          }

          if (targetRoomId != null && targetRoomId != _selectedRoomId) {
            setState(() {
              _selectedRoomId = targetRoomId;
            });
          }
        },
        child: _HotelDetailPageContent(
          selectedRoomId: _selectedRoomId,
          onRoomSelected: (roomId) {
            setState(() {
              _selectedRoomId = roomId;
            });
          },
        ),
      ),
    );
  }
}

class _HotelDetailPageContent extends StatelessWidget {
  final String? selectedRoomId;
  final Function(String) onRoomSelected;

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  const _HotelDetailPageContent({
    required this.selectedRoomId,
    required this.onRoomSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<HotelDetailBloc, HotelDetailState>(
        builder: (context, state) {
          if (state is HotelDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is HotelDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat detail hotel',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }

          if (state is HotelDetailLoaded) {
            final hotel = state.hotel;

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hotel Name and Rating
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    hotel.name,
                                    style: AppTypography.headlineSmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(
                                      hotel.starRating,
                                      (index) => const Icon(
                                        Icons.star,
                                        size: 18,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hotel.rating.toStringAsFixed(1),
                                    style: AppTypography.labelMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hotel.address,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${hotel.reviewCount} ulasan',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Description
                        Text(
                          'Tentang',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hotel.description,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Facilities
                        FacilitiesSection(facilities: hotel.facilities),
                        const SizedBox(height: 24),

                        // Room Types
                        RoomTypesSection(
                          roomTypes: hotel.roomTypes,
                          selectedRoomId: selectedRoomId,
                          onRoomSelected: onRoomSelected,
                        ),
                        const SizedBox(height: 24),

                        // Policies
                        Text(
                          'Kebijakan',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PolicyItem(
                          icon: Icons.login,
                          label: 'Check-in',
                          value: hotel.policies.checkIn,
                        ),
                        _PolicyItem(
                          icon: Icons.logout,
                          label: 'Check-out',
                          value: hotel.policies.checkOut,
                        ),
                        _PolicyItem(
                          icon: Icons.pets,
                          label: 'Hewan Peliharaan',
                          value: hotel.policies.pets
                              ? 'Diizinkan'
                              : 'Tidak diizinkan',
                        ),
                        _PolicyItem(
                          icon: Icons.smoking_rooms,
                          label: 'Merokok',
                          value: hotel.policies.smoking
                              ? 'Diizinkan'
                              : 'Tidak diizinkan',
                        ),
                        const SizedBox(height: 24),

                        // Reviews
                        ReviewsSection(reviews: hotel.reviews),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
      bottomNavigationBar: BlocBuilder<HotelDetailBloc, HotelDetailState>(
        buildWhen: (previous, current) =>
            previous.runtimeType != current.runtimeType,
        builder: (context, state) {
          if (state is HotelDetailLoaded) {
            double displayPrice = state.hotel.pricePerNight;
            String priceLabel = 'Mulai dari';
            int maxGuests = 2;

            if (selectedRoomId != null) {
              try {
                final selectedRoom = state.hotel.roomTypes.firstWhere(
                  (room) => room.id == selectedRoomId,
                );
                displayPrice = selectedRoom.pricePerNight;
                priceLabel = 'Kamar terpilih';
                maxGuests = selectedRoom.maxGuests;
              } catch (e) {
                displayPrice = state.hotel.pricePerNight;
                priceLabel = 'Mulai dari';
              }
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            priceLabel,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            _currencyFormatter.format(displayPrice),
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.w600,
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selectedRoomId == null
                            ? null
                            : () {
                                final now = DateTime.now();
                                final checkIn = DateTime(
                                  now.year,
                                  now.month,
                                  now.day + 1,
                                );
                                final checkOut = DateTime(
                                  now.year,
                                  now.month,
                                  now.day + 2,
                                );

                                context.push(
                                  Uri(
                                    path: AppRoutes.bookingSummaryPath,
                                    queryParameters: {
                                      'hotelId': state.hotel.id,
                                      'roomId': selectedRoomId!,
                                      'checkIn': checkIn.toIso8601String(),
                                      'checkOut': checkOut.toIso8601String(),
                                      'guests': maxGuests.toString(),
                                      'rooms': '1',
                                    },
                                  ).toString(),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: Text(
                          selectedRoomId == null
                              ? 'Pilih Kamar'
                              : 'Pesan Sekarang',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PolicyItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
