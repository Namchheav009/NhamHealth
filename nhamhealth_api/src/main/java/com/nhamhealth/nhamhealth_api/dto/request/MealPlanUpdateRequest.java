package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Size;

public record MealPlanUpdateRequest(
        LocalDate planDate,
        Integer plannerMealId,
        @DecimalMin("0.25") @DecimalMax("20") BigDecimal servings,
        @Size(max = 30) String status,
        @DecimalMin("0.25") @DecimalMax("20") BigDecimal actualServings,
        @Size(max = 30) String weightGoal) {

    public MealPlanUpdateRequest {
        status = status != null ? status.trim().toUpperCase() : null;
        weightGoal = weightGoal != null ? weightGoal.trim().toUpperCase() : null;
        if (status != null && status.isBlank()) {
            status = null;
        }
        if (weightGoal != null && weightGoal.isBlank()) {
            weightGoal = null;
        }
    }

    public MealPlanUpdateRequest(LocalDate planDate, Integer plannerMealId, BigDecimal servings,
            String status, BigDecimal actualServings) {
        this(planDate, plannerMealId, servings, status, actualServings, null);
    }
}
