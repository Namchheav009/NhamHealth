import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../profile/repositories/profile_repository.dart';
import '../controllers/calories_controller.dart';
import '../controllers/wellness_controller.dart';

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
