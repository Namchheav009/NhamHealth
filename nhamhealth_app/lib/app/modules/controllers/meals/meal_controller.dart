import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../widgets/app_alert.dart';
import '../../../routes/app_routes.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../home/home_controller.dart';
import '../../models/meals/meal_category_model.dart';
import '../../models/meals/meal_model.dart';
import '../../repositories/meals/meal_repository.dart';

class MealController extends GetxController with WidgetsBindingObserver {
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
  final personalizedIdeas = <MealModel>[].obs;
  final isIdeasLoading = false.obs;
  final ideasErrorMessage = RxnString();
  final maxCalories = RxnInt();
  final maxCookingMinutes = RxnInt();

  final PageController slideController = PageController();
  final TextEditingController searchController = TextEditingController();

  Timer? _slideTimer;
  Timer? _searchTimer;
  int _mealRequestVersion = 0;
  bool _refreshInProgress = false;
  Set<int> _favoriteMealIds = const <int>{};

  final categories = <MealCategoryModel>[MealCategoryModel.all].obs;

  final slides = <MealSlideModel>[
    MealSlideModel(
      title: 'Healthy food,',
      highlight: 'happy life.',
      description: 'Simple, nutritious meals to\nsupport your daily wellness.',
      image: 'assets/images/meals/slideshow3.png',
    ),
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
  ];

  final meals = <MealModel>[].obs;

  List<MealModel> get filteredMeals => meals
      .where((meal) {
        final calorieLimit = maxCalories.value;
        final cookingLimit = maxCookingMinutes.value;
        return (calorieLimit == null || meal.calories <= calorieLimit) &&
            (cookingLimit == null ||
                (meal.cookingTimeMinutes != null &&
                    meal.cookingTimeMinutes! <= cookingLimit));
      })
      .toList(growable: false);

  int get activeFilterCount =>
      (selectedCategory.value == 0 ? 0 : 1) +
      (maxCalories.value == null ? 0 : 1) +
      (maxCookingMinutes.value == null ? 0 : 1);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
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
    unawaited(loadPersonalizedIdeas());
    loadMeals();
    loadUnreadNotificationCount();
  }

  Future<void> refreshPage({
    bool refreshIdeas = true,
    bool showFeedback = true,
  }) async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    _searchTimer?.cancel();

    try {
      await Future.wait<void>([
        _restoreAuthenticatedUser(),
        _loadCategories(),
        _loadFavoriteMealIds(),
        loadUnreadNotificationCount(),
      ]);
      await Future.wait<void>([
        loadMeals(),
        loadPersonalizedIdeas(refresh: refreshIdeas),
      ]);

      if (!showFeedback) return;
      final mealError = errorMessage.value;
      if (mealError != null) {
        unawaited(AppAlert.error(title: 'Refresh failed', message: mealError));
      } else if (ideasErrorMessage.value != null) {
        unawaited(
          AppAlert.error(
            title: 'Meal ideas unavailable',
            message:
                'Meals were updated, but personalized ideas could not be refreshed.',
          ),
        );
      } else {
        unawaited(
          AppAlert.success(
            title: 'Meals updated',
            message: 'The latest meals and personalized ideas are now shown.',
          ),
        );
      }
    } finally {
      _refreshInProgress = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshPage(refreshIdeas: false, showFeedback: false));
    }
  }

  Future<void> loadMeals() async {
    final requestVersion = ++_mealRequestVersion;
    final categoryId =
        selectedCategory.value < categories.length
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
      final loaded = await repository.getCategories();
      categories.assignAll([MealCategoryModel.all, ...loaded]);
      if (selectedCategory.value >= categories.length) {
        selectedCategory.value = 0;
      }
    } on Object {
      // The All filter remains available if category metadata cannot load.
    }
  }

  Future<void> _loadFavoriteMealIds() async {
    try {
      _favoriteMealIds = await repository.getFavoriteMealIds();
      for (final meal in meals) {
        meal.isFavorite = _favoriteMealIds.contains(meal.id);
      }
      for (final meal in personalizedIdeas) {
        meal.isFavorite = _favoriteMealIds.contains(meal.id);
      }
      meals.refresh();
      personalizedIdeas.refresh();
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

  void selectCategory(int index) {
    if (index < 0 || index >= categories.length) return;
    if (selectedCategory.value == index) return;
    selectedCategory.value = index;
    _searchTimer?.cancel();
    loadMeals();
  }

  void showAllMeals() {
    searchController.clear();
    searchQuery.value = '';
    _searchTimer?.cancel();
    selectedCategory.value = 0;
    loadMeals();
  }

  void setMaxCalories(int? value) => maxCalories.value = value;

  void setMaxCookingMinutes(int? value) => maxCookingMinutes.value = value;

  void clearMealFilters() {
    maxCalories.value = null;
    maxCookingMinutes.value = null;
    if (selectedCategory.value != 0) {
      selectedCategory.value = 0;
      loadMeals();
    }
  }

  Future<void> loadPersonalizedIdeas({bool refresh = false}) async {
    if (isIdeasLoading.value) return;
    try {
      isIdeasLoading.value = true;
      ideasErrorMessage.value = null;
      final ideas = await repository.getPersonalizedMealIdeas(refresh: refresh);
      for (final meal in ideas) {
        meal.isFavorite = _favoriteMealIds.contains(meal.id);
      }
      personalizedIdeas.assignAll(ideas);
    } on Object catch (error) {
      ideasErrorMessage.value = error.toString();
    } finally {
      isIdeasLoading.value = false;
    }
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
    if (index < 0 || index >= meals.length) return;
    await toggleMealFavorite(meals[index]);
  }

  Future<void> toggleMealFavorite(MealModel meal) async {
    final previous = meal.isFavorite;
    _setFavoriteState(meal.id, favorite: !previous);
    try {
      await repository.setFavorite(meal.id, favorite: !previous);
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().setMealFavoriteState(
          meal.id,
          favorite: !previous,
        );
      }
    } on Object catch (error) {
      _setFavoriteState(meal.id, favorite: previous);
      AppAlert.error(title: 'Favorites unavailable', message: error.toString());
    }
  }

  void _setFavoriteState(int mealId, {required bool favorite}) {
    if (favorite) {
      _favoriteMealIds = {..._favoriteMealIds, mealId};
    } else {
      _favoriteMealIds = _favoriteMealIds.where((id) => id != mealId).toSet();
    }
    for (final item in meals) {
      if (item.id == mealId) item.isFavorite = favorite;
    }
    for (final item in personalizedIdeas) {
      if (item.id == mealId) item.isFavorite = favorite;
    }
    meals.refresh();
    personalizedIdeas.refresh();
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
    WidgetsBinding.instance.removeObserver(this);
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
