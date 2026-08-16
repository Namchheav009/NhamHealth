import '../models/food_nutrition_model.dart';
import '../models/food_recommendation_model.dart';

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
    if (food.calories > remaining) {
      return const FoodRecommendationModel(
        title: 'Consider a Smaller Portion',
        message:
            'This meal is higher than your remaining calorie target today.',
        type: FoodRecommendationType.warning,
      );
    }
    if (food.sugar >= 20) {
      return const FoodRecommendationModel(
        title: 'Watch Your Sugar',
        message:
            'This meal is relatively high in sugar. Consider a smaller portion or a lower-sugar drink.',
        type: FoodRecommendationType.warning,
      );
    }
    if (food.protein >= 25) {
      return const FoodRecommendationModel(
        title: 'Good Protein Source',
        message:
            'This meal fits your remaining calories and provides a useful amount of protein.',
        type: FoodRecommendationType.good,
      );
    }
    return const FoodRecommendationModel(
      title: 'Good Choice',
      message: 'This meal fits within your remaining calorie target today.',
      type: FoodRecommendationType.good,
    );
  }
}
