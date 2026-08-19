import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../controllers/notifications_controller.dart';
import '../providers/notifications_provider.dart';
import '../repositories/notifications_repository.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NotificationsProvider(authService: Get.find<AuthService>()));
    Get.lazyPut(() => NotificationsRepository(provider: Get.find<NotificationsProvider>()));
    Get.lazyPut(() => NotificationsController(repository: Get.find<NotificationsRepository>()));
  }
}
