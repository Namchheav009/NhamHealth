import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../controllers/planner/weight_loss_projection_controller.dart';
import '../../providers/planner/meal_planner_provider.dart';
import '../../repositories/profile/profile_repository.dart';

class MealPlannerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MealPlannerProvider>(
      () => MealPlannerProvider(authService: Get.find<AuthService>()),
      fenix: true,
    );
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(authService: Get.find<AuthService>()),
        fenix: true,
      );
    }
    Get.lazyPut<MealPlannerController>(
      () => MealPlannerController(
        provider: Get.find<MealPlannerProvider>(),
        profileRepository: Get.find<ProfileRepository>(),
        authService: Get.find<AuthService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<WeightLossProjectionController>(
      () => WeightLossProjectionController(
        provider: Get.find<MealPlannerProvider>(),
      ),
      fenix: true,
    );
  }
}
