package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;

public record MealPlanUpdateRequest(
        LocalDate planDate,
        Integer plannerMealId,
        @DecimalMin("0.25") @DecimalMax("20") BigDecimal servings) {
}
