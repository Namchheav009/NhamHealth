package com.nhamhealth.nhamhealth_api.dto.ai;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record FoodComponentNutritionEstimate(
        int index,
        double calories,
        double protein,
        double carbohydrates,
        double fat,
        double sugar,
        double fiber,
        double sodium,
        double confidence) {
}
