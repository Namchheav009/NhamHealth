package com.nhamhealth.nhamhealth_api.dto.response;

import java.util.List;

public record MealPlannerAiRecommendationResponse(
        WeeklyMealRecommendationResponse recommendedMeal,
        List<WeeklyMealRecommendationResponse> alternatives,
        String aiRationale,
        String actionType,
        String modelUsed) {

    public MealPlannerAiRecommendationResponse {
        alternatives = alternatives == null ? List.of() : List.copyOf(alternatives);
        aiRationale = aiRationale == null ? "" : aiRationale.trim();
        actionType = actionType == null ? "ADD" : actionType.trim();
        modelUsed = modelUsed == null ? "" : modelUsed.trim();
    }
}
