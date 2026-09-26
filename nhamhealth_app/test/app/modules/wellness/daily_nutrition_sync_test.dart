import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/home/home_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/planner/meal_planner_controller.dart';
import 'package:nhamhealth_flutter/app/modules/controllers/wellness/wellness_controller.dart';
import 'package:nhamhealth_flutter/app/modules/models/home/daily_summary_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/home/home_dashboard_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/home/nutrition_progress_model.dart';
import 'package:nhamhealth_flutter/app/modules/models/planner/meal_plan.dart';
import 'package:nhamhealth_flutter/app/modules/models/profile/profile_dashboard_model.dart';
import 'package:nhamhealth_flutter/app/modules/providers/home/home_provider.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/home/home_repository.dart';
import 'package:nhamhealth_flutter/app/modules/repositories/profile/profile_repository.dart';
import 'package:nhamhealth_flutter/core/services/auth_service.dart';

class _FakeHomeRepository extends HomeRepository {
  _FakeHomeRepository() : super(provider: HomeProvider());

  @override
  Future<HomeDashboardModel> getHomeDashboard({DateTime? date}) async {
    return HomeDashboardModel(
      userName: 'Test',
      dailySummary: const DailySummaryModel(
        calories: NutritionProgressModel(
          title: 'common.calories',
          value: '500',
          target: '2000',
          progress: 0.25,
          unit: 'kcal',
        ),
        protein: NutritionProgressModel(
          title: 'common.protein',
          value: '30',
          target: '120',
          progress: 0.25,
          unit: 'g',
        ),
        fat: NutritionProgressModel(
          title: 'common.fat',
          value: '20',
          target: '78',
          progress: 0.25,
          unit: 'g',
        ),
        water: NutritionProgressModel(
          title: 'common.water',
          value: '2',
          target: '8',
          progress: 0.25,
          unit: 'glasses',
        ),
        fiber: NutritionProgressModel(
          title: 'common.fiber',
          value: '5',
          target: '25',
          progress: 0.2,
          unit: 'g',
        ),
        sugar: NutritionProgressModel(
          title: 'common.sugar',
          value: '10',
          target: '50',
          progress: 0.2,
          unit: 'g',
        ),
      ),
      recommendedMeals: const [],
    );
  }
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository() : super(authService: AuthService());

  @override
  Future<ProfileDashboardModel> getDashboard({DateTime? date}) async {
    return const ProfileDashboardModel(
      userId: 1,
      email: 'test@example.com',
      calories: ProfileProgressModel(current: 500, goal: 2000),
      protein: ProfileProgressModel(current: 30, goal: 120),
      carbs: ProfileProgressModel(current: 60, goal: 205),
      fat: ProfileProgressModel(current: 20, goal: 78),
      water: ProfileProgressModel(current: 2, goal: 8),
    );
  }

  @override
  Future<ProfileDashboardModel> addDailyNutrition({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? water,
    double? fiber,
    double? sugar,
    DateTime? date,
    String? aiRecommendation,
  }) async {
    return ProfileDashboardModel(
      userId: 1,
      email: 'test@example.com',
      calories: ProfileProgressModel(
        current: 500 + (calories ?? 0),
        goal: 2000,
      ),
      protein: ProfileProgressModel(
        current: 30 + (protein ?? 0),
        goal: 120,
      ),
      carbs: ProfileProgressModel(
        current: 60 + (carbs ?? 0),
        goal: 205,
      ),
      fat: ProfileProgressModel(
        current: 20 + (fat ?? 0),
        goal: 78,
      ),
      water: ProfileProgressModel(
        current: 2 + (water ?? 0),
        goal: 8,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  test('Home, Wellness, and MealPlanner synchronize nutrition data seamlessly', () async {
    final today = DateTime.now();
    final profileRepo = _FakeProfileRepository();
    final homeRepo = _FakeHomeRepository();

    final homeController = Get.put(
      HomeController(repository: homeRepo),
    );
    final wellnessController = Get.put(
      WellnessController(profileRepository: profileRepo),
    );
    final plannerController = Get.put(
      MealPlannerController(profileRepository: profileRepo),
    );

    // Initial server dashboard applied to all three
    const initialDashboard = ProfileDashboardModel(
      userId: 1,
      email: 'test@example.com',
      calories: ProfileProgressModel(current: 500, goal: 2000),
      protein: ProfileProgressModel(current: 30, goal: 120),
      carbs: ProfileProgressModel(current: 60, goal: 205),
      fat: ProfileProgressModel(current: 20, goal: 78),
      water: ProfileProgressModel(current: 2, goal: 8),
    );

    wellnessController.showSavedNutrition(initialDashboard, date: today);
    homeController.showSavedNutrition(initialDashboard, date: today);
    plannerController.showSavedNutrition(initialDashboard, date: today);

    // Verify initial values in all three controllers
    expect(homeController.dashboard.value!.dailySummary.calories.value, '500');
    expect(homeController.dashboard.value!.dailySummary.protein.value, '30');
    expect(homeController.dashboard.value!.dailySummary.water.value, '2');

    expect(
      wellnessController.nutrients.firstWhere((n) => n.name == 'Calories').current,
      '500',
    );
    expect(
      wellnessController.nutrients.firstWhere((n) => n.name == 'Protein').current,
      '30',
    );
    expect(
      wellnessController.nutrients.firstWhere((n) => n.name == 'Water').current,
      '2',
    );

    expect(plannerController.totalCalories, 500);
    expect(plannerController.totalProtein, 30);
    expect(plannerController.dailyWaterGlasses.value, 2);

    // 1. User marks a meal as eaten in Planner (400 kcal, 25g protein, 50g carbs, 10g fat)
    const meal = PlannedMeal(
      id: 101,
      name: 'Khmer Chicken Rice',
      slot: MealPlanSlot.lunch,
      calories: 400,
      proteinGrams: 25,
      carbsGrams: 50,
      fatGrams: 10,
      servings: 1,
      status: MealPlanStatus.planned,
      ingredients: const [],
    );

    // Trigger status change in planner
    await plannerController.changeStatus(meal, MealPlanStatus.eaten);

    // Check optimistic updates across all three controllers:
    // Calories: 500 + 400 = 900
    // Protein: 30 + 25 = 55
    // Carbs: 60 + 50 = 110
    // Fat: 20 + 10 = 30
    expect(plannerController.totalCalories, 900);
    expect(plannerController.totalProtein, 55);
    expect(plannerController.totalCarbs, 110);
    expect(plannerController.totalFat, 30);

    expect(
      wellnessController.nutrients.firstWhere((n) => n.name == 'Calories').current,
      '900',
    );
    expect(
      wellnessController.nutrients.firstWhere((n) => n.name == 'Protein').current,
      '55',
    );

    expect(homeController.dashboard.value!.dailySummary.calories.value, '900');
    expect(homeController.dashboard.value!.dailySummary.protein.value, '55');

    // 2. User unmarks the meal (switches back to planned)
    final eatenMeal = meal.copyWith(status: MealPlanStatus.eaten);
    await plannerController.changeStatus(eatenMeal, MealPlanStatus.planned);

    // Should rollback across all three controllers back to 500 kcal, 30g protein
    expect(plannerController.totalCalories, 500);
    expect(plannerController.totalProtein, 30);

    expect(
      wellnessController.nutrients.firstWhere((n) => n.name == 'Calories').current,
      '500',
    );
    expect(
      wellnessController.nutrients.firstWhere((n) => n.name == 'Protein').current,
      '30',
    );

    expect(homeController.dashboard.value!.dailySummary.calories.value, '500');
    expect(homeController.dashboard.value!.dailySummary.protein.value, '30');

    // 3. User logs 1 glass of water from Planner
    await plannerController.incrementWater();

    expect(plannerController.dailyWaterGlasses.value, 3);
    expect(
      wellnessController.nutrients.firstWhere((n) => n.name == 'Water').current,
      '3',
    );
    expect(homeController.dashboard.value!.dailySummary.water.value, '3');
  });
}
