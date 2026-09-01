import 'package:get/get.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../controllers/community/community_controller.dart';
import '../../providers/notifications/notifications_provider.dart';
import '../../repositories/community/community_repository.dart';
import '../../repositories/notifications/notifications_repository.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CommunityRepository>(
      () => CommunityRepository(authService: Get.find()),
    );
    if (!Get.isRegistered<NotificationsProvider>()) {
      Get.lazyPut(
        () => NotificationsProvider(authService: Get.find<AuthService>()),
      );
    }
    if (!Get.isRegistered<NotificationsRepository>()) {
      Get.lazyPut(
        () => NotificationsRepository(
          provider: Get.find<NotificationsProvider>(),
        ),
      );
    }
    Get.lazyPut<CommunityController>(
      () => CommunityController(
        repository: Get.find<CommunityRepository>(),
        notificationsRepository: Get.find<NotificationsRepository>(),
        realtimeEvents: PushNotificationService.instance?.events,
      ),
    );
  }
}
