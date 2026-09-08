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
        title: 'wellness.confirm_food_first',
        message:
            'wellness.the_result_is_uncertain_confirm_the_food_or_retake_a_clear_well_lit_photo_before_saving',
        type: FoodRecommendationType.warning,
      );
    }
    if (remaining == 0 || food.calories > remaining * 1.1) {
      return FoodRecommendationModel(
        title: 'wellness.consider_a_smaller_portion',
        message:
            'wellness.about_calories_kcal_exceeds_your_remaining_remaining_kcal_target_reduce_the_portion_or_save_it_for_tomorrow',
        messageParams: {
          'calories': food.calories.round().toString(),
          'remaining': remaining.toString(),
        },
        type: FoodRecommendationType.warning,
      );
    }

    final sugarDensity = food.calories <= 0 ? 0 : food.sugar / food.calories;
    if (food.sugar >= 20 || sugarDensity >= .06) {
      return FoodRecommendationModel(
        title: 'wellness.balance_the_sugar',
        message:
            'wellness.estimated_sugar_is_sugar_g_pair_it_with_protein_or_fiber_and_choose_an_unsweetened_drink',
        messageParams: {'sugar': food.sugar.toStringAsFixed(0)},
        type: FoodRecommendationType.warning,
      );
    }
    if (food.fat >= 30 && food.protein < 20) {
      return const FoodRecommendationModel(
        title: 'wellness.add_a_leaner_balance',
        message:
            'wellness.this_looks_fat_heavy_for_its_protein_a_smaller_portion_with_vegetables_or_lean_protein_would_improve_balance',
        type: FoodRecommendationType.warning,
      );
    }
    if (food.protein >= 25) {
      return FoodRecommendationModel(
        title: 'wellness.strong_protein_choice',
        message:
            'wellness.provides_about_protein_g_protein_and_fits_your_remaining_calories_add_vegetables_for_fiber',
        messageParams: {'protein': food.protein.toStringAsFixed(0)},
        type: FoodRecommendationType.good,
      );
    }
    return FoodRecommendationModel(
      title: 'wellness.fits_todays_plan',
      message:
          'wellness.about_calories_kcal_fits_your_target_keep_the_portion_near_servingsize_servingunit',
      messageParams: {
        'calories': food.calories.round().toString(),
        'servingSize': food.servingSize.toStringAsFixed(0),
        'servingUnit': food.servingUnit,
      },
      type: FoodRecommendationType.good,
    );
  }
}
