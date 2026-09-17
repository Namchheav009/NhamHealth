package com.nhamhealth.nhamhealth_api.dto.request;

public record WeeklyMealRecommendationRequest(
        Integer plannerMealId,
        String dayOfWeek,
        String mealSlot,
        String note,
        Boolean active,
        Integer sortOrder) {
}
