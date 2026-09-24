package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;

public record MealPlanUpdateRequest(
        LocalDate planDate,
        Integer plannerMealId,
        @DecimalMin("0.25") @DecimalMax("20") BigDecimal servings,
        String status,
        @DecimalMin("0.25") @DecimalMax("20") BigDecimal actualServings,
        String weightGoal) {

    public MealPlanUpdateRequest(LocalDate planDate, Integer plannerMealId, BigDecimal servings,
            String status, BigDecimal actualServings) {
        this(planDate, plannerMealId, servings, status, actualServings, null);
    }
}
