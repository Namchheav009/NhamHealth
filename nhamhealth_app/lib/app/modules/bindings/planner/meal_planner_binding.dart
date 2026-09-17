import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../controllers/planner/meal_planner_controller.dart';
import '../../providers/planner/meal_planner_provider.dart';

class MealPlannerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MealPlannerProvider>(
      () => MealPlannerProvider(authService: Get.find<AuthService>()),
      fenix: true,
    );
    Get.lazyPut<MealPlannerController>(
      () => MealPlannerController(provider: Get.find<MealPlannerProvider>()),
      fenix: true,
    );
  }
}
