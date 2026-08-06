import '../models/daily_summary_model.dart';
import '../models/home_dashboard_model.dart';
import '../models/nutrition_progress_model.dart';
import '../models/recommended_meal_model.dart';

class HomeProvider {
  Future<HomeDashboardModel> getHomeDashboard() async {
    await Future.delayed(const Duration(milliseconds: 500));

    return const HomeDashboardModel(
      userName: 'Sokchen',
      dailySummary: DailySummaryModel(
        calories: NutritionProgressModel(
          title: 'Calories',
          value: '1420',
          target: '2000',
          progress: 0.71,
          unit: 'kcal',
        ),
        protein: NutritionProgressModel(
          title: 'Protein',
          value: '82',
          target: '120',
          progress: 0.68,
          unit: 'g',
        ),
        water: NutritionProgressModel(
          title: 'Water',
          value: '6',
          target: '8',
          progress: 0.75,
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
}
