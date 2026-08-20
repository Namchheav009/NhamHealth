import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../controllers/meal_controller.dart';
import '../providers/meal_provider.dart';
import '../repositories/meal_repository.dart';

class MealBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MealProvider>(
      () => MealProvider(authService: Get.find<AuthService>()),
    );
    Get.lazyPut<MealRepository>(
      () => MealRepository(provider: Get.find<MealProvider>()),
    );
    Get.lazyPut<MealController>(
      () => MealController(repository: Get.find<MealRepository>()),
    );
  }
}
