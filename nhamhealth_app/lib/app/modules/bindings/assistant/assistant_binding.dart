import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../controllers/assistant/assistant_controller.dart';
import '../../providers/assistant/assistant_provider.dart';

class AssistantBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AssistantProvider>(
      () => AssistantProvider(authService: Get.find<AuthService>()),
    );
    Get.lazyPut<AssistantController>(
      () => AssistantController(provider: Get.find<AssistantProvider>()),
    );
  }
}
