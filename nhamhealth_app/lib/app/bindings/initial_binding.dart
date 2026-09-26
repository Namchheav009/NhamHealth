import 'package:get/get.dart';

import '../../core/services/app_locale_service.dart';
import '../../core/services/app_security_service.dart';
import '../../core/services/app_theme_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/current_user_service.dart';
import '../../core/services/dynamic_notification_sync_service.dart';
import '../modules/services/auth/google_auth_service.dart';
import '../modules/providers/meals/meal_provider.dart';
import '../modules/repositories/meals/meal_repository.dart';

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
    // The Meals tab can be created from an IndexedStack before a route binding
    // runs, so its data dependencies must exist from application startup.
    if (!Get.isRegistered<MealProvider>()) {
      Get.put<MealProvider>(
        MealProvider(authService: Get.find<AuthService>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<MealRepository>()) {
      Get.put<MealRepository>(
        MealRepository(provider: Get.find<MealProvider>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<CurrentUserService>()) {
      Get.put<CurrentUserService>(
        CurrentUserService(authService: Get.find<AuthService>()),
        permanent: true,
      );
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
    if (!Get.isRegistered<DynamicNotificationSyncService>()) {
      Get.put<DynamicNotificationSyncService>(
        DynamicNotificationSyncService(authService: Get.find<AuthService>()),
        permanent: true,
      );
    }
  }

  @override
  void dependencies() {
    ensureRegistered();
  }
}
