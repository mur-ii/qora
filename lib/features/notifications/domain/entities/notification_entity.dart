import 'package:equatable/equatable.dart';

enum NotificationType { booking, payment, promo, reminder, review }

class NotificationEntity extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime time;
  final bool isUnread;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.time,
    required this.isUnread,
  });

  NotificationEntity copyWith({
    bool? isUnread,
  }) {
    return NotificationEntity(
      id: id,
      type: type,
      title: title,
      message: message,
      time: time,
      isUnread: isUnread ?? this.isUnread,
    );
  }

  @override
  List<Object?> get props => [id, type, title, message, time, isUnread];
}
