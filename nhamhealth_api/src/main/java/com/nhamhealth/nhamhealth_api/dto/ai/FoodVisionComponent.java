package com.nhamhealth.nhamhealth_api.dto.ai;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record FoodVisionComponent(
        String name,
        double estimatedAmount,
        String unit,
        double confidence,
        double portionConfidence,
        String preparationMethod,
        String visibleEvidence) {
}
