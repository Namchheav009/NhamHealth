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
        boolean published,
        String mainImageUrl,
        List<AdminMealIngredientDto> ingredients,
        List<AdminMealNutritionDto> nutrition,
        List<AdminRecipeStepDto> recipeSteps) {
}
