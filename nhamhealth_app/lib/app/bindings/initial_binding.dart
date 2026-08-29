import 'package:get/get.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/app_security_service.dart';
import '../../core/services/app_locale_service.dart';
import '../../core/services/app_theme_service.dart';
import '../modules/services/auth/google_auth_service.dart';

class InitialBinding extends Bindings {
  static void ensureRegistered({
    AppLocaleService? localeService,
    AppThemeService? themeService,
  }) {
    if (!Get.isRegistered<AppLocaleService>()) {
      Get.put<AppLocaleService>(
        localeService ?? AppLocaleService(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(AuthService(), permanent: true);
    }
    if (!Get.isRegistered<AppThemeService>()) {
      Get.put<AppThemeService>(
        themeService ?? AppThemeService(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<GoogleAuthService>()) {
      Get.put<GoogleAuthService>(GoogleAuthService(), permanent: true);
    }
    if (!Get.isRegistered<AppSecurityService>()) {
      Get.put<AppSecurityService>(
        AppSecurityService(authService: Get.find<AuthService>()),
        permanent: true,
      );
    }
  }

  @override
  void dependencies() {
    ensureRegistered();
  }
}
