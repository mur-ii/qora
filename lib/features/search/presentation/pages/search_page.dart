import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/search_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SearchInjection.createBloc()..add(const SearchHotelsEvent()),
      child: const _SearchPageContent(),
    );
  }
}

class _SearchPageContent extends StatelessWidget {
  const _SearchPageContent();

  void _selectLocation(BuildContext context, String location) {
    context.pop(location);
  }

  List<_ProvinceItem> _buildProvinceItems(SearchLoaded state) {
    final countByCity = <String, int>{};
    final displayByCity = <String, String>{};
    final locationByCity = <String, String>{};

    for (final hotel in state.hotels) {
      final city = hotel.city.trim().isNotEmpty
          ? hotel.city.trim()
          : hotel.location.split(',').first.trim();
      final cityKey = city.toLowerCase();

      countByCity[cityKey] = (countByCity[cityKey] ?? 0) + 1;
      displayByCity.putIfAbsent(cityKey, () => city);
      locationByCity.putIfAbsent(cityKey, () => hotel.location);
    }

    // Jakarta must always be present in the province picker.
    countByCity.putIfAbsent('jakarta', () => 0);
    displayByCity.putIfAbsent('jakarta', () => 'Jakarta');
    locationByCity.putIfAbsent('jakarta', () => 'Jakarta, Indonesia');

    final provinces =
        countByCity.keys
            .map(
              (cityKey) => _ProvinceItem(
                city: displayByCity[cityKey] ?? cityKey,
                location:
                    locationByCity[cityKey] ??
                    '${displayByCity[cityKey]}, Indonesia',
                hotelCount: countByCity[cityKey] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) {
            final aIsJakarta = a.city.toLowerCase() == 'jakarta';
            final bIsJakarta = b.city.toLowerCase() == 'jakarta';

            if (aIsJakarta && !bIsJakarta) {
              return -1;
            }
            if (!aIsJakarta && bIsJakarta) {
              return 1;
            }

            return a.city.compareTo(b.city);
          });

    return provinces;
  }

  String _provinceKey(String city) {
    return city.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Pilih Provinsi',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface, AppColors.background],
          ),
        ),
        child: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            if (state is SearchLoading || state is SearchInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SearchError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 56,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gagal memuat provinsi',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is SearchEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      size: 56,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada provinsi tersedia',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is SearchLoaded) {
              final provinces = _buildProvinceItems(state);

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: provinces.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.surfaceWhite, AppColors.neutral50],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.explore_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destinasi Hotel Qora',
                                  style: AppTypography.titleSmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Pilih provinsi untuk melanjutkan pencarian',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final province = provinces[index - 1];
                  final isJakarta = province.city.toLowerCase() == 'jakarta';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      key: ValueKey<String>(
                        'province_${_provinceKey(province.city)}',
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isJakarta
                              ? AppColors.primaryContainer
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isJakarta
                              ? Icons.location_city
                              : Icons.place_outlined,
                          color: isJakarta
                              ? AppColors.primary
                              : AppColors.brandGreen,
                        ),
                      ),
                      title: Text(
                        province.city,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          province.hotelCount > 0
                              ? '${province.hotelCount} hotel tersedia'
                              : 'Akan segera tersedia',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      onTap: () => _selectLocation(context, province.location),
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ProvinceItem {
  const _ProvinceItem({
    required this.city,
    required this.location,
    required this.hotelCount,
  });

  final String city;
  final String location;
  final int hotelCount;
}
