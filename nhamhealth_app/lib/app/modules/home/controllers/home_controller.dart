import 'package:get/get.dart';

import '../models/home_dashboard_model.dart';
import '../repositories/home_repository.dart';

class HomeController extends GetxController {
  HomeController({required this.repository});

  final HomeRepository repository;
  final isLoading = false.obs;
  final Rxn<HomeDashboardModel> dashboard = Rxn<HomeDashboardModel>();
  final selectedMoodIndex = 0.obs;
  final selectedBottomIndex = 0.obs;

  final moods = <MoodItem>[
    const MoodItem(emoji: '\u{1F60A}', label: 'Happy'),
    const MoodItem(emoji: '\u{1F975}', label: 'Tired'),
    const MoodItem(emoji: '\u{1F63E}', label: 'Stressed'),
    const MoodItem(emoji: '\u{1F4BC}', label: 'Busy'),
    const MoodItem(emoji: '\u{1F634}', label: 'Sleepy'),
    const MoodItem(emoji: '\u{1F60E}', label: 'Great'),
  ];

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
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
        // Get.toNamed(AppRoutes.profile);
        break;
    }
  }

  void openNotifications() {
    // Get.toNamed(AppRoutes.notifications);
  }

  void openFavorites() {
    // Get.toNamed(AppRoutes.favorites);
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
  const MoodItem({required this.emoji, required this.label});

  final String emoji;
  final String label;
}
