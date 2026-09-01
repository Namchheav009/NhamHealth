package com.nhamhealth.nhamhealth_api.service.wellness;

import java.math.BigDecimal;

/** Minimal wellness context used to personalize food guidance. */
public record UserNutritionContext(
        Integer age,
        BigDecimal heightCm,
        BigDecimal weightKg,
        BigDecimal bmi,
        String activityLevel) {

    public boolean isEmpty() {
        return age == null && heightCm == null && weightKg == null && activityLevel == null;
    }
}
