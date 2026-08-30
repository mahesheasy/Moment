import 'package:moment/core/result/result.dart';
import 'package:moment/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationsRepository {
  Stream<List<AppNotification>> watchNotifications();

  Future<Result<void>> markRead(String id);

  Future<Result<void>> markAllRead();

  Future<Result<void>> dismiss(String id);
}
