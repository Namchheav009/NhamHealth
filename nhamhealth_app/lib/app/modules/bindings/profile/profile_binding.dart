import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../controllers/profile/profile_controller.dart';
import '../../repositories/community/community_repository.dart';
import '../../repositories/profile/profile_repository.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileRepository>(
      () => ProfileRepository(authService: Get.find<AuthService>()),
    );
    Get.lazyPut<CommunityRepository>(
      () => CommunityRepository(authService: Get.find<AuthService>()),
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        repository: Get.find<ProfileRepository>(),
        communityRepository: Get.find<CommunityRepository>(),
        realtimeEvents: PushNotificationService.instance?.events,
      ),
    );
  }
}
