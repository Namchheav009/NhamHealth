import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

class MealController extends GetxController {
  final selectedCategory = 0.obs;
  final currentSlide = 0.obs;
  final selectedBottomIndex = 1.obs;

  final PageController slideController = PageController();

  Timer? _slideTimer;

  final categories = <String>['All', 'Breakfast', 'Lunch', 'Dinner', 'Snacks'];

  final slides = <MealSlideModel>[
    MealSlideModel(
      title: 'Meals for more',
      highlight: 'energy.',
      description: 'Nutrient-rich meals to keep\nyou active and focused.',
      image: 'assets/images/meals/slideshow1.png',
    ),
    MealSlideModel(
      title: 'Start your day',
      highlight: 'healthy.',
      description: 'Fresh balanced meals for a\nbetter and stronger morning.',
      image: 'assets/images/meals/slideshow2.png',
    ),
    MealSlideModel(
      title: 'Healthy food,',
      highlight: 'happy life.',
      description: 'Simple nutritious meals to\nsupport your daily wellness.',
      image: 'assets/images/meals/slideshow3.png',
    ),
  ];

  final meals =
      <MealModel>[
        MealModel(
          name: 'Grilled Chicken\nPower Bowl',
          calories: 520,
          image: 'assets/images/meals/healthy_salad.jpg',
        ),
        MealModel(
          name: 'Grilled Chicken\nPower Bowl',
          calories: 520,
          image: 'assets/images/meals/healthy_salad.jpg',
        ),
        MealModel(
          name: 'Grilled Chicken\nPower Bowl',
          calories: 520,
          image: 'assets/images/meals/healthy_salad.jpg',
        ),
        MealModel(
          name: 'Chicken Fresh\nSalad',
          calories: 430,
          image: 'assets/images/meals/healthy_salad.jpg',
        ),
        MealModel(
          name: 'Healthy Chicken\nWrap',
          calories: 390,
          image: 'assets/images/meals/healthy_salad.jpg',
        ),
        MealModel(
          name: 'Chicken Avocado\nBowl',
          calories: 480,
          image: 'assets/images/meals/healthy_salad.jpg',
        ),
      ].obs;

  @override
  void onInit() {
    super.onInit();
    startSlideShow();
  }

  void selectCategory(int index) {
    selectedCategory.value = index;
  }

  void onSlideChanged(int index) {
    currentSlide.value = index;
  }

  void toggleFavorite(int index) {
    meals[index].isFavorite = !meals[index].isFavorite;
    meals.refresh();
  }

  void selectBottomMenu(int index) {
    selectedBottomIndex.value = index;

    switch (index) {
      case 0:
        Get.offNamed<void>(AppRoutes.home);
        break;
      case 1:
        break;
      case 2:
        // Create post route is not available yet.
        break;
      case 3:
        // Community route is not available yet.
        break;
      case 4:
        Get.offNamed<void>(AppRoutes.profile);
        break;
    }
  }

  void startSlideShow() {
    _slideTimer?.cancel();

    _slideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!slideController.hasClients) return;

      int nextPage = currentSlide.value + 1;

      if (nextPage >= slides.length) {
        nextPage = 0;
      }

      slideController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void onClose() {
    _slideTimer?.cancel();
    slideController.dispose();
    super.onClose();
  }
}

class MealSlideModel {
  final String title;
  final String highlight;
  final String description;
  final String image;

  MealSlideModel({
    required this.title,
    required this.highlight,
    required this.description,
    required this.image,
  });
}

class MealModel {
  final String name;
  final int calories;
  final String image;

  bool isFavorite;

  MealModel({
    required this.name,
    required this.calories,
    required this.image,
    this.isFavorite = false,
  });
}
