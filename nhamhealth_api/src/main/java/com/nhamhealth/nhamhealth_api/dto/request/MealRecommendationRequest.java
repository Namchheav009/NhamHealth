package com.nhamhealth.nhamhealth_api.dto.request;

import java.time.LocalDate;
import java.util.List;
import java.util.Locale;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record MealRecommendationRequest(
        @NotNull LocalDate date,
        @NotBlank String slot,
        String goal,
        Integer currentMealId,
        String actionType,
        String diet,
        List<String> allergens,
        List<String> excludedIngredients,
        List<String> medicalFlags) {

    public MealRecommendationRequest(
            LocalDate date,
            String slot,
            String goal,
            Integer currentMealId,
            String actionType) {
        this(date, slot, goal, currentMealId, actionType,
                "BALANCED", List.of(), List.of(), List.of());
    }

    public MealRecommendationRequest {
        slot = slot == null ? "BREAKFAST" : slot.trim().toUpperCase(Locale.ROOT);
        goal = (goal == null || goal.isBlank()) ? "MAINTAIN_HEALTH" : goal.trim().toUpperCase(Locale.ROOT);
        actionType = (actionType == null || actionType.isBlank())
                ? (currentMealId != null ? "SWAP" : "ADD")
                : actionType.trim().toUpperCase(Locale.ROOT);
        diet = (diet == null || diet.isBlank()) ? "BALANCED" : diet.trim().toUpperCase(Locale.ROOT);
        allergens = sanitize(allergens);
        excludedIngredients = sanitize(excludedIngredients);
        medicalFlags = sanitize(medicalFlags);
    }

    private static List<String> sanitize(List<String> values) {
        if (values == null) {
            return List.of();
        }
        return values.stream()
                .filter(value -> value != null && !value.isBlank())
                .map(String::trim)
                .distinct()
                .limit(30)
                .toList();
    }
}
