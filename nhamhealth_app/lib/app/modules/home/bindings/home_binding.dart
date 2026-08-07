import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../providers/home_provider.dart';
import '../repositories/home_repository.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeProvider>(() => HomeProvider());

    Get.lazyPut<HomeRepository>(
      () => HomeRepository(
        provider: Get.find<HomeProvider>(),
      ),
    );

    Get.lazyPut<HomeController>(
      () => HomeController(
        repository: Get.find<HomeRepository>(),
      ),
    );
  }
}
