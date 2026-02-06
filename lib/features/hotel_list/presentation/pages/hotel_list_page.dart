import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../data/datasources/hotel_list_remote_datasource.dart';
import '../../data/repositories/hotel_list_repository_impl.dart';
import '../../domain/usecases/get_hotel_list.dart';
import '../bloc/hotel_list_bloc.dart';
import '../bloc/hotel_list_event.dart';
import '../bloc/hotel_list_state.dart';
import '../widgets/hotel_card.dart';

class HotelListPage extends StatelessWidget {
  final String? location;
  final String? checkIn;
  final String? checkOut;
  final String? rooms;
  final String? guests;

  const HotelListPage({
    super.key,
    this.location,
    this.checkIn,
    this.checkOut,
    this.rooms,
    this.guests,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final dataSource = HotelListRemoteDataSourceImpl();
        final repository = HotelListRepositoryImpl(dataSource);
        final useCase = GetHotelList(repository);
        return HotelListBloc(getHotelList: useCase)
          ..add(LoadHotelListEvent(location: location));
      },
      child: _HotelListPageContent(
        location: location,
        checkIn: checkIn,
        checkOut: checkOut,
        rooms: rooms,
        guests: guests,
      ),
    );
  }
}

class _HotelListPageContent extends StatelessWidget {
  final String? location;
  final String? checkIn;
  final String? checkOut;
  final String? rooms;
  final String? guests;

  const _HotelListPageContent({
    this.location,
    this.checkIn,
    this.checkOut,
    this.rooms,
    this.guests,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${location ?? 'Hotel'} · ${_formatDateRangeShort()}',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter buttons row
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _FilterButton(
                    icon: Icons.sort,
                    label: 'Sortir',
                    onTap: () => _showSortOptions(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterButton(
                    icon: Icons.tune,
                    label: 'Filter',
                    onTap: () => _showFilterOptions(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterButton(
                    icon: Icons.map_outlined,
                    label: 'Peta',
                    onTap: () {
                      // TODO: Implement map view
                      AppToast.showInfo(context, 'Peta akan segera hadir');
                    },
                  ),
                ),
              ],
            ),
          ),
          // Accommodation count
          BlocBuilder<HotelListBloc, HotelListState>(
            buildWhen: (previous, current) =>
                previous.runtimeType != current.runtimeType ||
                (current is HotelListLoaded &&
                    previous is HotelListLoaded &&
                    current.hotels.length != previous.hotels.length),
            builder: (context, state) {
              if (state is HotelListLoaded) {
                return Container(
                  width: double.infinity,
                  color: AppColors.surface,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    '${state.hotels.length} akomodasi',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: BlocBuilder<HotelListBloc, HotelListState>(
              buildWhen: (previous, current) {
                // Only rebuild when state type changes or hotel list changes
                if (previous.runtimeType != current.runtimeType) return true;
                if (current is HotelListLoaded && previous is HotelListLoaded) {
                  return current.hotels != previous.hotels;
                }
                return false;
              },
              builder: (context, state) {
                if (state is HotelListLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (state is HotelListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Gagal memuat hotel',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<HotelListBloc>().add(
                              LoadHotelListEvent(location: location),
                            );
                          },
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is HotelListEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hotel_outlined,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hotel tidak ditemukan',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba sesuaikan pencarian atau filter Anda',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is HotelListLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<HotelListBloc>().add(
                        LoadHotelListEvent(location: location),
                      );
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: state.hotels.length,
                      // Optimize scrolling with fixed item extent
                      physics: const AlwaysScrollableScrollPhysics(),
                      cacheExtent: 500, // Preload items for smooth scrolling
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final hotel = state.hotels[index];
                        return HotelCard(key: ValueKey(hotel.id), hotel: hotel);
                      },
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Reset filters
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Budget Filter
                        Text(
                          'Budget',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FilterChip(label: '< Rp 200.000'),
                            _FilterChip(label: 'Rp 200.000 - Rp 500.000'),
                            _FilterChip(label: 'Rp 500.000 - Rp 1.000.000'),
                            _FilterChip(label: '> Rp 1.000.000'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Accommodation Type Filter
                        Text(
                          'Tipe Akomodasi',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FilterChip(label: 'Hotel'),
                            _FilterChip(label: 'Apartemen'),
                            _FilterChip(label: 'Guest House'),
                            _FilterChip(label: 'Villa'),
                            _FilterChip(label: 'Resort'),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Room Facilities Filter
                        Text(
                          'Fasilitas Kamar',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _FilterChip(label: 'WiFi Gratis'),
                            _FilterChip(label: 'AC'),
                            _FilterChip(label: 'TV'),
                            _FilterChip(label: 'Kamar Mandi Dalam'),
                            _FilterChip(label: 'Breakfast'),
                            _FilterChip(label: 'Kolam Renang'),
                            _FilterChip(label: 'Parkir'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Apply filters
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Terapkan Filter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDateRangeShort() {
    if (checkIn == null || checkOut == null) return '';

    try {
      final checkInDate = DateTime.parse(checkIn!);
      final checkOutDate = DateTime.parse(checkOut!);
      final formatter = DateFormat('dd MMM');
      return '${formatter.format(checkInDate)} - ${formatter.format(checkOutDate)}';
    } catch (e) {
      return '';
    }
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Urutkan Berdasarkan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _SortOption(
              title: 'Harga: Rendah ke Tinggi',
              icon: Icons.arrow_upward,
              onTap: () {
                context.read<HotelListBloc>().add(
                  const FilterHotelListEvent('lowest_price'),
                );
                Navigator.pop(context);
              },
            ),
            _SortOption(
              title: 'Harga: Tinggi ke Rendah',
              icon: Icons.arrow_downward,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _SortOption(
              title: 'Rating: Tinggi ke Rendah',
              icon: Icons.star,
              onTap: () {
                context.read<HotelListBloc>().add(
                  const FilterHotelListEvent('highest_rating'),
                );
                Navigator.pop(context);
              },
            ),
            _SortOption(
              title: 'Populer',
              icon: Icons.trending_up,
              onTap: () {
                context.read<HotelListBloc>().add(
                  const FilterHotelListEvent('popular'),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Filter Button Widget
class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Filter Chip Widget
class _FilterChip extends StatefulWidget {
  final String label;

  const _FilterChip({required this.label});

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(widget.label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          isSelected = selected;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey[300]!,
      ),
    );
  }
}

// Sort Option Widget
class _SortOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _SortOption({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
