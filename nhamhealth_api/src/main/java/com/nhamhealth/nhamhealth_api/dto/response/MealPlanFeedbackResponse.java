package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.LocalDateTime;

public record MealPlanFeedbackResponse(
        Integer id,
        Integer mealPlanId,
        Short rating,
        String outcome,
        String skipReason,
        Short hungerBefore,
        Short fullnessAfter,
        String comment,
        LocalDateTime updatedAt) {
}
