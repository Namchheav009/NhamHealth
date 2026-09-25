import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/current_user_service.dart';
import '../../../../core/services/notification_realtime_event.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_alert.dart';
import '../../../widgets/favorite_removal_confirmation.dart';
import '../../models/auth/authenticated_user_model.dart';
import '../../models/home/daily_summary_model.dart';
import '../../models/home/home_dashboard_model.dart';
import '../../models/home/home_route_arguments.dart';
import '../../models/home/mood_model.dart';
import '../../models/home/nutrition_progress_model.dart';
import '../../models/home/recommended_meal_model.dart';
import '../../models/meals/meal_model.dart';
import '../../repositories/home/home_repository.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../services/auth/google_auth_service.dart';
import '../planner/meal_planner_controller.dart';
import '../wellness/wellness_controller.dart';

class HomeController extends GetxController {
  HomeController({required this.repository, this.realtimeEvents});

  final HomeRepository repository;
  final Stream<NotificationRealtimeEvent>? realtimeEvents;
  final isLoading = false.obs;
  final Rxn<HomeDashboardModel> dashboard = Rxn<HomeDashboardModel>();
  final selectedMoodId = RxnInt();
  final moodValidationPulse = 0.obs;
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
  StreamSubscription<NotificationRealtimeEvent>? _notificationSubscription;
  Worker? _currentUserWorker;

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
    _bindCurrentUser();
    final initialDashboard = dashboard.value;
    if (initialDashboard != null) {
      _summariesByDay[_dayKey(DateTime.now())] = initialDashboard.dailySummary;
    }
    loadMoods();
    loadFavoriteMeals();
    loadUnreadNotificationCount();
    _notificationSubscription = realtimeEvents?.listen(
      (_) => unawaited(loadUnreadNotificationCount()),
    );
    _notificationCountTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(loadUnreadNotificationCount()),
    );
    // Refresh dashboard data only. Mood selection and AI recommendations are
    // intentionally user-triggered through Select Mood -> Suggest Meals.
    unawaited(loadDashboard());
  }

  Future<void> loadUnreadNotificationCount() async {
    try {
      unreadNotificationCount.value =
          await repository.getUnreadNotificationCount();
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
        title: wasFavorite ? 'home.favorite_removed' : 'home.favorite_saved',
        message:
            wasFavorite
                ? 'home.meal_removed_from_favorites'
                : 'home.meal_saved_to_favorites',
      );
    } on Object catch (error) {
      setMealFavoriteState(mealId, favorite: wasFavorite);
      AppAlert.error(
        title: 'common.favorites_unavailable',
        message: error.toString(),
      );
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
    final user = await Get.find<AuthService>().restoreSession();
    authenticatedUser.value = user;
    if (Get.isRegistered<CurrentUserService>()) {
      Get.find<CurrentUserService>().setUser(user);
    }
  }

  void _bindCurrentUser() {
    if (!Get.isRegistered<CurrentUserService>()) return;
    final currentUser = Get.find<CurrentUserService>();
    authenticatedUser.value = currentUser.user.value ?? authenticatedUser.value;
    _currentUserWorker = ever<AuthenticatedUser?>(
      currentUser.user,
      (user) => authenticatedUser.value = user,
    );
  }

  Future<void> loadDashboard() async {
    try {
      isLoading.value = true;
      final requestedDate = DateTime(
        selectedDay.value.year,
        selectedDay.value.month,
        selectedDay.value.day,
      );
      final displayedRecommendations =
          dashboard.value?.recommendedMeals ?? const [];
      final refreshedDashboard = await repository.getHomeDashboard(
        date: requestedDate,
      );
      // Dashboard refreshes update wellness data, but must not erase meals the
      // user explicitly requested during this Home session.
      dashboard.value = HomeDashboardModel(
        userName: refreshedDashboard.userName,
        dailySummary: refreshedDashboard.dailySummary,
        recommendedMeals: displayedRecommendations,
      );
      final value = dashboard.value;
      if (value != null) {
        _summariesByDay[_dayKey(requestedDate)] = value.dailySummary;
        _showSelectedDay();
      }
    } catch (_) {
      AppAlert.error(
        title: 'home.home_unavailable',
        message: 'home.unable_to_load_home_data',
      );
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
    } catch (_) {
      _summariesByDay[key] = _emptySummary;
    } finally {
      _showSelectedDay();
      isLoading.value = false;
    }
  }

  void addNutritionToToday({
    required int calories,
    required double protein,
    double fat = 0,
    double water = 0,
    double fiber = 0,
    double sugar = 0,
    DateTime? date,
  }) {
    final targetDate = date ?? selectedDay.value;
    final key = _dayKey(targetDate);
    final current = _summariesByDay[key] ?? _emptySummary;
    _summariesByDay[key] = DailySummaryModel(
      calories: _increment(current.calories, calories.toDouble()),
      protein: _increment(current.protein, protein),
      fat: _increment(current.fat, fat),
      water: _increment(current.water, water),
      fiber: _increment(current.fiber, fiber),
      sugar: _increment(current.sugar, sugar),
    );
    if (_dayKey(selectedDay.value) == key) _showSelectedDay();
  }

  final isQuickLoggingWater = false.obs;

  Future<void> quickLogWater([double glasses = 1.0]) async {
    if (isQuickLoggingWater.value) return;
    isQuickLoggingWater.value = true;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
    addNutritionToToday(
      calories: 0,
      protein: 0,
      water: glasses,
      date: selectedDay.value,
    );
    try {
      final auth =
          Get.isRegistered<AuthService>()
              ? Get.find<AuthService>()
              : AuthService();
      final profileRepo =
          Get.isRegistered<ProfileRepository>()
              ? Get.find<ProfileRepository>()
              : ProfileRepository(authService: auth);
      await profileRepo.addDailyNutrition(
        water: glasses,
        date: selectedDay.value,
      );
      if (Get.isRegistered<WellnessController>()) {
        final wellness = Get.find<WellnessController>();
        if (_sameDay(wellness.selectedDate.value, selectedDay.value)) {
          unawaited(wellness.loadDailyWellness());
        }
      }
      if (Get.isRegistered<MealPlannerController>()) {
        final planner = Get.find<MealPlannerController>();
        unawaited(planner.loadDailyNutrition(selectedDay.value));
      }
      AppAlert.success(
        title: 'wellness.water_added_today',
        message: 'wellness.water_count_added_one'.trParams({
          'count': '${glasses.round()}',
        }),
      );
    } catch (_) {
      // Local state is already updated optimistically
    } finally {
      isQuickLoggingWater.value = false;
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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
      title: 'common.calories',
      value: '0',
      target: '2000',
      progress: 0,
      unit: 'kcal',
    ),
    protein: NutritionProgressModel(
      title: 'common.protein',
      value: '0',
      target: '120',
      progress: 0,
      unit: 'g',
    ),
    fat: NutritionProgressModel(
      title: 'common.fat',
      value: '0',
      target: '78',
      progress: 0,
      unit: 'g',
    ),
    water: NutritionProgressModel(
      title: 'common.water',
      value: '0',
      target: '8',
      progress: 0,
      unit: 'glasses',
    ),
    fiber: NutritionProgressModel(
      title: 'common.fiber',
      value: '0',
      target: '25',
      progress: 0,
      unit: 'g',
    ),
    sugar: NutritionProgressModel(
      title: 'common.sugar',
      value: '0',
      target: '50',
      progress: 0,
      unit: 'g',
    ),
  );

  void selectMood(int moodId) {
    selectedMoodId.value = moodId;
    moodValidationPulse.value = 0;
    _clearRecommendationForMoodChange();
  }

  void _clearRecommendationForMoodChange() {
    final current = dashboard.value;
    if (current == null || current.recommendedMeals.isEmpty) return;
    dashboard.value = HomeDashboardModel(
      userName: current.userName,
      dailySummary: current.dailySummary,
      recommendedMeals: const [],
    );
  }

  void selectBottomMenu(int index) {
    if (index == selectedBottomIndex.value) return;
    selectedBottomIndex.value = index;

    switch (index) {
      case 0:
        break;
      case 1:
        Get.offNamed<void>(AppRoutes.meals);
        break;
      case 2:
        Get.offNamed<void>(AppRoutes.mealPlanner);
        break;
      case 3:
        Get.offNamed<void>(AppRoutes.community);
        break;
    }
  }

  void openMeals({String? query}) {
    final normalizedQuery = query?.replaceAll('\n', ' ').trim() ?? '';
    Get.toNamed<void>(
      AppRoutes.meals,
      arguments: normalizedQuery.isEmpty ? null : {'query': normalizedQuery},
    );
  }

  void openRecommendedMeal(RecommendedMealModel meal) {
    Get.toNamed<void>(
      AppRoutes.foodDetail,
      arguments: MealModel(
        id: meal.id,
        name: meal.name,
        calories: meal.calories,
        image: meal.image,
        category: '',
        categoryId: 0,
        proteinGrams: meal.proteinGrams,
        recommendationReason: meal.reason,
        isFavorite: favoriteMealIds.contains(meal.id),
      ),
    );
  }

  Future<void> openNotifications() async {
    await Get.toNamed<void>(AppRoutes.notifications);
    await loadUnreadNotificationCount();
  }

  void openFavorites() {
    Get.toNamed<void>(AppRoutes.favorites);
  }

  void openProfile() {
    Get.toNamed<void>(AppRoutes.profile, arguments: authenticatedUser.value);
  }

  void openSettings() {
    Get.offNamed<void>(AppRoutes.settings);
  }

  Future<void> openWellnessDetails() async {
    await Get.toNamed<void>(AppRoutes.wellness, arguments: selectedDay.value);
    await loadDashboard();
  }

  void openWaterDetails() =>
      Get.toNamed<void>(AppRoutes.water, arguments: selectedDay.value);

  bool _isNavigatingMealPlanner = false;
  Future<void> openMealPlanner() async {
    if (_isNavigatingMealPlanner) return;
    _isNavigatingMealPlanner = true;
    try {
      await Get.toNamed<void>(AppRoutes.mealPlanner);
      await loadDashboard();
    } finally {
      _isNavigatingMealPlanner = false;
    }
  }

  void openFoodAnalyzer() {
    Get.toNamed<void>(AppRoutes.aiFood);
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
      AppAlert.error(
        title: 'home.logout_failed',
        message: 'home.logout_failed_help',
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  Future<void> getRecommendation() async {
    if (isRecommendedMealsLoading.value) return;
    final moodId = selectedMoodId.value;
    if (moodId == null) {
      moodValidationPulse.value++;
      return;
    }
    // The generate endpoint is idempotent when refresh=false: it returns today's
    // existing recommendation or creates one. Keeping this to one request avoids
    // a GET-then-POST race and leaves enough time for the server-side fallback.
    await loadRecommendedMeals(moodId: moodId, generate: true);
  }

  Future<void> refreshMeals() async {
    await Future.wait([loadDashboard(), loadMoods()]);
  }

  Future<void> loadRecommendedMeals({
    int? moodId,
    bool generate = false,
    bool refresh = false,
    bool generateIfEmpty = false,
  }) async {
    try {
      isRecommendedMealsLoading.value = true;
      var meals =
          generate && moodId != null
              ? await repository.generateRecommendedMeals(
                moodId: moodId,
                refresh: refresh,
              )
              : await repository.getRecommendedMeals(moodId: moodId);

      // Retained for callers that explicitly want a read-first workflow.
      if (meals.isEmpty && generateIfEmpty && moodId != null) {
        meals = await repository.generateRecommendedMeals(moodId: moodId);
      }
      final current = dashboard.value;
      if (current != null) {
        dashboard.value = HomeDashboardModel(
          userName: current.userName,
          dailySummary: current.dailySummary,
          recommendedMeals: meals,
        );
      }
    } on Object {
      AppAlert.error(
        title: 'home.recommendations_unavailable',
        message: 'home.could_not_generate_meals_right_now_please_try_again',
      );
    } finally {
      isRecommendedMealsLoading.value = false;
    }
  }

  @override
  void onClose() {
    _notificationCountTimer?.cancel();
    _notificationSubscription?.cancel();
    _currentUserWorker?.dispose();
    super.onClose();
  }
}
