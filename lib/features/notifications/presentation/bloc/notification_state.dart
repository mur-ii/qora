part of 'notification_bloc.dart';

enum NotificationStatus { initial, loading, success, failure }

class NotificationSection extends Equatable {
  final String label;
  final List<NotificationEntity> items;

  const NotificationSection({required this.label, required this.items});

  @override
  List<Object?> get props => [label, items];
}

class NotificationState extends Equatable {
  final NotificationStatus status;
  final List<NotificationEntity> items;
  final List<NotificationSection> sections;
  final String? errorMessage;

  const NotificationState({
    this.status = NotificationStatus.initial,
    this.items = const [],
    this.sections = const [],
    this.errorMessage,
  });

  bool get hasUnread => items.any((item) => item.isUnread);

  NotificationState copyWith({
    NotificationStatus? status,
    List<NotificationEntity>? items,
    List<NotificationSection>? sections,
    String? errorMessage,
  }) {
    return NotificationState(
      status: status ?? this.status,
      items: items ?? this.items,
      sections: sections ?? this.sections,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, items, sections, errorMessage];
}
