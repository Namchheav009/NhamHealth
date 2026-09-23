package com.nhamhealth.nhamhealth_api.dto.response;

import java.util.List;

public record IngredientAnalysisResponse(
        String mealName,
        int totalIngredients,
        int databaseMatchedCount,
        double totalCalories,
        double totalProtein,
        double totalCarbs,
        double totalFat,
        double totalFiber,
        double totalSodium,
        List<IngredientMatchDetail> ingredients,
        AiHealthInsights aiAnalysis,
        String disclaimer
) {
    public record IngredientMatchDetail(
            String originalText,
            boolean matched,
            String matchedFoodName,
            String imageUrl,
            double calories,
            double protein,
            double carbs,
            double fat,
            String portion,
            double matchConfidence
    ) {}

    public record AiHealthInsights(
            String healthRating,
            int healthScore,
            String headline,
            String summary,
            List<String> healthBenefits,
            List<String> warningsAndAllergens,
            List<String> smartTips,
            List<String> dietarySuitability,
            String modelUsed
    ) {}
}
