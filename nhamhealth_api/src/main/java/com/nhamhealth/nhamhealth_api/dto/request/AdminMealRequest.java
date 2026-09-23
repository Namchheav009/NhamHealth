package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AdminMealRequest(
        @NotBlank @Size(max = 150) String mealName,
        @Size(max = 150) String mealNameKm,
        @NotNull Integer categoryId,
        @DecimalMin("0.0") BigDecimal calories,
        @NotNull @Min(1) @Max(100) Integer servings,
        @Size(max = 500) String description,
        @Size(max = 1000) String descriptionKm,
        @Size(max = 20) String difficulty,
        @Min(0) @Max(1440) Integer cookingTimeMinutes,
        @Min(0) @Max(1440) Integer prepTimeMinutes,
        @Min(0) @Max(1440) Integer restingTimeMinutes,
        @Min(0) @Max(1440) Integer totalTimeMinutes,
        Boolean isNutritionEstimated,
        boolean published,
        @NotBlank @Size(max = 255) String mainImageUrl,
        @NotNull @Size(min = 1) List<@Valid AdminMealIngredientRequest> ingredients,
        @NotNull List<@Valid AdminRecipeStepRequest> recipeSteps) {

    public AdminMealRequest(
            String mealName, String mealNameKm, Integer categoryId, BigDecimal calories,
            Integer servings, String description, String descriptionKm, String difficulty,
            Integer cookingTimeMinutes, boolean published, String mainImageUrl,
            List<AdminMealIngredientRequest> ingredients, List<AdminRecipeStepRequest> recipeSteps) {
        this(mealName, mealNameKm, categoryId, calories, servings, description, descriptionKm,
                difficulty, cookingTimeMinutes, null, null, cookingTimeMinutes, false, published,
                mainImageUrl, ingredients, recipeSteps);
    }
}
