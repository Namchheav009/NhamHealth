package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMin;

public record DailyNutritionUpdateRequest(
        LocalDate date,
        @DecimalMin("0.0") BigDecimal calories,
        @DecimalMin("0.0") BigDecimal protein,
        @DecimalMin("0.0") BigDecimal carbs,
        @DecimalMin("0.0") BigDecimal fat,
        @DecimalMin("0.0") BigDecimal water,
        @DecimalMin("0.0") BigDecimal fiber,
        @DecimalMin("0.0") BigDecimal sugar,
        String aiRecommendation) {
}
