import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../views/pages/edit_profile_view.dart';
import '../views/pages/setting_view.dart';
import 'edit_profile_controller.dart';
import 'setting_controller.dart';

class ProfileController extends GetxController {
  final selectedNavIndex = 4.obs;

  final name = 'Sarah Smith'.obs;
  final email = 'sarasmith009@gmail.com'.obs;
  final membership = 'WellBite Member'.obs;
  final profileImagePath = ''.obs;

  final age = 21.obs;
  final height = 165.obs;
  final weight = 58.obs;

  double get bmi {
    final heightInMeters = height.value / 100;
    if (heightInMeters <= 0) return 0;
    return weight.value / (heightInMeters * heightInMeters);
  }

  String get bmiStatus {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  final calories = 1420.obs;
  final caloriesGoal = 2000.obs;

  final protein = 82.obs;
  final proteinGoal = 120.obs;

  final water = 6.obs;
  final waterGoal = 8.obs;

  double get caloriesProgress => calories.value / caloriesGoal.value;

  double get proteinProgress => protein.value / proteinGoal.value;

  double get waterProgress => water.value / waterGoal.value;

  void changeNavigation(int index) {
    selectedNavIndex.value = index;

    switch (index) {
      case 0:
        Get.offNamed<void>(AppRoutes.home);
        break;
      case 1:
        // Get.offNamed(AppRoutes.food);
        break;
      case 2:
        // Create post
        break;
      case 3:
        // Get.offNamed(AppRoutes.community);
        break;
      case 4:
        // Already profile
        break;
    }
  }

  void editProfile() {
    Get.to(
      () => const EditProfileView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<EditProfileController>(
          () => EditProfileController(profileController: this),
        );
      }),
    );
  }

  void openNotifications() {
    Get.toNamed<void>(AppRoutes.notifications);
  }

  void openSettings() {
    Get.to(
      () => const SettingsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SettingsController>(() => SettingsController());
      }),
    );
  }

  void openProgressDetails() {
    // Get.toNamed(AppRoutes.progress);
  }

  void openInsights() {
    // Get.toNamed(AppRoutes.insights);
  }
}
