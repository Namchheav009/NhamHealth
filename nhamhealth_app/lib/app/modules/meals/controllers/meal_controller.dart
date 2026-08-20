import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../widgets/app_alert.dart';
import '../../../routes/app_routes.dart';
import '../../auth/models/authenticated_user_model.dart';
import '../../home/controllers/home_controller.dart';
import '../models/meal_model.dart';
import '../models/meal_category_model.dart';
import '../repositories/meal_repository.dart';

class MealController extends GetxController {
  MealController({required this.repository});

  final MealRepository repository;
  final selectedCategory = 0.obs;
  final currentSlide = 0.obs;
  final selectedBottomIndex = 1.obs;
  final searchQuery = ''.obs;
  final Rxn<AuthenticatedUser> authenticatedUser = Rxn<AuthenticatedUser>();
  final unreadNotificationCount = 0.obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  final PageController slideController = PageController();
  final TextEditingController searchController = TextEditingController();

  Timer? _slideTimer;

  final categories = <MealCategoryModel>[MealCategoryModel.all].obs;

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

  final meals = <MealModel>[].obs;

  List<MealModel> get filteredMeals {
    final category = categories[selectedCategory.value];
    final query = searchQuery.value.trim().toLowerCase();

    return meals.where((meal) {
      final matchesCategory =
          category.id == MealCategoryModel.all.id ||
          meal.categoryId == category.id;
      final matchesSearch =
          query.isEmpty ||
          meal.name.replaceAll('\n', ' ').toLowerCase().contains(query) ||
          meal.category.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    _restoreAuthenticatedUser();
    final arguments = Get.arguments;
    if (arguments is Map && arguments['query'] is String) {
      final query = (arguments['query'] as String).trim();
      searchController.text = query;
      searchQuery.value = query;
    }
    startSlideShow();
    loadMeals();
    loadUnreadNotificationCount();
  }

  Future<void> loadMeals() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final results = await Future.wait<Object>([
        repository.getMeals(),
        repository.getCategories(),
        repository.getFavoriteMealIds(),
      ]);
      final loadedMeals = results[0] as List<MealModel>;
      final loadedCategories = results[1] as List<MealCategoryModel>;
      final favoriteIds = results[2] as Set<int>;
      for (final meal in loadedMeals) {
        meal.isFavorite = favoriteIds.contains(meal.id);
      }
      meals.assignAll(loadedMeals);
      categories.assignAll([MealCategoryModel.all, ...loadedCategories]);
      if (selectedCategory.value >= categories.length) {
        selectedCategory.value = 0;
      }
    } on Object catch (error) {
      errorMessage.value = error.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUnreadNotificationCount() async {
    try {
      unreadNotificationCount.value =
          await repository.getUnreadNotificationCount();
    } on Object {
      // Meal content should remain available if the badge cannot be refreshed.
    }
  }

  Future<void> _restoreAuthenticatedUser() async {
    if (Get.isRegistered<AuthService>()) {
      authenticatedUser.value = await Get.find<AuthService>().restoreSession();
    }
  }

  void selectCategory(int index) {
    selectedCategory.value = index;
  }

  void updateSearch(String value) => searchQuery.value = value;

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  void openFavorites() => Get.toNamed<void>(AppRoutes.favorites);

  Future<void> openNotifications() async {
    await Get.toNamed<void>(AppRoutes.notifications);
    await loadUnreadNotificationCount();
  }

  void openProfile() => Get.offNamed<void>(
    AppRoutes.profile,
    arguments: authenticatedUser.value,
  );

  Future<void> logout() async {
    if (Get.isRegistered<AuthService>()) {
      await Get.find<AuthService>().logout();
    }
    authenticatedUser.value = null;
    Get.offAllNamed<void>(AppRoutes.login);
  }

  void onSlideChanged(int index) {
    currentSlide.value = index;
  }

  Future<void> toggleFavorite(int index) async {
    final meal = meals[index];
    final previous = meal.isFavorite;
    meal.isFavorite = !previous;
    meals.refresh();
    try {
      await repository.setFavorite(meal.id, favorite: meal.isFavorite);
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().setMealFavoriteState(
          meal.id,
          favorite: meal.isFavorite,
        );
      }
    } on Object catch (error) {
      meal.isFavorite = previous;
      meals.refresh();
      AppAlert.error(title: 'Favorites unavailable', message: error.toString());
    }
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
    searchController.dispose();
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
