import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../controllers/community/community_post_detail_controller.dart';
import '../../repositories/community/community_repository.dart';

class CommunityPostDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CommunityRepository>()) {
      Get.lazyPut<CommunityRepository>(
        () => CommunityRepository(authService: Get.find<AuthService>()),
      );
    }
    Get.lazyPut<CommunityPostDetailController>(
      () => CommunityPostDetailController(
        postId: Get.parameters['postId'] ?? '',
        repository: Get.find<CommunityRepository>(),
        authService: Get.find<AuthService>(),
      ),
    );
  }
}
