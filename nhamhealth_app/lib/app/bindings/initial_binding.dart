import 'package:get/get.dart';

import '../../core/services/auth_service.dart';
import '../modules/auth/services/google_auth_service.dart';

class InitialBinding extends Bindings {
  static void ensureRegistered() {
    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(AuthService(), permanent: true);
    }
    if (!Get.isRegistered<GoogleAuthService>()) {
      Get.put<GoogleAuthService>(GoogleAuthService(), permanent: true);
    }
  }

  @override
  void dependencies() {
    ensureRegistered();
  }
}
