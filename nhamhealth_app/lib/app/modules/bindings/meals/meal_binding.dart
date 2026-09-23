import 'package:get/get.dart';

import '../../../../core/services/app_locale_service.dart';
import '../../controllers/meals/meal_controller.dart';
import '../../repositories/meals/meal_repository.dart';

class MealBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<MealController>()) {
      Get.put<MealController>(
        MealController(
          repository: Get.find<MealRepository>(),
        localeService:
            Get.isRegistered<AppLocaleService>()
                ? Get.find<AppLocaleService>()
                : null,
        ),
        permanent: true,
      );
    }
  }
}
