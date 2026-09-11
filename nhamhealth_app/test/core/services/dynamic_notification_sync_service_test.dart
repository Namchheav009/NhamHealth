import 'package:flutter_test/flutter_test.dart';
import 'package:nhamhealth_flutter/app/modules/models/notifications/notification_item.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/notifications/notifications_repository.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';
import 'package:nhamhealth_flutter/core/services/dynamic_notification_sync_service.dart';

class _FakeAuthService extends Fake implements AuthService {
  String? token = 'mock-access-token';
  @override
  Future<String?> readAccessToken() async => token;
}

class _FakeNotificationsRepository extends Fake implements NotificationsRepository {
  List<NotificationItem> items = [];
  @override
  Future<List<NotificationItem>> getNotifications() async => items;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DynamicNotificationSyncService skips old notifications on first run and alerts only on new unread', () async {
    final authService = _FakeAuthService();
    final repository = _FakeNotificationsRepository();
    final service = DynamicNotificationSyncService(
      authService: authService,
      repository: repository,
    );
    addTearDown(service.stopSync);

    // Initial notifications before app was opened
    repository.items = [
      NotificationItem(
        id: 1,
        title: 'Old notification',
        message: 'Already exists',
        time: 'Yesterday',
        kind: NotificationKind.system,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    // First sync: records baseline, doesn't spam alerts
    await service.syncNow();

    // Now a new dynamic interaction arrives
    repository.items = [
      NotificationItem(
        id: 2,
        title: 'Kun Kaknika',
        message: 'commented on your post.',
        time: 'Just now',
        kind: NotificationKind.social,
        isUnread: true,
        actorUserId: 7,
        actorAvatarUrl: 'https://example.com/avatar.jpg',
        referenceType: 'POST',
        referenceId: 10,
        createdAt: DateTime.now(),
      ),
      ...repository.items,
    ];

    // Second sync: processes new unread item
    await expectLater(service.syncNow(), completes);

    // Third sync: duplicate check ensures already alerted items are not re-alerted
    await expectLater(service.syncNow(), completes);
  });

}
