import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../../auth/models/authenticated_user_model.dart';
import '../models/profile_dashboard_model.dart';
import '../repositories/profile_repository.dart';
import '../views/edit_profile_view.dart';
import '../views/setting_view.dart';
import 'edit_profile_controller.dart';
import 'setting_controller.dart';

class ProfileController extends GetxController {
  ProfileController({required ProfileRepository repository})
    : _repository = repository;

  final ProfileRepository _repository;
  final selectedNavIndex = 4.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final Rxn<AuthenticatedUser> authenticatedUser = Rxn<AuthenticatedUser>();
  final Rxn<ProfileDashboardModel> dashboard = Rxn<ProfileDashboardModel>();

  final name = 'My Profile'.obs;
  final email = ''.obs;
  final membership = 'WellBite Member'.obs;
  final profileImagePath = ''.obs;
  final insight = "You've hit 71% of your calories goal today.".obs;

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

  double get caloriesProgress => caloriesGoal.value <= 0
      ? 0
      : calories.value / caloriesGoal.value;

  double get proteinProgress => proteinGoal.value <= 0
      ? 0
      : protein.value / proteinGoal.value;

  double get waterProgress => waterGoal.value <= 0
      ? 0
      : water.value / waterGoal.value;

  @override
  void onInit() {
    super.onInit();
    final routeUser = Get.arguments;
    if (routeUser is AuthenticatedUser) {
      _applyUser(routeUser);
    }
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      _applyDashboard(await _repository.getDashboard());
    } on ProfileException catch (error) {
      errorMessage.value = error.message;
    } on Object {
      errorMessage.value = 'Unable to load your profile. Pull down to retry.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProfile() => loadProfile();

  void _applyUser(AuthenticatedUser user) {
    authenticatedUser.value = user;
    name.value = user.displayName;
    email.value = user.email;
    errorMessage.value = null;
  }

  void _applyDashboard(ProfileDashboardModel dashboard) {
    this.dashboard.value = dashboard;
    final fullName = dashboard.fullName?.trim();
    name.value = fullName == null || fullName.isEmpty
        ? dashboard.email.split('@').first
        : fullName;
    email.value = dashboard.email;
    membership.value = dashboard.membership?.trim().isNotEmpty == true
        ? dashboard.membership!.trim()
        : 'WellBite Member';
    if (dashboard.age != null) age.value = dashboard.age!;
    if (dashboard.heightCm != null) height.value = dashboard.heightCm!.round();
    if (dashboard.weightKg != null) weight.value = dashboard.weightKg!.round();
    if (dashboard.calories != null) {
      calories.value = dashboard.calories!.current.round();
      caloriesGoal.value = dashboard.calories!.goal.round();
    }
    if (dashboard.protein != null) {
      protein.value = dashboard.protein!.current.round();
      proteinGoal.value = dashboard.protein!.goal.round();
    }
    if (dashboard.water != null) {
      water.value = dashboard.water!.current.round();
      waterGoal.value = dashboard.water!.goal.round();
    }
    final dashboardInsight = dashboard.insight?.trim();
    if (dashboardInsight != null && dashboardInsight.isNotEmpty) {
      insight.value = dashboardInsight;
    } else if (caloriesGoal.value > 0) {
      final percent = (caloriesProgress * 100).clamp(0, 999).round();
      insight.value = "You've hit $percent% of your calories goal today.";
    }
    authenticatedUser.value = AuthenticatedUser(
      id: dashboard.userId,
      email: dashboard.email,
      role: authenticatedUser.value?.role ?? 'USER',
      fullName: dashboard.fullName,
      profileImageUrl: dashboard.profileImageUrl,
    );
    errorMessage.value = null;
  }

  Future<void> saveProfile({
    required String fullName,
    required String email,
    required String phone,
    required DateTime dateOfBirth,
    required String gender,
    required double heightCm,
    required double weightKg,
    String? imagePath,
  }) async {
    if (imagePath != null && imagePath.trim().isNotEmpty) {
      await _repository.uploadProfileImage(imagePath);
    }
    _applyDashboard(
      await _repository.updateProfile(
        fullName: fullName,
        email: email,
        phone: phone,
        dateOfBirth: dateOfBirth,
        gender: gender,
        heightCm: heightCm,
        weightKg: weightKg,
      ),
    );
    profileImagePath.value = '';
  }

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
