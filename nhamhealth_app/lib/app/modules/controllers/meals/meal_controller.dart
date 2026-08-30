import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../widgets/app_alert.dart';
import '../../../routes/app_routes.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../home/home_controller.dart';
import '../../models/meals/meal_model.dart';
import '../../models/meals/meal_category_model.dart';
import '../../repositories/meals/meal_repository.dart';

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
  Timer? _searchTimer;
  int _mealRequestVersion = 0;
  Set<int> _favoriteMealIds = const <int>{};

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

  List<MealModel> get filteredMeals => meals.toList(growable: false);

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
    unawaited(_loadCategories());
    unawaited(_loadFavoriteMealIds());
    loadMeals();
    loadUnreadNotificationCount();
  }

  Future<void> loadMeals() async {
    final requestVersion = ++_mealRequestVersion;
    final categoryId = selectedCategory.value < categories.length
        ? categories[selectedCategory.value].id
        : MealCategoryModel.all.id;

    try {
      isLoading.value = true;
      errorMessage.value = null;

      final loadedMeals = await repository.getMeals(
        keyword: searchQuery.value,
        categoryId: categoryId,
      );
      if (requestVersion != _mealRequestVersion) return;
      for (final meal in loadedMeals) {
        meal.isFavorite = _favoriteMealIds.contains(meal.id);
      }
      meals.assignAll(loadedMeals);
    } on Object catch (error) {
      if (requestVersion != _mealRequestVersion) return;
      errorMessage.value = error.toString();
    } finally {
      if (requestVersion == _mealRequestVersion) isLoading.value = false;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final selectedId =
          selectedCategory.value < categories.length
              ? categories[selectedCategory.value].id
              : MealCategoryModel.all.id;
      final loaded = await repository.getCategories();
      categories.assignAll([MealCategoryModel.all, ...loaded]);
      final restoredIndex = categories.indexWhere(
        (category) => category.id == selectedId,
      );
      selectedCategory.value = restoredIndex < 0 ? 0 : restoredIndex;
    } on Object {
      // "All" remains usable if category metadata cannot be refreshed.
    }
  }

  Future<void> _loadFavoriteMealIds() async {
    try {
      _favoriteMealIds = await repository.getFavoriteMealIds();
      for (final meal in meals) {
        meal.isFavorite = _favoriteMealIds.contains(meal.id);
      }
      meals.refresh();
    } on Object {
      // Favorites must not delay or hide the meal list.
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
    if (index < 0 || index >= categories.length) return;
    selectedCategory.value = index;
    _searchTimer?.cancel();
    loadMeals();
  }

  void updateSearch(String value) {
    searchQuery.value = value;
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 400), loadMeals);
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    _searchTimer?.cancel();
    loadMeals();
  }

  void openFavorites() => Get.toNamed<void>(AppRoutes.favorites);

  void openFoodDetail(MealModel meal) =>
      Get.toNamed<void>(AppRoutes.foodDetail, arguments: meal);

  Future<void> openNotifications() async {
    await Get.toNamed<void>(AppRoutes.notifications);
    await loadUnreadNotificationCount();
  }

  void openProfile() =>
      Get.toNamed<void>(AppRoutes.profile, arguments: authenticatedUser.value);

  void openSettings() {
    Get.offNamed<void>(AppRoutes.settings);
  }

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
    if (index == 4) {
      openSettings();
      return;
    }
    if (index == selectedBottomIndex.value) return;
    selectedBottomIndex.value = index;

    switch (index) {
      case 0:
        Get.offNamed<void>(AppRoutes.home);
        break;
      case 1:
        break;
      case 2:
        Get.offNamed<void>(AppRoutes.community);
        break;
      case 4:
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
    _searchTimer?.cancel();
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
