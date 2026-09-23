package com.nhamhealth.nhamhealth_api.dto.request;

import java.time.LocalDate;
import java.util.Locale;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record MealRecommendationRequest(
        @NotNull LocalDate date,
        @NotBlank String slot,
        String goal,
        Integer currentMealId,
        String actionType) {

    public MealRecommendationRequest {
        slot = slot == null ? "BREAKFAST" : slot.trim().toUpperCase(Locale.ROOT);
        goal = (goal == null || goal.isBlank()) ? "MAINTAIN_HEALTH" : goal.trim().toUpperCase(Locale.ROOT);
        actionType = (actionType == null || actionType.isBlank())
                ? (currentMealId != null ? "SWAP" : "ADD")
                : actionType.trim().toUpperCase(Locale.ROOT);
    }
}
