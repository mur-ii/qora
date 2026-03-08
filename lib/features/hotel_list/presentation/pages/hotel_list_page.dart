import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/hotel_list_injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../bloc/hotel_list_bloc.dart';
import '../bloc/hotel_list_event.dart';
import '../bloc/hotel_list_state.dart';
import '../widgets/hotel_card.dart';

class HotelListPage extends StatefulWidget {
  final String? location;
  final String? checkIn;
  final String? checkOut;
  final String? rooms;
  final String? guests;
  final String? searchKey;

  const HotelListPage({
    super.key,
    this.location,
    this.checkIn,
    this.checkOut,
    this.rooms,
    this.guests,
    this.searchKey,
  });

  @override
  State<HotelListPage> createState() => _HotelListPageState();
}

class _HotelListPageState extends State<HotelListPage> {
  late final HotelListBloc _hotelListBloc;

  @override
  void initState() {
    super.initState();
    _hotelListBloc = HotelListInjection.createBloc()
      ..add(LoadHotelListEvent(location: widget.location));
  }

  @override
  void didUpdateWidget(covariant HotelListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasSearchChanged =
        oldWidget.location != widget.location ||
        oldWidget.checkIn != widget.checkIn ||
        oldWidget.checkOut != widget.checkOut ||
        oldWidget.rooms != widget.rooms ||
        oldWidget.guests != widget.guests ||
        oldWidget.searchKey != widget.searchKey;

    if (hasSearchChanged) {
      _hotelListBloc.add(const ResetHotelFiltersEvent());
      _hotelListBloc.add(LoadHotelListEvent(location: widget.location));
    }
  }

  @override
  void dispose() {
    _hotelListBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _hotelListBloc,
      child: _HotelListPageContent(
        location: widget.location,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        rooms: widget.rooms,
        guests: widget.guests,
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

  static final DateFormat _shortDateFormatter = DateFormat('dd MMM');

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
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          tooltip: 'Kembali',
          onPressed: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              router.pop();
            } else {
              router.go(AppRoutes.homePath);
            }
          },
        ),
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
                  return const _HotelListLoadingView();
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
                          'Tidak ada hotel ditemukan',
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
                  final hotels = state.hotels;
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: hotels.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final hotel = hotels[index];
                      return HotelCard(key: ValueKey(hotel.id), hotel: hotel);
                    },
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
    final hotelListBloc = context.read<HotelListBloc>();
    final currentState = hotelListBloc.state;
    final currentFilters = currentState is HotelListLoaded
        ? currentState.activeFilters
        : const HotelListFilters();

    String? selectedBudgetKey = currentFilters.budgetKey;
    final Set<String> selectedTypes = {...currentFilters.types};
    final Set<String> selectedAmenities = {...currentFilters.amenities};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceWhite,
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
                        setState(() {
                          selectedBudgetKey = null;
                          selectedTypes.clear();
                          selectedAmenities.clear();
                        });
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
                            _FilterChip(
                              label: '< Rp 200.000',
                              isSelected: selectedBudgetKey == 'lt_200k',
                              onSelected: (selected) {
                                setState(() {
                                  selectedBudgetKey = selected
                                      ? 'lt_200k'
                                      : null;
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'Rp 200.000 - Rp 500.000',
                              isSelected: selectedBudgetKey == '200_500k',
                              onSelected: (selected) {
                                setState(() {
                                  selectedBudgetKey = selected
                                      ? '200_500k'
                                      : null;
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'Rp 500.000 - Rp 1.000.000',
                              isSelected: selectedBudgetKey == '500_1000k',
                              onSelected: (selected) {
                                setState(() {
                                  selectedBudgetKey = selected
                                      ? '500_1000k'
                                      : null;
                                });
                              },
                            ),
                            _FilterChip(
                              label: '> Rp 1.000.000',
                              isSelected: selectedBudgetKey == 'gt_1000k',
                              onSelected: (selected) {
                                setState(() {
                                  selectedBudgetKey = selected
                                      ? 'gt_1000k'
                                      : null;
                                });
                              },
                            ),
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
                            _FilterChip(
                              label: 'Hotel',
                              isSelected: selectedTypes.contains('hotel'),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedTypes.add('hotel');
                                  } else {
                                    selectedTypes.remove('hotel');
                                  }
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'Apartemen',
                              isSelected: selectedTypes.contains('apartemen'),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedTypes.add('apartemen');
                                  } else {
                                    selectedTypes.remove('apartemen');
                                  }
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'Guest House',
                              isSelected: selectedTypes.contains('guest_house'),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedTypes.add('guest_house');
                                  } else {
                                    selectedTypes.remove('guest_house');
                                  }
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'Villa',
                              isSelected: selectedTypes.contains('villa'),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedTypes.add('villa');
                                  } else {
                                    selectedTypes.remove('villa');
                                  }
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'Resort',
                              isSelected: selectedTypes.contains('resort'),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedTypes.add('resort');
                                  } else {
                                    selectedTypes.remove('resort');
                                  }
                                });
                              },
                            ),
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
                            _FilterChip(
                              label: 'WiFi Gratis',
                              isSelected: selectedAmenities.contains('wifi'),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedAmenities.add('wifi');
                                  } else {
                                    selectedAmenities.remove('wifi');
                                  }
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'AC',
                              isSelected: selectedAmenities.contains(
                                'air conditioning',
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedAmenities.add('air conditioning');
                                  } else {
                                    selectedAmenities.remove(
                                      'air conditioning',
                                    );
                                  }
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'TV',
                              isSelected: selectedAmenities.contains('tv'),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedAmenities.add('tv');
                                  } else {
                                    selectedAmenities.remove('tv');
                                  }
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'Kamar Mandi Dalam',
                              isSelected: selectedAmenities.contains(
                                'bathroom',
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedAmenities.add('bathroom');
                                  } else {
                                    selectedAmenities.remove('bathroom');
                                  }
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'Breakfast',
                              isSelected: selectedAmenities.contains(
                                'restaurant',
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedAmenities.add('restaurant');
                                  } else {
                                    selectedAmenities.remove('restaurant');
                                  }
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'Kolam Renang',
                              isSelected: selectedAmenities.contains('pool'),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedAmenities.add('pool');
                                  } else {
                                    selectedAmenities.remove('pool');
                                  }
                                });
                              },
                            ),
                            _FilterChip(
                              label: 'Parkir',
                              isSelected: selectedAmenities.contains('parking'),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedAmenities.add('parking');
                                  } else {
                                    selectedAmenities.remove('parking');
                                  }
                                });
                              },
                            ),
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
                      final filters = HotelListFilters(
                        budgetKey: selectedBudgetKey,
                        types: selectedTypes,
                        amenities: selectedAmenities,
                      );

                      if (filters.isEmpty) {
                        hotelListBloc.add(const ResetHotelFiltersEvent());
                      } else {
                        hotelListBloc.add(ApplyHotelFiltersEvent(filters));
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surfaceWhite,
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
      return '${_shortDateFormatter.format(checkInDate)} - ${_shortDateFormatter.format(checkOutDate)}';
    } catch (e) {
      return '';
    }
  }

  void _showSortOptions(BuildContext context) {
    final hotelListBloc = context.read<HotelListBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
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
                hotelListBloc.add(const FilterHotelListEvent('lowest_price'));
                Navigator.pop(context);
              },
            ),
            _SortOption(
              title: 'Harga: Tinggi ke Rendah',
              icon: Icons.arrow_downward,
              onTap: () {
                hotelListBloc.add(const FilterHotelListEvent('highest_price'));
                Navigator.pop(context);
              },
            ),
            _SortOption(
              title: 'Rating: Tinggi ke Rendah',
              icon: Icons.star,
              onTap: () {
                hotelListBloc.add(const FilterHotelListEvent('highest_rating'));
                Navigator.pop(context);
              },
            ),
            _SortOption(
              title: 'Populer',
              icon: Icons.trending_up,
              onTap: () {
                hotelListBloc.add(const FilterHotelListEvent('popular'));
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
          border: Border.all(color: AppColors.border),
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
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
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

class _HotelListLoadingView extends StatelessWidget {
  const _HotelListLoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LinearProgressIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          minHeight: 2,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: 6,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => const _HotelCardSkeleton(),
          ),
        ),
      ],
    );
  }
}

class _HotelCardSkeleton extends StatelessWidget {
  const _HotelCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonBar(width: double.infinity, height: 16),
                  const SizedBox(height: 10),
                  _SkeletonBar(width: 140, height: 12),
                  const SizedBox(height: 8),
                  _SkeletonBar(width: 180, height: 12),
                  const Spacer(),
                  Row(
                    children: const [
                      _SkeletonBar(width: 72, height: 20),
                      SizedBox(width: 8),
                      _SkeletonBar(width: 88, height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
