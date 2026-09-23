package com.nhamhealth.nhamhealth_api.dto.response;

import java.util.List;

public record AiIngredientReanalysisResponse(
        List<DetectedFoodComponent> ingredients,
        NutritionSummaryResponse nutrition) {

    public AiIngredientReanalysisResponse {
        ingredients = ingredients == null ? List.of() : List.copyOf(ingredients);
        nutrition = nutrition == null ? NutritionSummaryResponse.unavailable() : nutrition;
    }
}
