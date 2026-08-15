import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../auth/models/authenticated_user_model.dart';
import '../../auth/services/google_auth_service.dart';
import '../../../routes/app_routes.dart';
import '../models/home_dashboard_model.dart';
import '../models/home_route_arguments.dart';
import '../repositories/home_repository.dart';

class HomeController extends GetxController {
  HomeController({required this.repository});

  final HomeRepository repository;
  final isLoading = false.obs;
  final Rxn<HomeDashboardModel> dashboard = Rxn<HomeDashboardModel>();
  final selectedMoodIndex = 0.obs;
  final selectedBottomIndex = 0.obs;
  final isLoggingOut = false.obs;
  final Rxn<AuthenticatedUser> authenticatedUser = Rxn<AuthenticatedUser>();

  final moods = <MoodItem>[
    const MoodItem(imageAsset: 'assets/icons/moods/happy.png', label: 'Happy'),
    const MoodItem(imageAsset: 'assets/icons/moods/tired.png', label: 'Tired'),
    const MoodItem(
      imageAsset: 'assets/icons/moods/stressed.png',
      label: 'Stressed',
    ),
    const MoodItem(imageAsset: 'assets/icons/moods/busy.png', label: 'Busy'),
    const MoodItem(
      imageAsset: 'assets/icons/moods/sleepy.png',
      label: 'Sleepy',
    ),
    const MoodItem(imageAsset: 'assets/icons/moods/great.png', label: 'Great'),
  ];

  @override
  void onInit() {
    super.onInit();
    final routeUser = Get.arguments;
    if (routeUser is HomeRouteArguments) {
      authenticatedUser.value = routeUser.user;
      dashboard.value = routeUser.initialDashboard;
    } else if (routeUser is AuthenticatedUser) {
      authenticatedUser.value = routeUser;
    } else {
      _restoreAuthenticatedUser();
    }
    if (dashboard.value == null) {
      loadDashboard();
    }
  }

  Future<void> _restoreAuthenticatedUser() async {
    authenticatedUser.value = await Get.find<AuthService>().restoreSession();
  }

  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      dashboard.value = await repository.getHomeDashboard();
    } catch (_) {
      Get.snackbar(
        'Error',
        'Unable to load home data.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectMood(int index) {
    selectedMoodIndex.value = index;
  }

  void selectBottomMenu(int index) {
    selectedBottomIndex.value = index;

    switch (index) {
      case 0:
        break;
      case 1:
        // Get.toNamed(AppRoutes.meals);
        break;
      case 2:
        // Get.toNamed(AppRoutes.createPost);
        break;
      case 3:
        // Get.toNamed(AppRoutes.community);
        break;
      case 4:
        Get.offNamed<void>(AppRoutes.profile);
        break;
    }
  }

  void openNotifications() {
    Get.toNamed<void>(AppRoutes.notifications);
  }

  void openFavorites() {
    // Get.toNamed(AppRoutes.favorites);
  }

  void openProfile() {
    selectBottomMenu(4);
  }

  void openWellnessDetails() {
    Get.toNamed(AppRoutes.wellness);
  }

  Future<void> logout() async {
    if (isLoggingOut.value) return;
    isLoggingOut.value = true;

    try {
      await Get.find<AuthService>().logout();
      authenticatedUser.value = null;

      if (Get.isRegistered<GoogleAuthService>()) {
        try {
          await Get.find<GoogleAuthService>().signOut();
        } on Object {
          // The local session is already cleared, so a provider sign-out
          // failure must not keep the user inside the authenticated app.
        }
      }

      Get.offAllNamed(AppRoutes.login);
    } on Object {
      Get.snackbar(
        'Logout failed',
        'Unable to clear your session. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  void getRecommendation() {
    Get.snackbar(
      'AI Recommendation',
      'Preparing recommendations based on your wellness.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void refreshMeals() {
    loadDashboard();
  }
}

class MoodItem {
  const MoodItem({required this.imageAsset, required this.label});

  final String imageAsset;
  final String label;
}
