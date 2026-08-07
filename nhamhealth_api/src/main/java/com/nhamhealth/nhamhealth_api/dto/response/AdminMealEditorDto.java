package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;
import java.util.List;

public record AdminMealEditorDto(
        Integer mealId,
        String mealName,
        Integer categoryId,
        BigDecimal calories,
        Integer servings,
        String description,
        String difficulty,
        Integer cookingTimeMinutes,
        boolean published,
        String mainImageUrl,
        List<AdminRecipeStepDto> recipeSteps) {
}
