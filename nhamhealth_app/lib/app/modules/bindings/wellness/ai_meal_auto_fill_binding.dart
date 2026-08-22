import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../controllers/wellness/ai_meal_auto_fill_controller.dart';
import '../../controllers/wellness/calories_controller.dart';
import '../../controllers/wellness/wellness_controller.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../repositories/wellness/food_nutrition_repository.dart';

class AiMealAutoFillBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.lazyPut<ProfileRepository>(
        () => ProfileRepository(authService: Get.find<AuthService>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<WellnessController>()) {
      Get.lazyPut<WellnessController>(
        () => WellnessController(profileRepository: Get.find()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CaloriesController>()) {
      Get.lazyPut<CaloriesController>(() => CaloriesController(), fenix: true);
    }
    Get.lazyPut<FoodNutritionRepository>(() => FoodNutritionRepository());
    Get.lazyPut<AiMealAutoFillController>(
      () => AiMealAutoFillController(
        nutritionRepository: Get.find(),
        profileRepository: Get.find(),
        caloriesController: Get.find(),
        wellnessController: Get.find(),
      ),
    );
  }
}
