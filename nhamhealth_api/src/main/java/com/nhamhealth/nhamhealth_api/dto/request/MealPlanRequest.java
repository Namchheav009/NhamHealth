package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record MealPlanRequest(
        @NotNull LocalDate planDate,
        @NotBlank @Size(max = 30) String mealType,
        @NotNull Integer plannerMealId,
        @NotNull @DecimalMin("0.25") @DecimalMax("20") BigDecimal servings,
        @NotBlank @Size(max = 30) String weightGoal) {

    public MealPlanRequest {
        mealType = mealType != null ? mealType.trim().toUpperCase() : null;
        weightGoal = weightGoal != null ? weightGoal.trim().toUpperCase() : null;
    }
}
