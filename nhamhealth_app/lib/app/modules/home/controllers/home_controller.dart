import 'dart:async';

import 'package:get/get.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/favorite_removal_confirmation.dart';

import '../../../../core/services/auth_service.dart';
import '../../auth/models/authenticated_user_model.dart';
import '../../auth/services/google_auth_service.dart';
import '../../../routes/app_routes.dart';
import '../models/home_dashboard_model.dart';
import '../models/home_route_arguments.dart';
import '../models/daily_summary_model.dart';
import '../models/nutrition_progress_model.dart';
import '../models/mood_model.dart';
import '../repositories/home_repository.dart';
import '../../profile/controllers/setting_controller.dart';
import '../../profile/views/setting_view.dart';

class HomeController extends GetxController {
  HomeController({required this.repository});

  final HomeRepository repository;
  final isLoading = false.obs;
  final Rxn<HomeDashboardModel> dashboard = Rxn<HomeDashboardModel>();
  final selectedMoodId = RxnInt();
  final selectedBottomIndex = 0.obs;
  final selectedDay = DateTime.now().obs;
  final isLoggingOut = false.obs;
  final Rxn<AuthenticatedUser> authenticatedUser = Rxn<AuthenticatedUser>();
  final Map<String, DailySummaryModel> _summariesByDay = {};

  List<DateTime> get recentDays => List.generate(
    7,
    (index) => DateTime.now().subtract(Duration(days: 6 - index)),
  );

  final moods = <MoodModel>[].obs;
  final isMoodsLoading = false.obs;
  final isRecommendedMealsLoading = false.obs;
  final favoriteMealIds = <int>{}.obs;
  final unreadNotificationCount = 0.obs;
  Timer? _notificationCountTimer;

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
    final initialDashboard = dashboard.value;
    if (initialDashboard != null) {
      _summariesByDay[_dayKey(DateTime.now())] = initialDashboard.dailySummary;
    }
    loadMoods();
    loadFavoriteMeals();
    loadUnreadNotificationCount();
    _notificationCountTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => loadUnreadNotificationCount(),
    );
    if (dashboard.value == null) {
      loadDashboard();
    } else {
      _clearRecommendedMeals();
    }
  }

  Future<void> loadUnreadNotificationCount() async {
    try {
      unreadNotificationCount.value = await repository.getUnreadNotificationCount();
    } on Object {
      // Keep the last known badge count while the API is temporarily unavailable.
    }
  }

  Future<void> loadFavoriteMeals() async {
    try {
      favoriteMealIds.assignAll(await repository.getFavoriteMealIds());
    } on Object {
      // Favorites remain usable after the next successful refresh.
    }
  }

  Future<void> toggleMealFavorite(int mealId) async {
    final wasFavorite = favoriteMealIds.contains(mealId);
    if (wasFavorite && !await confirmFavoriteRemoval()) return;

    setMealFavoriteState(mealId, favorite: !wasFavorite);
    try {
      await repository.setMealFavorite(mealId, favorite: !wasFavorite);
      AppAlert.success(
        title: wasFavorite ? 'Favorite removed' : 'Favorite saved',
        message:
            wasFavorite
                ? 'This meal was removed from your Favorites page.'
                : 'This meal is now available on your Favorites page.',
      );
    } on Object catch (error) {
      setMealFavoriteState(mealId, favorite: wasFavorite);
      AppAlert.error(title: 'Favorites unavailable', message: error.toString());
    }
  }

  /// Keeps the home meal cards in sync when favorites are changed elsewhere.
  void setMealFavoriteState(int mealId, {required bool favorite}) {
    if (favorite) {
      favoriteMealIds.add(mealId);
    } else {
      favoriteMealIds.remove(mealId);
    }
    favoriteMealIds.refresh();
  }

  Future<void> loadMoods() async {
    try {
      isMoodsLoading.value = true;
      final result = await repository.getMoods();
      moods.assignAll(result);
      if (!result.any((mood) => mood.id == selectedMoodId.value)) {
        selectedMoodId.value = null;
      }
    } on Object {
      // Mood selection is supplementary to the dashboard. Leave the card empty
      // rather than displaying stale values after an admin update or deletion.
      moods.clear();
      selectedMoodId.value = null;
    } finally {
      isMoodsLoading.value = false;
    }
  }

  Future<void> _restoreAuthenticatedUser() async {
    authenticatedUser.value = await Get.find<AuthService>().restoreSession();
  }

  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      dashboard.value = await repository.getHomeDashboard();
      final value = dashboard.value;
      if (value != null) {
        _summariesByDay.putIfAbsent(
          _dayKey(DateTime.now()),
          () => value.dailySummary,
        );
        _showSelectedDay();
      }
    } catch (_) {
      AppAlert.error(title: 'Home unavailable', message: 'Unable to load home data.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectDay(DateTime date) async {
    selectedDay.value = DateTime(date.year, date.month, date.day);
    final key = _dayKey(date);
    if (_summariesByDay.containsKey(key)) {
      _showSelectedDay();
      return;
    }
    try {
      isLoading.value = true;
      final result = await repository.getHomeDashboard(date: date);
      _summariesByDay[key] = result.dailySummary;
      _showSelectedDay();
    } finally {
      isLoading.value = false;
    }
  }

  void addNutritionToToday({required int calories, required double protein}) {
    final today = DateTime.now();
    final key = _dayKey(today);
    final current = _summariesByDay[key] ?? _emptySummary;
    _summariesByDay[key] = DailySummaryModel(
      calories: _increment(current.calories, calories.toDouble()),
      protein: _increment(current.protein, protein),
      water: current.water,
    );
    if (_dayKey(selectedDay.value) == key) _showSelectedDay();
  }

  void _showSelectedDay() {
    final currentDashboard = dashboard.value;
    if (currentDashboard == null) return;
    dashboard.value = HomeDashboardModel(
      userName: currentDashboard.userName,
      dailySummary:
          _summariesByDay[_dayKey(selectedDay.value)] ?? _emptySummary,
      recommendedMeals: currentDashboard.recommendedMeals,
    );
  }

  NutritionProgressModel _increment(
    NutritionProgressModel item,
    double amount,
  ) {
    final value = (double.tryParse(item.value) ?? 0) + amount;
    final target = double.tryParse(item.target) ?? 1;
    return NutritionProgressModel(
      title: item.title,
      value:
          value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1),
      target: item.target,
      progress: (value / target).clamp(0.0, 1.0).toDouble(),
      unit: item.unit,
    );
  }

  String _dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  static const _emptySummary = DailySummaryModel(
    calories: NutritionProgressModel(
      title: 'Calories',
      value: '0',
      target: '2000',
      progress: 0,
      unit: 'kcal',
    ),
    protein: NutritionProgressModel(
      title: 'Protein',
      value: '0',
      target: '120',
      progress: 0,
      unit: 'g',
    ),
    water: NutritionProgressModel(
      title: 'Water',
      value: '0',
      target: '8',
      progress: 0,
      unit: 'glasses',
    ),
  );

  void selectMood(int moodId) {
    selectedMoodId.value = moodId;
    _clearRecommendedMeals();
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
        Get.offNamed<void>(
          AppRoutes.profile,
          arguments: authenticatedUser.value,
        );
        break;
    }
  }

  Future<void> openNotifications() async {
    await Get.toNamed<void>(AppRoutes.notifications);
    await loadUnreadNotificationCount();
  }

  void openFavorites() {
    Get.toNamed<void>(AppRoutes.favorites);
  }

  void openProfile() {
    selectBottomMenu(4);
  }

  void openSettings() {
    Get.to<void>(
      () => const SettingsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<SettingsController>(() => SettingsController());
      }),
    );
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
      AppAlert.error(title: 'Logout failed', message: 'Unable to clear your session. Please try again.');
    } finally {
      isLoggingOut.value = false;
    }
  }

  Future<void> getRecommendation() async {
    final moodId = selectedMoodId.value;
    if (moodId == null) {
      AppAlert.error(title: 'Choose your mood', message: 'Select how you are feeling so AI can recommend suitable meals.');
      return;
    }
    await loadRecommendedMeals(
      moodId: moodId,
      generate: true,
      refresh: true,
    );
  }

  Future<void> refreshMeals() async {
    await Future.wait([loadDashboard(), loadMoods()]);
  }

  void _clearRecommendedMeals() {
    final current = dashboard.value;
    if (current == null || current.recommendedMeals.isEmpty) return;
    dashboard.value = HomeDashboardModel(
      userName: current.userName,
      dailySummary: current.dailySummary,
      recommendedMeals: const [],
    );
  }

  Future<void> loadRecommendedMeals({
    int? moodId,
    bool generate = false,
    bool refresh = false,
  }) async {
    try {
      isRecommendedMealsLoading.value = true;
      final meals =
          generate && moodId != null
              ? await repository.generateRecommendedMeals(
                moodId: moodId,
                refresh: refresh,
              )
              : await repository.getRecommendedMeals(moodId: moodId);
      final current = dashboard.value;
      if (current != null) {
        dashboard.value = HomeDashboardModel(
          userName: current.userName,
          dailySummary: current.dailySummary,
          recommendedMeals: meals,
        );
      }
    } on Object {
      // Keep the recommendation card in place without covering the bottom of
      // the home screen with a transient AI Recommendation alert.
    } finally {
      isRecommendedMealsLoading.value = false;
    }
  }

  @override
  void onClose() {
    _notificationCountTimer?.cancel();
    super.onClose();
  }
}
