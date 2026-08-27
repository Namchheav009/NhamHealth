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
        String visibleEvidence,
        String componentType,
        double liquidVolumeMl,
        String beverageType) {

    /** Compatibility constructor for callers using the original recognition schema. */
    public FoodVisionComponent(
            String name,
            double estimatedAmount,
            String unit,
            double confidence,
            double portionConfidence,
            String preparationMethod,
            String visibleEvidence) {
        this(
                name, estimatedAmount, unit, confidence, portionConfidence,
                preparationMethod, visibleEvidence, null, 0, null);
    }
}
