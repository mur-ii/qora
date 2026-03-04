import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_local_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource localDataSource;

  NotificationRepositoryImpl({required this.localDataSource});

  @override
  Future<List<NotificationEntity>> getNotifications() {
    return localDataSource.fetchNotifications();
  }
}
