package com.nhamhealth.nhamhealth_api.dto.ai;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record FoodVisionResult(
        boolean foodDetected,
        String reason,
        String mealName,
        String cuisine,
        String type,
        double mealConfidence,
        double portionConfidence,
        double preparationConfidence,
        List<FoodVisionComponent> components,
        List<FoodCandidate> candidates) {
}
