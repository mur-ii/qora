import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/notification_injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/notification_entity.dart';
import '../bloc/notification_bloc.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          NotificationInjection.createBloc()
            ..add(const LoadNotificationsEvent()),
      child: const _NotificationPageContent(),
    );
  }
}

class _NotificationPageContent extends StatelessWidget {
  const _NotificationPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surfaceWhite,
        title: Text(
          'Notifikasi',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            buildWhen: (previous, current) =>
                previous.hasUnread != current.hasUnread,
            builder: (context, state) {
              return TextButton(
                onPressed: state.hasUnread
                    ? () => context.read<NotificationBloc>().add(
                        const MarkAllReadEvent(),
                      )
                    : null,
                child: Text(
                  'Tandai Semua',
                  style: AppTypography.labelMedium.copyWith(
                    color: state.hasUnread
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.status == NotificationStatus.loading) {
            return const SizedBox.shrink();
          }

          if (state.status == NotificationStatus.failure) {
            return Center(
              child: Text(
                state.errorMessage ?? 'Gagal memuat notifikasi',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          if (state.sections.isEmpty) {
            return Center(
              child: Text(
                'Belum ada notifikasi',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          final items = _buildSectionedItems(state.sections);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          );
        },
      ),
    );
  }

  List<Widget> _buildSectionedItems(List<NotificationSection> sections) {
    final widgets = <Widget>[];
    for (final section in sections) {
      widgets.add(_buildDateHeader(section.label));
      for (final item in section.items) {
        widgets.add(_NotificationItem(item: item));
      }
    }
    return widgets;
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
}

class _NotificationItem extends StatelessWidget {
  final NotificationEntity item;

  const _NotificationItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: item.isUnread
            ? AppColors.primary.withValues(alpha: 0.05)
            : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isUnread
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (item.isUnread) {
            context.read<NotificationBloc>().add(
              MarkNotificationReadEvent(item.id),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(item.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (item.isUnread)
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
                      item.message,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(item.time),
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

  Widget _buildNotificationIcon(NotificationType type) {
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
        color: backgroundColor.withValues(alpha: 0.1),
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
