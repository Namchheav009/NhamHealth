import 'package:get/get.dart';

import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import 'app_routes.dart';

abstract class AppPages {
  AppPages._();

  static const String initialRoute = AppRoutes.splash;

  static final List<GetPage<dynamic>> pages = [
    GetPage<dynamic>(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
    ),
  ];
}