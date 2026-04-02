import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class BookingListPage extends StatelessWidget {
  const BookingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.surfaceWhite,
          title: Text(
            'Booking Saya',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: AppColors.surfaceWhite,
              child: TabBar(
                indicatorColor: AppColors.brandGreen,
                indicatorWeight: 3,
                labelColor: AppColors.brandGreen,
                unselectedLabelColor: AppColors.textTertiary,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Ongoing'),
                  Tab(text: 'History'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _BookingEmptyState(
              title: 'Belum ada booking berjalan',
              subtitle:
                  'Data booking yang sedang berlangsung akan tampil di sini.',
            ),
            _BookingEmptyState(
              title: 'Belum ada riwayat booking',
              subtitle: 'Data riwayat booking akan tampil di sini.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BookingEmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hotel_outlined, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
