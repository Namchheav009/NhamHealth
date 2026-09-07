import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../controllers/wellness/water_controller.dart';
import '../../repositories/profile/profile_repository.dart';

class WaterBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(authService: Get.find<AuthService>()),
        fenix: true,
      );
    }
    Get.lazyPut<WaterController>(
      () => WaterController(
        repository: Get.find<ProfileRepository>(),
        initialDate:
            Get.arguments is DateTime ? Get.arguments as DateTime : null,
      ),
    );
  }
}
