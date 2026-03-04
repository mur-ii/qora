part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationEvent {
  const LoadNotificationsEvent();
}

class MarkAllReadEvent extends NotificationEvent {
  const MarkAllReadEvent();
}

class MarkNotificationReadEvent extends NotificationEvent {
  final String id;

  const MarkNotificationReadEvent(this.id);

  @override
  List<Object?> get props => [id];
}
