import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/datasources/booking_local_datasource.dart';
import '../../data/models/booking_record.dart';
import '../../data/repositories/booking_local_repository_impl.dart';
import '../bloc/booking_history_bloc.dart';
import '../bloc/booking_history_event.dart';
import '../bloc/booking_history_state.dart';

class BookingListPage extends StatelessWidget {
  const BookingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final box = Hive.box<BookingRecord>('booking_box');
        final dataSource = BookingLocalDataSource(box: box);
        final repository = BookingLocalRepositoryImpl(
          localDataSource: dataSource,
        );
        return BookingHistoryBloc(repository: repository)
          ..add(const LoadBookingHistory());
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
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
                color: Colors.white,
                child: TabBar(
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
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
            children: [OngoingBookingsTab(), HistoryBookingsTab()],
          ),
        ),
      ),
    );
  }
}

// ==================== ONGOING BOOKINGS TAB ====================
class OngoingBookingsTab extends StatelessWidget {
  const OngoingBookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingHistoryBloc, BookingHistoryState>(
      builder: (context, state) {
        if (state is BookingHistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BookingHistoryLoaded) {
          if (state.ongoing.isEmpty) {
            return const _BookingEmptyState(
              title: 'No ongoing bookings',
              subtitle: 'Your upcoming stays will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.ongoing.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final record = state.ongoing[index];
              return _BookingCard(record: record, isHistory: false);
            },
          );
        }

        if (state is BookingHistoryError) {
          return const _BookingEmptyState(
            title: 'Unable to load bookings',
            subtitle: 'Please try again later.',
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

// ==================== HISTORY BOOKINGS TAB ====================
class HistoryBookingsTab extends StatelessWidget {
  const HistoryBookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingHistoryBloc, BookingHistoryState>(
      builder: (context, state) {
        if (state is BookingHistoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is BookingHistoryLoaded) {
          if (state.history.isEmpty) {
            return const _BookingEmptyState(
              title: 'No booking history',
              subtitle: 'Completed stays will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final record = state.history[index];
              return _BookingCard(record: record, isHistory: true);
            },
          );
        }

        if (state is BookingHistoryError) {
          return const _BookingEmptyState(
            title: 'Unable to load bookings',
            subtitle: 'Please try again later.',
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingRecord record;
  final bool isHistory;

  const _BookingCard({required this.record, required this.isHistory});

  Color _statusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return AppColors.secondary;
      case 'Ongoing':
        return AppColors.primary;
      case 'Completed':
        return AppColors.success;
      case 'Cancelled':
        return AppColors.textTertiary;
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel() {
    final status = record.bookingStatus.toLowerCase();
    if (status.contains('cancel')) return 'Cancelled';

    final now = DateTime.now();
    if (now.isBefore(record.checkIn)) return 'Upcoming';
    if (now.isAfter(record.checkOut)) return 'Completed';
    return 'Ongoing';
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel();
    final statusColor = _statusColor(status);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  height: 140,
                  width: double.infinity,
                  color: AppColors.neutral.withOpacity(0.1),
                  child: record.imageUrl.isNotEmpty
                      ? Image.network(
                          record.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.hotel,
                              size: 48,
                              color: AppColors.textTertiary,
                            );
                          },
                        )
                      : const Icon(
                          Icons.hotel,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.hotelName,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      record.location,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-in',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(record.checkIn),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppColors.textTertiary.withOpacity(0.2),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-out',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(record.checkOut),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      record.roomName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (isHistory && status == 'Completed')
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Book Again',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
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
