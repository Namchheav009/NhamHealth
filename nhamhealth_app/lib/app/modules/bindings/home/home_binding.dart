import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../controllers/home/home_controller.dart';
import '../../providers/home/home_provider.dart';
import '../../repositories/home/home_repository.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(authService: Get.find<AuthService>()),
        fenix: true,
      );
    }
    Get.lazyPut<HomeProvider>(
      () => HomeProvider(
        profileRepository: Get.find<ProfileRepository>(),
        authService: Get.find<AuthService>(),
      ),
    );

    Get.lazyPut<HomeRepository>(
      () => HomeRepository(
        provider: Get.find<HomeProvider>(),
      ),
    );

    Get.lazyPut<HomeController>(
      () => HomeController(
        repository: Get.find<HomeRepository>(),
        realtimeEvents: PushNotificationService.instance?.events,
      ),
    );
  }
}
