import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/hotel_list_bloc.dart';
import '../bloc/hotel_list_event.dart';
import '../bloc/hotel_list_state.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HotelListBloc, HotelListState, String?>(
      selector: (state) => state is HotelListLoaded ? state.activeFilter : null,
      builder: (context, activeFilter) {
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FilterChip(
                label: 'Lowest Price',
                icon: Icons.attach_money,
                isActive: activeFilter == 'lowest_price',
                onTap: () {
                  context.read<HotelListBloc>().add(
                        const FilterHotelListEvent('lowest_price'),
                      );
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Highest Rating',
                icon: Icons.star,
                isActive: activeFilter == 'highest_rating',
                onTap: () {
                  context.read<HotelListBloc>().add(
                        const FilterHotelListEvent('highest_rating'),
                      );
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Popular',
                icon: Icons.trending_up,
                isActive: activeFilter == 'popular',
                onTap: () {
                  context.read<HotelListBloc>().add(
                        const FilterHotelListEvent('popular'),
                      );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? AppColors.textOnPrimary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.textOnPrimary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
