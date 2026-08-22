import 'daily_summary_model.dart';
import 'recommended_meal_model.dart';

class HomeDashboardModel {
  final String userName;
  final DailySummaryModel dailySummary;
  final List<RecommendedMealModel> recommendedMeals;

  const HomeDashboardModel({
    required this.userName,
    required this.dailySummary,
    required this.recommendedMeals,
  });
}
