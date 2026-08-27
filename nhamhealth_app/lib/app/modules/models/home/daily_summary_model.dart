import 'nutrition_progress_model.dart';

class DailySummaryModel {
  final NutritionProgressModel calories;
  final NutritionProgressModel protein;
  final NutritionProgressModel fat;
  final NutritionProgressModel water;
  final NutritionProgressModel fiber;
  final NutritionProgressModel sugar;

  const DailySummaryModel({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.water,
    required this.fiber,
    required this.sugar,
  });
}
