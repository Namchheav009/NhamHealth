import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../controllers/favorites_controller.dart';
import '../providers/favorites_provider.dart';
import '../repositories/favorites_repository.dart';

class FavoritesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FavoritesProvider>(
      () => FavoritesProvider(authService: Get.find<AuthService>()),
    );
    Get.lazyPut<FavoritesRepository>(
      () => FavoritesRepository(provider: Get.find<FavoritesProvider>()),
    );
    Get.lazyPut<FavoritesController>(
      () => FavoritesController(repository: Get.find<FavoritesRepository>()),
    );
  }
}
