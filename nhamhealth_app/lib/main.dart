import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'app/translations/app_translations.dart';
import 'app/widgets/forest_glow_background.dart';
import 'core/services/app_locale_service.dart';
import 'core/services/app_theme_service.dart';
import 'core/services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeService = AppLocaleService();
  final initialLocale = await localeService.loadLocale();
  final themeService = AppThemeService();
  await themeService.loadThemeMode();
  InitialBinding.ensureRegistered(
    localeService: localeService,
    themeService: themeService,
  );
  runApp(NhamHealthApp(initialLocale: initialLocale));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_initializePushNotifications());
  });
}

Future<void> _initializePushNotifications() async {
  if (!PushNotificationService.isSupported) return;
  try {
    await Firebase.initializeApp();
    await PushNotificationService(authService: Get.find()).initialize();
  } on Object catch (error) {
    // Notifications are optional; an unavailable service must not block startup.
    debugPrint('Push notification initialization unavailable: $error');
  }
}

class NhamHealthApp extends StatelessWidget {
  const NhamHealthApp({
    super.key,
    this.initialLocale = AppLocaleService.fallbackLocale,
  });

  final Locale initialLocale;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Nham Health',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: AppLocaleService.fallbackLocale,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode:
          Get.isRegistered<AppThemeService>()
              ? Get.find<AppThemeService>().themeMode
              : AppThemeService.fallbackThemeMode,
      initialRoute: AppPages.initialRoute,
      getPages: AppPages.pages,
      initialBinding: InitialBinding(),
      // Use the same opaque page-opening motion in light and dark mode.
      // Unlike a fade, this never makes the incoming page transparent.
      defaultTransition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 220),
      opaqueRoute: true,
      builder:
          (context, child) =>
              ForestGlowBackground(child: child ?? const SizedBox.shrink()),
    );
  }
}
