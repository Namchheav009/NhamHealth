import 'nutrition_progress_model.dart';

class DailySummaryModel {
  final NutritionProgressModel calories;
  final NutritionProgressModel protein;
  final NutritionProgressModel water;

  const DailySummaryModel({
    required this.calories,
    required this.protein,
    required this.water,
  });
}