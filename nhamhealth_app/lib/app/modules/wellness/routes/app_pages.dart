import 'package:get/get.dart';

import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/pages/onboarding_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/auth/views/pages/login_view.dart';
import '../modules/auth/views/pages/register_view.dart';
import '../modules/auth/controllers/account_created_controller.dart';
import '../modules/auth/views/pages/account_created_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/pages/home_view.dart';
import '../modules/notifications/views/pages/notifications_view.dart';

import '../modules/wellness/bindings/wellness_binding.dart';
import '../modules/wellness/views/pages/wellness_view.dart';
import '../modules/wellness/views/pages/calories_view.dart';
import '../modules/wellness/views/pages/protein_view.dart';
import '../modules/wellness/bindings/water_binding.dart';
import '../modules/wellness/views/pages/water_view.dart';
import '../modules/wellness/views/pages/fiber_view.dart';
import '../modules/wellness/views/pages/sugar_view.dart';
import '../modules/wellness/views/pages/ai_meal_auto_fill_view.dart';
import '../modules/wellness/bindings/calories_binding.dart';
import '../modules/wellness/views/pages/food_source_detail_view.dart';
import '../modules/wellness/bindings/food_source_detail_binding.dart';

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
    GetPage<dynamic>(
      name: AppRoutes.onboarding,
      page: () => const OnboardingView(),
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 400),
    ),
    GetPage<dynamic>(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage<dynamic>(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage<dynamic>(
      name: AppRoutes.accountCreated,
      page: () => const AccountCreatedView(),
      binding: BindingsBuilder(
        () => Get.put<AccountCreatedController>(AccountCreatedController()),
      ),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage<dynamic>(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<dynamic>(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      transition: Transition.rightToLeft,
    ),
    GetPage<dynamic>(
      name: AppRoutes.wellness,
      page: () => const WellnessView(),
      binding: WellnessBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    // GetPage<dynamic>(
    //   name: AppRoutes.calories,
    //   page: () => const CaloriesView(),
    //   binding: WellnessBinding(),
    // ),

    GetPage<dynamic>(
      name: AppRoutes.protein,
      page: () => const ProteinView(),
      binding: WellnessBinding(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.water,
      page: () => const WaterView(),
      binding: WaterBinding(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.fiber,
      page: () => const FiberView(),
      binding: WellnessBinding(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.sugar,
      page: () => const SugarView(),
      binding: WellnessBinding(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.aiMealAutoFill,
      page: () => const AiMealAutoFillView(),
      binding: WellnessBinding(),
    ),

    GetPage<dynamic>(
      name: AppRoutes.calories,
      page: () => const CaloriesView(),
      binding: CaloriesBinding(),
      transition: Transition.rightToLeft,
    ),

    GetPage<dynamic>(
      name: AppRoutes.foodSourceDetail,
      page: () => const FoodSourceDetailView(),
      binding: FoodSourceDetailBinding(),
      transition: Transition.rightToLeft,
    ),
  ];
}
