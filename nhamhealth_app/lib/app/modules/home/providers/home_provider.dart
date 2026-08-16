import '../../profile/repositories/profile_repository.dart';
import '../models/daily_summary_model.dart';
import '../models/home_dashboard_model.dart';
import '../models/nutrition_progress_model.dart';
import '../models/recommended_meal_model.dart';

class HomeProvider {
  HomeProvider({ProfileRepository? profileRepository})
    : _profileRepository = profileRepository;

  final ProfileRepository? _profileRepository;

  Future<HomeDashboardModel> getHomeDashboard({DateTime? date}) async {
    final profile = await _profileRepository?.getDashboard(date: date);

    final calories = profile?.calories;
    final protein = profile?.protein;
    final water = profile?.water;
    final displayName = profile?.fullName?.trim();

    return HomeDashboardModel(
      userName: displayName?.isNotEmpty == true
          ? displayName!.split(RegExp(r'\s+')).first
          : profile?.email.split('@').first ?? 'Friend',
      dailySummary: DailySummaryModel(
        calories: NutritionProgressModel(
          title: 'Calories',
          value: _number(calories?.current ?? 0),
          target: _number(calories?.goal ?? 2000),
          progress: _progress(calories?.current, calories?.goal),
          unit: 'kcal',
        ),
        protein: NutritionProgressModel(
          title: 'Protein',
          value: _number(protein?.current ?? 0),
          target: _number(protein?.goal ?? 120),
          progress: _progress(protein?.current, protein?.goal),
          unit: 'g',
        ),
        water: NutritionProgressModel(
          title: 'Water',
          value: _number(water?.current ?? 0),
          target: _number(water?.goal ?? 8),
          progress: _progress(water?.current, water?.goal),
          unit: 'glasses',
        ),
      ),
      recommendedMeals: [
        RecommendedMealModel(
          id: 1,
          name: 'Grilled Chicken Power Bowl',
          image: 'assets/images/meals/healthy_salad.jpg',
          calories: 520,
          cookingTime: '15 min',
          rating: 4.8,
        ),
        RecommendedMealModel(
          id: 2,
          name: 'Grilled Chicken Power Bowl',
          image: 'assets/images/meals/healthy_salad.jpg',
          calories: 520,
          cookingTime: '20 min',
          rating: 4.8,
        ),
        RecommendedMealModel(
          id: 3,
          name: 'Grilled Chicken Power Bowl',
          image: 'assets/images/meals/healthy_salad.jpg',
          calories: 520,
          cookingTime: '10 min',
          rating: 4.8,
        ),
      ],
    );
  }

  static String _number(double value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);

  static double _progress(double? current, double? goal) {
    if (goal == null || goal <= 0) return 0;
    return ((current ?? 0) / goal).clamp(0.0, 1.0).toDouble();
  }
}
