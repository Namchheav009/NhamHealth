package com.nhamhealth.nhamhealth_api.dto.response;

public record NutritionSummaryResponse(
        double calories,
        double protein,
        double carbohydrates,
        double fat,
        double sugar,
        double fiber,
        double sodium,
        NutritionSource source,
        boolean complete) {

    public static NutritionSummaryResponse unavailable() {
        return new NutritionSummaryResponse(
                0, 0, 0, 0, 0, 0, 0, NutritionSource.UNAVAILABLE, false);
    }
}
