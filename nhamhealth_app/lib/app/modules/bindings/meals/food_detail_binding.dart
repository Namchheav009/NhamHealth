import 'package:get/get.dart';

import '../../controllers/meals/food_detail_controller.dart';
import '../../../../core/services/auth_service.dart';
import '../../providers/meals/meal_provider.dart';
import '../../repositories/meals/meal_repository.dart';

class FoodDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MealProvider>()) {
      Get.lazyPut<MealProvider>(
        () => MealProvider(authService: Get.find<AuthService>()),
      );
    }
    if (!Get.isRegistered<MealRepository>()) {
      Get.lazyPut<MealRepository>(
        () => MealRepository(provider: Get.find<MealProvider>()),
      );
    }
    Get.lazyPut<FoodDetailController>(
      () => FoodDetailController(repository: Get.find<MealRepository>()),
    );
  }
}
