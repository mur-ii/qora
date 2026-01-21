import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Notifikasi',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Mark all as read
            },
            child: Text(
              'Tandai Semua',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildDateHeader('Hari Ini'),
          _buildNotificationItem(
            context: context,
            type: NotificationType.booking,
            title: 'Booking Berhasil!',
            message:
                'Reservasi Anda di Grand Luxury Hotel telah dikonfirmasi untuk tanggal 22-25 Januari 2026.',
            time: DateTime.now().subtract(const Duration(hours: 2)),
            isUnread: true,
          ),
          _buildNotificationItem(
            context: context,
            type: NotificationType.promo,
            title: 'Promo Spesial Weekend! 🎉',
            message:
                'Dapatkan diskon hingga 50% untuk booking hotel di akhir pekan. Buruan pesan sekarang!',
            time: DateTime.now().subtract(const Duration(hours: 5)),
            isUnread: true,
          ),
          _buildDateHeader('Kemarin'),
          _buildNotificationItem(
            context: context,
            type: NotificationType.payment,
            title: 'Pembayaran Berhasil',
            message:
                'Pembayaran sebesar Rp 2.500.000 untuk Sunset Beach Resort telah diterima.',
            time: DateTime.now().subtract(const Duration(days: 1, hours: 10)),
            isUnread: false,
          ),
          _buildNotificationItem(
            context: context,
            type: NotificationType.reminder,
            title: 'Pengingat Check-in',
            message:
                'Jangan lupa! Check-in Anda di Mountain View Lodge besok pukul 14:00.',
            time: DateTime.now().subtract(const Duration(days: 1, hours: 14)),
            isUnread: false,
          ),
          _buildDateHeader('Minggu Lalu'),
          _buildNotificationItem(
            context: context,
            type: NotificationType.review,
            title: 'Bagikan Pengalaman Anda',
            message:
                'Terima kasih telah menginap di Royal Palace Hotel. Berikan review Anda!',
            time: DateTime.now().subtract(const Duration(days: 5)),
            isUnread: false,
          ),
          _buildNotificationItem(
            context: context,
            type: NotificationType.promo,
            title: 'Cashback 100rb',
            message:
                'Dapatkan cashback Rp 100.000 untuk transaksi minimal Rp 500.000. Berlaku hingga akhir bulan!',
            time: DateTime.now().subtract(const Duration(days: 6)),
            isUnread: false,
          ),
          _buildNotificationItem(
            context: context,
            type: NotificationType.booking,
            title: 'Konfirmasi Pembatalan',
            message:
                'Pembatalan booking Anda di Beachfront Paradise telah diproses. Dana akan dikembalikan dalam 3-5 hari kerja.',
            time: DateTime.now().subtract(const Duration(days: 7)),
            isUnread: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        date,
        style: AppTypography.labelLarge.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required BuildContext context,
    required NotificationType type,
    required String title,
    required String message,
    required DateTime time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isUnread ? AppColors.primary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Handle notification tap
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(type, isUnread),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(time),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type, bool isUnread) {
    IconData icon;
    Color backgroundColor;

    switch (type) {
      case NotificationType.booking:
        icon = Icons.calendar_today;
        backgroundColor = AppColors.success;
        break;
      case NotificationType.payment:
        icon = Icons.payment;
        backgroundColor = AppColors.secondary;
        break;
      case NotificationType.promo:
        icon = Icons.local_offer;
        backgroundColor = AppColors.accent;
        break;
      case NotificationType.reminder:
        icon = Icons.notifications_active;
        backgroundColor = AppColors.warning;
        break;
      case NotificationType.review:
        icon = Icons.rate_review;
        backgroundColor = AppColors.info;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: backgroundColor, size: 24),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(time);
    }
  }
}

enum NotificationType { booking, payment, promo, reminder, review }
