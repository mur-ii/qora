import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotifications getNotifications;

  NotificationBloc({required this.getNotifications})
    : super(const NotificationState()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<MarkAllReadEvent>(_onMarkAllRead);
    on<MarkNotificationReadEvent>(_onMarkNotificationRead);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(status: NotificationStatus.loading, errorMessage: null));

    try {
      final items = await getNotifications();
      final sorted = List<NotificationEntity>.from(items)
        ..sort((a, b) => b.time.compareTo(a.time));
      emit(_buildStateWithSections(sorted));
    } catch (e) {
      emit(
        state.copyWith(
          status: NotificationStatus.failure,
          errorMessage: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }

  void _onMarkAllRead(
    MarkAllReadEvent event,
    Emitter<NotificationState> emit,
  ) {
    if (state.items.isEmpty) return;
    final updated = state.items
        .map((item) => item.isUnread ? item.copyWith(isUnread: false) : item)
        .toList(growable: false);
    emit(_buildStateWithSections(updated));
  }

  void _onMarkNotificationRead(
    MarkNotificationReadEvent event,
    Emitter<NotificationState> emit,
  ) {
    if (state.items.isEmpty) return;
    final updated = state.items
        .map(
          (item) => item.id == event.id
              ? item.copyWith(isUnread: false)
              : item,
        )
        .toList(growable: false);
    emit(_buildStateWithSections(updated));
  }

  NotificationState _buildStateWithSections(List<NotificationEntity> items) {
    final sections = _groupByDate(items);
    return NotificationState(
      status: NotificationStatus.success,
      items: items,
      sections: sections,
      errorMessage: null,
    );
  }

  List<NotificationSection> _groupByDate(List<NotificationEntity> items) {
    if (items.isEmpty) return const [];

    final now = DateTime.now();
    final sections = <NotificationSection>[];
    String? currentLabel;
    final bucket = <NotificationEntity>[];

    for (final item in items) {
      final label = _resolveDateLabel(now, item.time);
      if (currentLabel != label) {
        if (bucket.isNotEmpty && currentLabel != null) {
          sections.add(NotificationSection(label: currentLabel, items: List.of(bucket)));
          bucket.clear();
        }
        currentLabel = label;
      }
      bucket.add(item);
    }

    if (bucket.isNotEmpty && currentLabel != null) {
      sections.add(NotificationSection(label: currentLabel, items: List.of(bucket)));
    }

    return sections;
  }

  String _resolveDateLabel(DateTime now, DateTime time) {
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(time.year, time.month, time.day);
    final difference = today.difference(target).inDays;

    if (difference == 0) return 'Hari Ini';
    if (difference == 1) return 'Kemarin';
    if (difference <= 7) return 'Minggu Lalu';
    return '${target.day.toString().padLeft(2, '0')}/'
        '${target.month.toString().padLeft(2, '0')}/'
        '${target.year}';
  }
}
