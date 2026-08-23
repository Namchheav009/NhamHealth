import 'package:get/get.dart';

import '../modules/bindings/onboarding/onboarding_binding.dart';
import '../modules/views/onboarding/onboarding_view.dart';
import '../modules/bindings/splash/splash_binding.dart';
import '../modules/views/splash/splash_view.dart';
import '../modules/views/auth/login_view.dart';
import '../modules/views/auth/register_view.dart';
import '../modules/bindings/auth/login_binding.dart';
import '../modules/bindings/auth/register_binding.dart';
import '../modules/controllers/auth/account_created_controller.dart';
import '../modules/views/auth/account_created_view.dart';
import '../modules/bindings/home/home_binding.dart';
import '../modules/views/home/home_view.dart';
import '../modules/bindings/meals/meal_binding.dart';
import '../modules/bindings/meals/food_detail_binding.dart';
import '../modules/bindings/meals/ingredient_binding.dart';
import '../modules/views/meals/meal_view.dart';
import '../modules/views/meals/food_detail_view.dart';
import '../modules/views/meals/ingredient_view.dart';
import '../modules/views/notifications/notifications_view.dart';
import '../modules/bindings/notifications/notifications_binding.dart';
import '../modules/bindings/favorites/favorites_binding.dart';
import '../modules/views/favorites/favorites_view.dart';
import '../modules/bindings/profile/profile_binding.dart';
import '../modules/bindings/profile/change_password_binding.dart';
import '../modules/views/profile/change_password_view.dart';
import '../modules/views/profile/profile_view.dart';
import '../modules/bindings/profile/language_binding.dart';
import '../modules/views/profile/language_view.dart';

import '../modules/bindings/wellness/wellness_binding.dart';
import '../modules/views/wellness/wellness_view.dart';
import '../modules/views/wellness/calories_view.dart';
import '../modules/views/wellness/protein_view.dart';
import '../modules/bindings/wellness/water_binding.dart';
import '../modules/views/wellness/water_view.dart';
import '../modules/views/wellness/fiber_view.dart';
import '../modules/views/wellness/sugar_view.dart';
import '../modules/views/wellness/ai_food_view.dart';
import '../modules/views/wellness/ai_meal_auto_fill_view.dart';
import '../modules/bindings/wellness/ai_food_binding.dart';
import '../modules/bindings/wellness/ai_meal_auto_fill_binding.dart';
import '../modules/bindings/wellness/calories_binding.dart';
import '../modules/views/wellness/food_source_detail_view.dart';
import '../modules/bindings/wellness/food_source_detail_binding.dart';

import 'app_routes.dart';
import '../modules/views/feed/feed_page.dart';
import '../modules/bindings/feed/feed_binding.dart';

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
      binding: LoginBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage<dynamic>(
      name: AppRoutes.register,
      page: () => const RegisterScreen(),
      binding: RegisterBinding(),
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
      transition: Transition.noTransition,
    ),
    GetPage<dynamic>(
      name: AppRoutes.meals,
      page: () => const MealView(),
      binding: MealBinding(),
      transition: Transition.noTransition,
    ),
    GetPage<dynamic>(
      name: AppRoutes.foodDetail,
      page: () => const FoodDetailView(),
      binding: FoodDetailBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage<dynamic>(
      name: AppRoutes.ingredients,
      page: () => const IngredientView(),
      binding: IngredientBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage<dynamic>(
      name: AppRoutes.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
      transition: Transition.noTransition,
    ),
    GetPage<dynamic>(
      name: AppRoutes.changePassword,
      page: () => const ChangePasswordView(),
      binding: ChangePasswordBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage<dynamic>(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage<dynamic>(
      name: AppRoutes.favorites,
      page: () => const FavoritesView(),
      binding: FavoritesBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage<dynamic>(
      name: AppRoutes.language,
      page: () => const LanguageView(),
      binding: LanguageBinding(),
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
      binding: AiMealAutoFillBinding(),
    ),
    GetPage<dynamic>(
      name: AppRoutes.aiFood,
      page: () => const AiFoodView(),
      binding: AiFoodBinding(),
      transition: Transition.rightToLeft,
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

    GetPage<dynamic>(
      name: AppRoutes.feed,
      page: () => const FeedPage(),
      binding: FeedBinding(),
      transition: Transition.noTransition,
    ),
  ];
}
