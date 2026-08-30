package com.nhamhealth.nhamhealth_api.dto.response;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodCandidate;

@JsonIgnoreProperties(ignoreUnknown = true)
public record AiFoodAnalysisResponse(
        Integer analysisId,
        String name,
        String analysis,
        double confidence,
        double calories,
        double protein,
        double carbs,
        double fat,
        double sugar,
        double servingSize,
        String servingUnit,
        String recommendationTitle,
        String recommendation,
        boolean databaseMatched,
        double databaseMatchConfidence,
        boolean needsUserConfirmation,
        String dataSource,
        String disclaimer,
        String privacyNotice,
        boolean foodDetected,
        String reason,
        String mealName,
        String cuisine,
        String type,
        boolean requiresDrinkDetails,
        double mealIdentityConfidence,
        double portionConfidence,
        double preparationConfidence,
        List<DetectedFoodComponent> components,
        List<FoodCandidate> candidates,
        NutritionSummaryResponse nutrition) {

    /** Keeps existing callers source-compatible while the API gains structured fields. */
    public AiFoodAnalysisResponse(
            Integer analysisId,
            String name,
            String analysis,
            double confidence,
            double calories,
            double protein,
            double carbs,
            double fat,
            double sugar,
            double servingSize,
            String servingUnit,
            String recommendationTitle,
            String recommendation,
            boolean databaseMatched,
            double databaseMatchConfidence,
            boolean needsUserConfirmation,
            String dataSource,
            String disclaimer,
            String privacyNotice) {
        this(
                analysisId, name, analysis, confidence,
                calories, protein, carbs, fat, sugar,
                servingSize, servingUnit, recommendationTitle, recommendation,
                databaseMatched, databaseMatchConfidence, needsUserConfirmation,
                dataSource, disclaimer, privacyNotice,
                name != null && !name.isBlank() && !"Unknown food".equalsIgnoreCase(name.trim()),
                "", name, "Unknown", "food", false,
                confidence, confidence, confidence,
                List.of(), List.of(),
                new NutritionSummaryResponse(
                        calories, protein, carbs, fat, sugar, 0, 0,
                        databaseMatched
                                ? NutritionSource.DATABASE_CALCULATED
                                : NutritionSource.AI_ESTIMATED,
                        calories > 0));
    }

    public AiFoodAnalysisResponse withAnalysisId(Integer value) {
        return new AiFoodAnalysisResponse(
                value, name, analysis, confidence, calories, protein,
                carbs, fat, sugar, servingSize, servingUnit,
                recommendationTitle, recommendation, databaseMatched,
                databaseMatchConfidence, needsUserConfirmation, dataSource,
                disclaimer, privacyNotice, foodDetected, reason, mealName,
                cuisine, type, requiresDrinkDetails, mealIdentityConfidence, portionConfidence,
                preparationConfidence, components, candidates, nutrition);
    }
}
