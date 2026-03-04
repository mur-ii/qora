import '../../features/notifications/data/datasources/notification_local_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/usecases/get_notifications.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';

class NotificationInjection {
  static NotificationBloc createBloc() {
    final dataSource = NotificationLocalDataSource();
    final repository = NotificationRepositoryImpl(localDataSource: dataSource);
    final useCase = GetNotifications(repository);
    return NotificationBloc(getNotifications: useCase);
  }
}
