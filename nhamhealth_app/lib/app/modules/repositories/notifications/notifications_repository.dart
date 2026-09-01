import '../../models/notifications/notification_item.dart';
import '../../providers/notifications/notifications_provider.dart';

class NotificationsRepository {
  const NotificationsRepository({required this.provider});
  final NotificationsProvider provider;
  Future<List<NotificationItem>> getNotifications() =>
      provider.getNotifications();
  Future<void> markRead(int id) => provider.markRead(id);
}
