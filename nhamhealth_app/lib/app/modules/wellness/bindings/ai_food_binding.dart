import 'package:get/get.dart';

import '../controllers/ai_food_controller.dart';
import '../controllers/calories_controller.dart';
import '../controllers/wellness_controller.dart';
import '../repositories/food_nutrition_repository.dart';
import '../services/food_ai_service.dart';
import '../services/food_recommendation_service.dart';

class AiFoodBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<WellnessController>()) {
      Get.lazyPut<WellnessController>(() => WellnessController(), fenix: true);
    }
    if (!Get.isRegistered<CaloriesController>()) {
      Get.lazyPut<CaloriesController>(() => CaloriesController(), fenix: true);
    }
    Get.lazyPut<FoodAiService>(() => FoodAiService());
    Get.lazyPut<FoodNutritionRepository>(() => FoodNutritionRepository());
    Get.lazyPut<FoodRecommendationService>(() => FoodRecommendationService());
    Get.lazyPut<AiFoodController>(
      () => AiFoodController(
        aiService: Get.find(),
        nutritionRepository: Get.find(),
        recommendationService: Get.find(),
        caloriesController: Get.find(),
        wellnessController: Get.find(),
      ),
    );
  }
}
