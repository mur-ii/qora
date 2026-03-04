import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository repository;

  GetNotifications(this.repository);

  Future<List<NotificationEntity>> call() {
    return repository.getNotifications();
  }
}
