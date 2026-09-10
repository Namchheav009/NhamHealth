import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../controllers/community/community_report_controller.dart';
import '../../repositories/community/community_repository.dart';

class CommunityReportBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CommunityRepository>()) {
      Get.lazyPut<CommunityRepository>(
        () => CommunityRepository(authService: Get.find<AuthService>()),
        fenix: true,
      );
    }
    if (!Get.isRegistered<CommunityReportController>()) {
      Get.lazyPut<CommunityReportController>(
        () => CommunityReportController(
          repository: Get.find<CommunityRepository>(),
        ),
        fenix: true,
      );
    }
  }
}
