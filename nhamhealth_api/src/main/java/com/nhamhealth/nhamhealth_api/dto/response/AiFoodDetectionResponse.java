package com.nhamhealth.nhamhealth_api.dto.response;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodCandidate;

@JsonIgnoreProperties(ignoreUnknown = true)
public record AiFoodDetectionResponse(
        boolean foodDetected,
        String reason,
        String mealName,
        String type,
        boolean requiresDrinkDetails,
        double confidence,
        String cuisine,
        List<FoodCandidate> candidates) {

    public AiFoodDetectionResponse(
            boolean foodDetected,
            String reason,
            String mealName,
            String type,
            boolean requiresDrinkDetails,
            double confidence) {
        this(foodDetected, reason, mealName, type, requiresDrinkDetails, confidence, "Unknown", List.of());
    }
}
