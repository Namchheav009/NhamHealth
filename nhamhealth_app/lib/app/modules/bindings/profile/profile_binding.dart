import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../controllers/profile/profile_controller.dart';
import '../../repositories/profile/profile_repository.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileRepository>(
      () => ProfileRepository(authService: Get.find<AuthService>()),
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(repository: Get.find<ProfileRepository>()),
    );
  }
}
