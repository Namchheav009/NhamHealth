package com.nhamhealth.nhamhealth_api.service.ai;

import java.util.List;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodComponentNutritionEstimate;

public record FoodNutritionEstimationResult(
        List<FoodComponentNutritionEstimate> components,
        String modelName,
        int promptTokens,
        int completionTokens,
        long latencyMs) {

    public FoodNutritionEstimationResult {
        components = components == null ? List.of() : List.copyOf(components);
        modelName = modelName == null ? "" : modelName.trim();
    }

    public static FoodNutritionEstimationResult empty() {
        return new FoodNutritionEstimationResult(List.of(), "", 0, 0, 0);
    }

    public boolean used() {
        return !components.isEmpty();
    }
}
