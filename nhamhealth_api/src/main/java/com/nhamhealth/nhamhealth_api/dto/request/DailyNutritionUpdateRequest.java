package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Size;

public record DailyNutritionUpdateRequest(
        LocalDate date,
        @DecimalMin("0.0") @DecimalMax("20000.0") BigDecimal calories,
        @DecimalMin("0.0") @DecimalMax("2000.0") BigDecimal protein,
        @DecimalMin("0.0") @DecimalMax("2000.0") BigDecimal carbs,
        @DecimalMin("0.0") @DecimalMax("2000.0") BigDecimal fat,
        @DecimalMin("0.0") @DecimalMax("20000.0") BigDecimal water,
        @DecimalMin("0.0") @DecimalMax("1000.0") BigDecimal fiber,
        @DecimalMin("0.0") @DecimalMax("2000.0") BigDecimal sugar,
        @Size(max = 1000) String aiRecommendation,
        @Size(max = 100) String sourceType,
        @Size(max = 100) String sourceId) {

    public DailyNutritionUpdateRequest {
        aiRecommendation = aiRecommendation != null ? aiRecommendation.trim() : null;
        sourceType = sourceType != null ? sourceType.trim() : null;
        sourceId = sourceId != null ? sourceId.trim() : null;
        if (aiRecommendation != null && aiRecommendation.isBlank()) {
            aiRecommendation = null;
        }
        if (sourceType != null && sourceType.isBlank()) {
            sourceType = null;
        }
        if (sourceId != null && sourceId.isBlank()) {
            sourceId = null;
        }
    }
}
