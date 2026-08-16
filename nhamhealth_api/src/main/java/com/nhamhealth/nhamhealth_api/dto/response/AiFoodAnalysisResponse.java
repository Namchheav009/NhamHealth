package com.nhamhealth.nhamhealth_api.dto.response;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record AiFoodAnalysisResponse(
        String name,
        double confidence,
        double calories,
        double protein,
        double carbs,
        double fat,
        double sugar,
        double servingSize,
        String servingUnit,
        String recommendationTitle,
        String recommendation) {
}
