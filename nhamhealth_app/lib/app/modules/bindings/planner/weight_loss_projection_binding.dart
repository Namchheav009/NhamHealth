import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../controllers/planner/weight_loss_projection_controller.dart';
import '../../providers/planner/meal_planner_provider.dart';

class WeightLossProjectionBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MealPlannerProvider>()) {
      Get.lazyPut<MealPlannerProvider>(
        () => MealPlannerProvider(authService: Get.find<AuthService>()),
        fenix: true,
      );
    }

    Get.lazyPut<WeightLossProjectionController>(
      () => WeightLossProjectionController(
        provider: Get.find<MealPlannerProvider>(),
      ),
      fenix: true,
    );
  }
}
