import 'package:get/get.dart';

import '../../controllers/meals/food_detail_controller.dart';
import '../../../../core/services/app_locale_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../providers/meals/meal_provider.dart';
import '../../repositories/meals/meal_repository.dart';

class FoodDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<FoodDetailController>()) {
      Get.put<FoodDetailController>(
        FoodDetailController(
          repository: MealRepository(
            provider: MealProvider(authService: Get.find<AuthService>()),
          ),
          localeService:
              Get.isRegistered<AppLocaleService>()
                  ? Get.find<AppLocaleService>()
                  : null,
        ),
      );
    }
  }
}
