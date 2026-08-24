import 'package:get/get.dart';
import '../../controllers/community/community_controller.dart';
import '../../repositories/community/community_repository.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CommunityRepository>(
      () => CommunityRepository(authService: Get.find()),
    );
    Get.lazyPut<CommunityController>(
      () => CommunityController(repository: Get.find<CommunityRepository>()),
    );
  }
}
