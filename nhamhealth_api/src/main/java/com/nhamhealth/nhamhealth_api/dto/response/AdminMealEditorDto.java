package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;
import java.util.List;

public record AdminMealEditorDto(
        Integer mealId,
        String mealName,
        String mealNameKm,
        Integer categoryId,
        BigDecimal calories,
        Integer servings,
        String description,
        String descriptionKm,
        String difficulty,
        Integer cookingTimeMinutes,
        Integer prepTimeMinutes,
        Integer restingTimeMinutes,
        Integer totalTimeMinutes,
        Boolean isNutritionEstimated,
        boolean published,
        String mainImageUrl,
        List<AdminMealIngredientDto> ingredients,
        List<AdminMealNutritionDto> nutrition,
        List<AdminRecipeStepDto> recipeSteps) {

    public AdminMealEditorDto(
            Integer mealId, String mealName, String mealNameKm, Integer categoryId,
            BigDecimal calories, Integer servings, String description, String descriptionKm,
            String difficulty, Integer cookingTimeMinutes, boolean published, String mainImageUrl,
            List<AdminMealIngredientDto> ingredients, List<AdminMealNutritionDto> nutrition,
            List<AdminRecipeStepDto> recipeSteps) {
        this(mealId, mealName, mealNameKm, categoryId, calories, servings, description, descriptionKm,
                difficulty, cookingTimeMinutes, null, null, cookingTimeMinutes, false, published,
                mainImageUrl, ingredients, nutrition, recipeSteps);
    }
}
