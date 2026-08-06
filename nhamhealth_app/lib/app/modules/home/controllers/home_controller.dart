import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/home_dashboard_model.dart';
import '../repositories/home_repository.dart';

class HomeController extends GetxController {
  final HomeRepository repository;

  HomeController({
    required this.repository,
  });

  final isLoading = false.obs;

  final Rxn<HomeDashboardModel> dashboard =
      Rxn<HomeDashboardModel>();

  final selectedMoodIndex = 0.obs;

  final selectedBottomIndex = 0.obs;

  final moods = <MoodItem>[
    MoodItem(
      emoji: '😊',
      label: 'Happy',
    ),
    MoodItem(
      emoji: '🥵',
      label: 'Tired',
    ),
    MoodItem(
      emoji: '😫',
      label: 'Stressed',
    ),
    MoodItem(
      emoji: '💼',
      label: 'Busy',
    ),
    MoodItem(
      emoji: '😴',
      label: 'Sleepy',
    ),
    MoodItem(
      emoji: '😎',
      label: 'Great',
    ),
  ];

  @override
  void onInit() {
    super.onInit();

    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;

      dashboard.value =
          await repository.getHomeDashboard();
    } catch (e) {
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
  final String emoji;
  final String label;

  MoodItem({
    required this.emoji,
    required this.label,
  });
}