package com.nhamhealth.nhamhealth_api.dto.ai;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record FoodNutritionEstimationEnvelope(
        List<FoodComponentNutritionEstimate> components) {
}
