import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../controllers/wellness/calories_controller.dart';
import '../../controllers/wellness/wellness_controller.dart';

class WellnessBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(authService: Get.find<AuthService>()),
        fenix: true,
      );
    }
    Get.lazyPut<WellnessController>(
      () => WellnessController(profileRepository: Get.find<ProfileRepository>()),
      fenix: true,
    );
    Get.lazyPut<CaloriesController>(() => CaloriesController(), fenix: true);
  }
}
