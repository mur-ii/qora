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
import '../../domain/entities/hotel_detail_entity.dart';
import '../bloc/hotel_detail_bloc.dart';
import '../bloc/hotel_detail_event.dart';
import '../bloc/hotel_detail_state.dart';
import '../widgets/facilities_section.dart';
import '../widgets/hotel_description_section.dart';
import '../widgets/hotel_header.dart';
import '../widgets/hotel_info_section.dart';
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

  void _handleBackNavigation(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.hotelListPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<HotelDetailBloc, HotelDetailState>(
        builder: (context, state) {
          if (state is HotelDetailLoading) {
            return const _HotelDetailLoadingView();
          }

          if (state is HotelDetailError) {
            return _HotelDetailErrorView(
              message: state.message,
              onBackPressed: () => _handleBackNavigation(context),
            );
          }

          if (state is HotelDetailLoaded) {
            final hotel = state.hotel;

            return CustomScrollView(
              slivers: [
                // Header gambar hotel dengan overlay nama dan bintang.
                SliverToBoxAdapter(
                  child: HotelHeader(
                    hotelName: hotel.name,
                    starRating: hotel.starRating,
                    onBackPressed: () => _handleBackNavigation(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HotelInfoSection(
                          hotelName: hotel.name,
                          address: hotel.address,
                          rating: hotel.rating,
                          reviewCount: hotel.reviewCount,
                          formattedPrice: _currencyFormatter.format(
                            hotel.pricePerNight,
                          ),
                        ),
                        const SizedBox(height: 24),

                        FacilitiesSection(facilities: hotel.facilities),
                        const SizedBox(height: 24),
                        HotelDescriptionSection(description: hotel.description),
                        const SizedBox(height: 24),

                        RoomTypesSection(
                          roomTypes: hotel.roomTypes,
                          selectedRoomId: selectedRoomId,
                          onRoomSelected: onRoomSelected,
                          onBookNow: (room) {
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
                                  'roomId': room.id,
                                  'checkIn': checkIn.toIso8601String(),
                                  'checkOut': checkOut.toIso8601String(),
                                  'guests': room.maxGuests.toString(),
                                  'rooms': '1',
                                },
                              ).toString(),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        _HotelPolicySection(policies: hotel.policies),
                        const SizedBox(height: 24),
                        ReviewsSection(reviews: hotel.reviews),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _HotelDetailLoadingView extends StatelessWidget {
  const _HotelDetailLoadingView();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _HotelDetailErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onBackPressed;

  const _HotelDetailErrorView({
    required this.message,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat detail hotel',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onBackPressed,
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotelPolicySection extends StatelessWidget {
  final PolicyEntity policies;

  const _HotelPolicySection({required this.policies});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kebijakan Hotel',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _PolicyItem(
            icon: Icons.login,
            label: 'Waktu check-in',
            value: policies.checkIn,
          ),
          _PolicyItem(
            icon: Icons.logout,
            label: 'Waktu check-out',
            value: policies.checkOut,
          ),
          _PolicyItem(
            icon: Icons.pets,
            label: 'Hewan Peliharaan',
            value: policies.pets ? 'Diizinkan' : 'Tidak diizinkan',
          ),
          _PolicyItem(
            icon: Icons.smoking_rooms,
            label: 'Merokok',
            value: policies.smoking ? 'Diizinkan' : 'Tidak diizinkan',
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
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
