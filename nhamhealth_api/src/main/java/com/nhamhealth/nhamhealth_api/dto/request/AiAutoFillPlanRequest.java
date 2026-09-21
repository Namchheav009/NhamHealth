package com.nhamhealth.nhamhealth_api.dto.request;

import java.time.LocalDate;
import java.util.List;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/**
 * Request payload for AI-powered meal plan auto-filling using IBM watsonx
 * Granite.
 */
public record AiAutoFillPlanRequest(
        @NotNull LocalDate startDate,
        @Min(3) @Max(7) Integer days,
        String goal,
        Integer targetTimeframeDays,
        Boolean fillEmptyOnly,
        Boolean includeBeverages,
        String diet,
        List<String> allergens,
        List<String> excludedIngredients,
        List<String> medicalFlags) {

    public AiAutoFillPlanRequest(
            LocalDate startDate,
            Integer days,
            String goal,
            Integer targetTimeframeDays,
            Boolean fillEmptyOnly,
            Boolean includeBeverages) {
        this(startDate, days, goal, targetTimeframeDays, fillEmptyOnly, includeBeverages,
                "BALANCED", List.of(), List.of(), List.of());
    }

    public AiAutoFillPlanRequest {
        if (days == null || days < 3) {
            days = 7;
        }
        if (goal == null || goal.isBlank()) {
            goal = "LOSE_WEIGHT";
        }
        if (targetTimeframeDays == null || targetTimeframeDays <= 0) {
            targetTimeframeDays = 28;
        }
        if (fillEmptyOnly == null) {
            fillEmptyOnly = true;
        }
        if (includeBeverages == null) {
            includeBeverages = true;
        }
        if (diet == null || diet.isBlank()) {
            diet = "BALANCED";
        }
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
