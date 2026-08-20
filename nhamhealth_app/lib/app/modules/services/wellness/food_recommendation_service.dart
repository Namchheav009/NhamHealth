import '../../models/wellness/food_nutrition_model.dart';
import '../../models/wellness/food_recommendation_model.dart';

class FoodRecommendationService {
  FoodRecommendationModel create({
    required FoodNutritionModel food,
    required int currentCalories,
    required int targetCalories,
  }) {
    final remaining = (targetCalories - currentCalories).clamp(
      0,
      targetCalories,
    );
    if (food.needsUserConfirmation || food.confidence < .65) {
      return const FoodRecommendationModel(
        title: 'Confirm the Food First',
        message:
            'The result is uncertain. Confirm the food or retake a clear, well-lit photo before saving.',
        type: FoodRecommendationType.warning,
      );
    }
    if (remaining == 0 || food.calories > remaining * 1.1) {
      return FoodRecommendationModel(
        title: 'Consider a Smaller Portion',
        message:
            'About ${food.calories.round()} kcal exceeds your remaining $remaining kcal target. Reduce the portion or save it for tomorrow.',
        type: FoodRecommendationType.warning,
      );
    }

    final sugarDensity = food.calories <= 0 ? 0 : food.sugar / food.calories;
    if (food.sugar >= 20 || sugarDensity >= .06) {
      return FoodRecommendationModel(
        title: 'Balance the Sugar',
        message:
            'Estimated sugar is ${food.sugar.toStringAsFixed(0)} g. Pair it with protein or fiber and choose an unsweetened drink.',
        type: FoodRecommendationType.warning,
      );
    }
    if (food.fat >= 30 && food.protein < 20) {
      return const FoodRecommendationModel(
        title: 'Add a Leaner Balance',
        message:
            'This looks fat-heavy for its protein. A smaller portion with vegetables or lean protein would improve balance.',
        type: FoodRecommendationType.warning,
      );
    }
    if (food.protein >= 25) {
      return FoodRecommendationModel(
        title: 'Strong Protein Choice',
        message:
            'Provides about ${food.protein.toStringAsFixed(0)} g protein and fits your remaining calories. Add vegetables for fiber.',
        type: FoodRecommendationType.good,
      );
    }
    return FoodRecommendationModel(
      title: 'Fits Today’s Plan',
      message:
          'About ${food.calories.round()} kcal fits your target. Keep the portion near ${food.servingSize.toStringAsFixed(0)} ${food.servingUnit}.',
      type: FoodRecommendationType.good,
    );
  }
}
