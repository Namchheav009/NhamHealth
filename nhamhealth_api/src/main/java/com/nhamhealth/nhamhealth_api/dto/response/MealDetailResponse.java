package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;
import java.util.List;

import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.MealIngredient;
import com.nhamhealth.nhamhealth_api.entity.MealNutrition;
import com.nhamhealth.nhamhealth_api.entity.RecipeStep;

/** Complete published-meal content used by the mobile detail flow. */
public record MealDetailResponse(
        Integer id,
        String name,
        Integer categoryId,
        String category,
        String imageUrl,
        BigDecimal calories,
        String description,
        Integer cookingTimeMinutes,
        String difficulty,
        Integer servings,
        List<IngredientItem> ingredients,
        List<NutritionItem> nutrition,
        List<StepItem> steps) {

    public static MealDetailResponse from(
            Meal meal,
            List<MealIngredient> ingredients,
            List<MealNutrition> nutrition,
            List<RecipeStep> steps) {
        String categoryName = meal.getCategory() == null
                ? "Uncategorized"
                : meal.getCategory().getCategoryName();
        return new MealDetailResponse(
                meal.getMealId(), meal.getMealName(),
                meal.getCategory() == null ? null : meal.getCategory().getCategoryId(),
                categoryName, meal.getMainImageUrl(), meal.getCaloriesCached(),
                meal.getDescription(), meal.getCookingTimeMinutes(), meal.getDifficulty(), meal.getServings(),
                ingredients.stream().map(IngredientItem::from).toList(),
                nutrition.stream().map(NutritionItem::from).toList(),
                steps.stream().map(StepItem::from).toList());
    }

    public record IngredientItem(
            Integer id, String name, String description, String imageUrl,
            BigDecimal quantity, String unit, String preparationNote) {
        static IngredientItem from(MealIngredient item) {
            var ingredient = item.getIngredient();
            return new IngredientItem(
                    ingredient.getIngredientId(), ingredient.getIngredientName(), ingredient.getDescription(),
                    ingredient.getImageUrl(), item.getQuantity(), item.getUnit(), item.getPreparationNote());
        }
    }

    public record NutritionItem(String name, BigDecimal amount, String unit) {
        static NutritionItem from(MealNutrition item) {
            return new NutritionItem(item.getNutrient().getNutrientName(), item.getAmountPerServing(),
                    item.getNutrient().getUnit());
        }
    }

    public record StepItem(Integer number, String title, String instruction, String imageUrl) {
        static StepItem from(RecipeStep step) {
            return new StepItem(step.getStepNumber(), step.getStepTitle(), step.getInstruction(), step.getImageUrl());
        }
    }
}
